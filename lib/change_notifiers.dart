import 'package:flutter/material.dart';
// Change Notifiers are used by cb_handling.dart to update UI components, with the exception of TextField which can be updated directly
// We currently use two types of ChangeNotifier--one for integers, one for String. We do not pass Pointer<Utf8> because UI is presumably async and the pointer is probably free'd/0'd first
// NOTE: better to have 1-2 listeners per ChangeNotifier. not efficient to have many, apparently.

class SectionInt {
  int integer = -1;
  SectionInt({required this.integer});
}

class ChangeNotifierInt extends ChangeNotifier {
  SectionInt section = SectionInt(integer: -1);

  void callback({required int integer}) {
    section.integer = integer;
    notifyListeners();
  }
}

class SectionString {
  String string = "";
  SectionString({required this.string});
}

class ChangeNotifierString extends ChangeNotifier {
  SectionString section = SectionString(string: "");

  void callback({required String string}) {
    section.string = string;
    notifyListeners();
  }
}

class ChangeNotifierTransferProgress extends ChangeNotifier {
  void callback() {
    notifyListeners();
  }
}

class SectionMessage {
  int n = -1;
  int i = -1;
  int scroll = -1;
  SectionMessage({required this.n, required this.i, required this.scroll});
}

class ChangeNotifierMessage extends ChangeNotifier {
  SectionMessage section = SectionMessage(n: -1, i: -1, scroll: -1);

  void callback({required int n, required int i, required int scroll}) {
    section.n = n;
    section.i = i;
    section.scroll = scroll;

    notifyListeners();
  }
}

// NOTICE: We cannot have individual widgets listening on multiple ChangeNotifier(s). Therefore, we must have a ChangeNotifier per widget, not per callback type.
// RE: numbers, see enum cb_type
ChangeNotifierInt changeNotifierTextOrAudio = ChangeNotifierInt();
ChangeNotifierInt changeNotifierSendButton = ChangeNotifierInt();
ChangeNotifierInt changeNotifierActivity = ChangeNotifierInt();
ChangeNotifierInt changeNotifierStickerReady = ChangeNotifierInt();
ChangeNotifierInt changeNotifierChangePassword = ChangeNotifierInt();
ChangeNotifierInt changeNotifierDataTables = ChangeNotifierInt();
ChangeNotifierInt changeNotifierChatList = ChangeNotifierInt();
ChangeNotifierInt changeNotifierPopoverList = ChangeNotifierInt();
ChangeNotifierInt changeNotifierOnlineOffline = ChangeNotifierInt();
ChangeNotifierInt changeNotifierOnionReady = ChangeNotifierInt();
ChangeNotifierInt changeNotifierLogin = ChangeNotifierInt();
ChangeNotifierInt changeNotifierGroupReady = ChangeNotifierInt();
ChangeNotifierString changeNotifierTorLog = ChangeNotifierString();
ChangeNotifierString changeNotifierError = ChangeNotifierString();
ChangeNotifierMessage changeNotifierMessage = ChangeNotifierMessage();

// Somewhat unrelated to cb_handling()
ChangeNotifierInt changeNotifierTotalUnread = ChangeNotifierInt();
ChangeNotifierInt changeNotifierTotalIncoming = ChangeNotifierInt();

// Theme related
ChangeNotifierInt changeNotifierTheme = ChangeNotifierInt();


// Low Priority, yet to implement:
//  For RouteLogin, instead of using Timer. Might be complex to eliminate timer because we have a Navigate which requires context so to put it in the cb_handling we'd at least need a key(?)