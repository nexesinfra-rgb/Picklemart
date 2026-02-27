import 'package:flutter_riverpod/flutter_riverpod.dart';

class GuestModeNotifier extends StateNotifier<bool> {
  GuestModeNotifier() : super(false);

  void enableGuestMode() {
    state = true;
  }

  void disableGuestMode() {
    state = false;
  }

  void toggleGuestMode() {
    state = !state;
  }
}

final guestModeProvider = StateNotifierProvider<GuestModeNotifier, bool>(
  (ref) => GuestModeNotifier(),
);



