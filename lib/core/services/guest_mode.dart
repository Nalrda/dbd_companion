/// Simple static flag used across the app (including repositories that don't
/// have Riverpod access) to know whether the current session is guest-only.
class GuestMode {
  GuestMode._();
  static bool isGuest = false;
}
