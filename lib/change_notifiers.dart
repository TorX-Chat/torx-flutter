/*
TorX: Metadata-safe Tor Chat Library
Copyright (C) 2024 TorX

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License version 3 as published by the Free
Software Foundation.

You should have received a copy of the GNU General Public License along with
this program.  If not, see <https://www.gnu.org/licenses/>.

Appendix:

Section 7 Exceptions:

1) Modified versions of the material and resulting works must be clearly titled
in the following manner: "Unofficial TorX by Financier", where the word
Financier is replaced by the financier of the modifications. Where there is no
financier, the word Financier shall be replaced by the organization or
individual who is primarily responsible for causing the modifications. Example:
"Unofficial TorX by The United States Department of Defense". This amended
full-title must replace the word "TorX" in all source code files and all
resulting works. Where utilizing spaces is not possible, underscores may be
utilized. Example: "Unofficial_TorX_by_The_United_States_Department_of_Defense".
The title must not be replaced by an acronym or short title in any form of
distribution.

2) Modified versions of the material and resulting works must be distributed
with alternate logos and imagery that is substantially different from the
original TorX logo and imagery, especially the 7-headed snake logo. Modified
material and resulting works, where distributed with a logo or imagery, should
choose and distribute a logo or imagery that reflects the Financier,
organization, or individual primarily responsible for causing modifications and
must not cause any user to note similarities with any of the original TorX
imagery. Example: Modifications or works financed by The United States
Department of Defense should choose a logo and imagery similar to existing logos
and imagery utilized by The United States Department of Defense.

3) Those who modify, distribute, or finance the modification or distribution of
modified versions of the material or resulting works, shall not avail themselves
of any disclaimers of liability, such as those laid out by the original TorX
author in sections 15 and 16 of the License.

4) Those who modify, distribute, or finance the modification or distribution of
modified versions of the material or resulting works, shall jointly and
severally indemnify the original TorX author against any claims of damages
incurred and any costs arising from litigation related to any changes they are
have made, caused to be made, or financed. 

5) The original author of TorX may issue explicit exemptions from some or all of
the above requirements (1-4), but such exemptions should be interpreted in the
narrowest possible scope and to only grant limited rights within the narrowest
possible scope to those who explicitly receive the exemption and not those who
receive the material or resulting works from the exemptee.

6) The original author of TorX grants no exceptions from trademark protection in
any form.

7) Each aspect of these exemptions are to be considered independent and
severable if found in contradiction with the License or applicable law.
*/
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