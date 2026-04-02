import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

// Desktop OAuth 2.0 client ID (type: Desktop app) from Google Cloud Console.
// https://console.cloud.google.com/apis/credentials
// Create → OAuth client ID → Desktop app
const _desktopGoogleClientId = 'YOUR_DESKTOP_CLIENT_ID.apps.googleusercontent.com';

bool get _isDesktop =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS);

class AuthNotifier extends ChangeNotifier {
  User? _user;
  StreamSubscription<User?>? _sub;

  AuthNotifier() {
    _sub = FirebaseAuth.instance.authStateChanges().listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  User? get user => _user;
  bool get isGuest => _user?.isAnonymous ?? false;

  Future<void> signInAsGuest() async {
    await FirebaseAuth.instance.signInAnonymously();
  }

  Future<void> signInWithGoogle() async {
    if (kIsWeb) {
      await FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());
    } else if (_isDesktop) {
      await _signInWithGoogleDesktop();
    } else {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
    }
  }

  Future<void> _signInWithGoogleDesktop() async {
    final codeVerifier = _generateCodeVerifier();
    final codeChallenge = _generateCodeChallenge(codeVerifier);

    final authUrl = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
      'client_id': _desktopGoogleClientId,
      'redirect_uri': 'http://localhost',
      'response_type': 'code',
      'scope': 'openid email profile',
      'code_challenge': codeChallenge,
      'code_challenge_method': 'S256',
    });

    final result = await FlutterWebAuth2.authenticate(
      url: authUrl.toString(),
      callbackUrlScheme: 'http',
    );

    final code = Uri.parse(result).queryParameters['code'];
    if (code == null) throw Exception('Brak kodu autoryzacji od Google');

    final tokenResponse = await http.post(
      Uri.parse('https://oauth2.googleapis.com/token'),
      body: {
        'client_id': _desktopGoogleClientId,
        'code': code,
        'redirect_uri': 'http://localhost',
        'grant_type': 'authorization_code',
        'code_verifier': codeVerifier,
      },
    );

    final tokenData = jsonDecode(tokenResponse.body) as Map<String, dynamic>;
    final idToken = tokenData['id_token'] as String?;
    final accessToken = tokenData['access_token'] as String?;

    if (idToken == null) {
      throw Exception('Nie udało się uzyskać tokenu: ${tokenResponse.body}');
    }

    final credential = GoogleAuthProvider.credential(
      idToken: idToken,
      accessToken: accessToken,
    );
    await FirebaseAuth.instance.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!kIsWeb && !_isDesktop) await GoogleSignIn().signOut();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

String _generateCodeVerifier() {
  final random = Random.secure();
  final bytes = List<int>.generate(32, (_) => random.nextInt(256));
  return base64UrlEncode(bytes).replaceAll('=', '');
}

String _generateCodeChallenge(String verifier) {
  final bytes = utf8.encode(verifier);
  final digest = sha256.convert(bytes);
  return base64UrlEncode(digest.bytes).replaceAll('=', '');
}

final authNotifierProvider =
    ChangeNotifierProvider<AuthNotifier>((ref) => AuthNotifier());
