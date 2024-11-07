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
// ignore_for_file: non_constant_identifier_names, constant_identifier_names, camel_case_types
import 'package:flutter/material.dart';
import 'main.dart';

enum enum_theme { DARK_THEME, LIGHT_THEME }

/* 
  torch_on / torch_off is being used for all or most icons
  lots of things are redundant or not used
*/

// NOTE: Initialize all first as white
class color {
// Flutter exclusive
  static Color logo = const Color.fromRGBO(255, 255, 255, 0);
  static Color title = const Color.fromRGBO(255, 255, 255, 0);
  static Color torch_on = const Color.fromRGBO(255, 255, 255, 0);
  static Color torch_off = const Color.fromRGBO(255, 255, 255, 0);
  static Color button_background = const Color.fromRGBO(255, 255, 255, 0);
  static Color button_text = const Color.fromRGBO(255, 255, 255, 0);
  static Color selected_row = const Color.fromRGBO(255, 255, 255, 0);

// Same as GTK CSS files
  static Color window_auth = const Color.fromRGBO(255, 255, 255, 0);
  static Color main_box = const Color.fromRGBO(255, 255, 255, 0);
  static Color login_label = const Color.fromRGBO(255, 255, 255, 0);
  static Color auth_error = const Color.fromRGBO(255, 255, 255, 0);
  static Color login_label_subtext = const Color.fromRGBO(255, 255, 255, 0);
  static Color unsaved_sticker = const Color.fromRGBO(0, 200, 10, 1);
  static Color auth_button_background = const Color.fromRGBO(255, 255, 255, 0);
  static Color auth_button_text = const Color.fromRGBO(255, 255, 255, 0); // GOAT not used
  static Color auth_button_hover = const Color.fromRGBO(255, 255, 255, 0); // GOAT not used, some others too
  static Color window_main = const Color.fromRGBO(255, 255, 255, 0);
  static Color search_field_background = const Color.fromRGBO(255, 255, 255, 0);
  static Color search_field_text = const Color.fromRGBO(255, 255, 255, 0);
  static Color left_panel = const Color.fromRGBO(255, 255, 255, 0);
  static Color right_panel_background = const Color.fromRGBO(255, 255, 255, 0);
  static Color right_panel_text = const Color.fromRGBO(255, 255, 255, 0);
  static Color chat_headerbar = const Color.fromRGBO(255, 255, 255, 0);
  static Color page_title = const Color.fromRGBO(255, 255, 255, 0);
  static Color page_subtitle = const Color.fromRGBO(255, 255, 255, 0);
  static Color chat_name = const Color.fromRGBO(255, 255, 255, 0);
  static Color last_message = const Color.fromRGBO(48, 48, 48, 1); // Changed from GTK. i think in GTK it is not loading.
  static Color write_message_background = const Color.fromRGBO(255, 255, 255, 0);
  static Color write_message_text = const Color.fromRGBO(255, 255, 255, 0);
  static Color message_sent_private_background = const Color.fromRGBO(255, 255, 255, 0);
  static Color message_sent_private_text = const Color.fromRGBO(255, 255, 255, 0);
  static Color message_recv_private_background = const Color.fromRGBO(255, 255, 255, 0);
  static Color message_recv_private_text = const Color.fromRGBO(255, 255, 255, 0);
  static Color message_sent_background = const Color.fromRGBO(255, 255, 255, 0);
  static Color message_sent_text = const Color.fromRGBO(255, 255, 255, 0);
  static Color message_recv_background = const Color.fromRGBO(255, 255, 255, 0);
  static Color message_recv_text = const Color.fromRGBO(255, 255, 255, 0);
  static Color message_time = const Color.fromRGBO(255, 255, 255, 0);
  static Color group_or_user_name = const Color.fromRGBO(255, 255, 255, 0);
  static Color last_online = const Color.fromRGBO(255, 255, 255, 0);
}

void initialize_theme(BuildContext? context) {
  if (theme == enum_theme.DARK_THEME.index) {
    color.logo = const Color.fromRGBO(0, 0, 0, 1);
    color.title = const Color.fromRGBO(255, 255, 255, 1);
    color.torch_on = const Color.fromRGBO(255, 255, 255, 1);
    color.torch_off = const Color.fromRGBO(190, 190, 190, 1);
    color.button_background = const Color.fromRGBO(33, 45, 56, 1);
    color.button_text = const Color.fromRGBO(255, 255, 255, 1);
    color.selected_row = const Color.fromRGBO(237, 168, 74, 0.5);
    color.window_auth = const Color.fromRGBO(22, 33, 44, 1);
    color.main_box = const Color.fromRGBO(33, 45, 56, 1);
    color.login_label = const Color.fromRGBO(255, 255, 255, 1);
    color.auth_error = const Color.fromRGBO(222, 49, 49, 1);
    color.login_label_subtext = const Color.fromRGBO(165, 165, 165, 1);
    color.unsaved_sticker = const Color.fromRGBO(0, 200, 10, 1);
    color.auth_button_background = const Color.fromRGBO(236, 179, 101, 1);
    color.auth_button_text = const Color.fromRGBO(48, 48, 48, 1);
    color.auth_button_hover = const Color.fromRGBO(237, 168, 74, 1);
    color.window_main = const Color.fromRGBO(33, 45, 56, 1);
    color.search_field_background = const Color.fromRGBO(190, 190, 190, 1);
    color.search_field_text = const Color.fromRGBO(48, 48, 48, 1);
    color.left_panel = const Color.fromRGBO(33, 45, 56, 1);
    color.right_panel_background = const Color.fromRGBO(22, 33, 44, 1);
    color.right_panel_text = const Color.fromRGBO(190, 190, 190, 1);
    color.chat_headerbar = const Color.fromRGBO(33, 45, 56, 1);
    color.page_title = const Color.fromRGBO(255, 255, 255, 1);
    color.page_subtitle = const Color.fromRGBO(255, 255, 255, 1);
    color.chat_name = const Color.fromRGBO(255, 255, 255, 1);
    color.last_message = const Color.fromRGBO(255, 255, 255, 0.7);
    color.write_message_background = const Color.fromRGBO(33, 45, 56, 1);
    color.write_message_text = const Color.fromRGBO(255, 255, 255, 1);
    color.message_sent_private_background = const Color.fromRGBO(144, 0, 128, 1);
    color.message_sent_private_text = const Color.fromRGBO(255, 255, 255, 1);
    color.message_recv_private_background = const Color.fromRGBO(144, 0, 128, 1);
    color.message_recv_private_text = const Color.fromRGBO(255, 255, 255, 1);
    color.message_sent_background = const Color.fromRGBO(213, 155, 73, 1);
    color.message_sent_text = const Color.fromRGBO(255, 255, 255, 1);
    color.message_recv_background = const Color.fromRGBO(35, 54, 73, 1);
    color.message_recv_text = const Color.fromRGBO(255, 255, 255, 1);
    color.message_time = const Color.fromRGBO(255, 255, 255, 1);
    color.group_or_user_name = const Color.fromRGBO(255, 255, 255, 1);
    color.last_online = const Color.fromRGBO(255, 255, 255, 0.7);
  } else if (theme == enum_theme.LIGHT_THEME.index) {
    color.logo = const Color.fromRGBO(0, 0, 0, 1);
    color.title = const Color.fromRGBO(0, 0, 0, 1);
    color.torch_on = const Color.fromRGBO(48, 48, 48, 1);
    color.torch_off = const Color.fromRGBO(165, 165, 165, 1);
    color.button_background = const Color.fromRGBO(223, 225, 229, 1);
    color.button_text = const Color.fromRGBO(71, 71, 71, 1);
    color.selected_row = const Color.fromRGBO(237, 168, 74, 0.5);
    color.window_auth = const Color.fromRGBO(223, 225, 229, 1);
    color.main_box = const Color.fromRGBO(255, 255, 255, 1);
    color.login_label = const Color.fromRGBO(95, 99, 104, 1);
    color.auth_error = const Color.fromRGBO(222, 49, 49, 1);
    color.login_label_subtext = const Color.fromRGBO(165, 165, 165, 1);
    color.unsaved_sticker = const Color.fromRGBO(0, 200, 10, 1);
    color.auth_button_background = const Color.fromRGBO(236, 179, 101, 1);
    color.auth_button_text = const Color.fromRGBO(48, 48, 48, 1);
    color.auth_button_hover = const Color.fromRGBO(237, 168, 74, 1);
    color.window_main = const Color.fromRGBO(223, 225, 229, 1);
    color.search_field_background = const Color.fromRGBO(255, 255, 255, 1);
    color.search_field_text = const Color.fromRGBO(48, 48, 48, 1);
    color.left_panel = const Color.fromRGBO(223, 225, 229, 1);
    color.right_panel_background = const Color.fromRGBO(255, 255, 255, 1);
    color.right_panel_text = const Color.fromRGBO(71, 71, 71, 1);
    color.chat_headerbar = const Color.fromRGBO(223, 225, 229, 1);
    color.page_title = const Color.fromRGBO(71, 71, 71, 1);
    color.page_subtitle = const Color.fromRGBO(71, 71, 71, 1);
    color.chat_name = const Color.fromRGBO(71, 71, 71, 1);
    color.last_message = const Color.fromRGBO(71, 71, 71, 1);
    color.write_message_background = const Color.fromRGBO(223, 225, 229, 1);
    color.write_message_text = const Color.fromRGBO(48, 48, 48, 1);
    color.message_sent_private_background = const Color.fromRGBO(210, 120, 200, 1);
    color.message_sent_private_text = const Color.fromRGBO(48, 48, 48, 1);
    color.message_recv_private_background = const Color.fromRGBO(210, 120, 200, 1);
    color.message_recv_private_text = const Color.fromRGBO(48, 48, 48, 1);
    color.message_sent_background = const Color.fromRGBO(255, 197, 118, 1);
    color.message_sent_text = const Color.fromRGBO(48, 48, 48, 1);
    color.message_recv_background = const Color.fromRGBO(223, 225, 229, 1);
    color.message_recv_text = const Color.fromRGBO(48, 48, 48, 1);
    color.message_time = const Color.fromRGBO(48, 48, 48, 1);
    color.group_or_user_name = const Color.fromRGBO(71, 71, 71, 1);
    color.last_online = const Color.fromRGBO(71, 71, 71, 1);
  } else {
    if (context != null && MediaQuery.of(context).platformBrightness == Brightness.light) {
      theme = enum_theme.LIGHT_THEME.index;
    } else {
      theme = enum_theme.DARK_THEME.index; // default, should never trigger. don't bother.
    }
    initialize_theme(context); // recursive
  }
}
