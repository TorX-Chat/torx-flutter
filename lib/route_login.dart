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
// ignore_for_file: constant_identifier_names, non_constant_identifier_names
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'change_notifiers.dart';
import 'colors.dart';
import 'manual_bindings.dart';
import 'routes.dart';
import 'main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'language.dart';

class RouteLogin extends StatefulWidget {
  const RouteLogin({super.key});

  @override
  State<RouteLogin> createState() => _RouteLoginState();
}

class _RouteLoginState extends State<RouteLogin> {
  String button_text = text.enter;
  TextEditingController entryLoginController = TextEditingController();

  void _submit() {
    if (threadsafe_read_global_Uint8("lockout") == 0) {
      button_text = text.wait;
      Pointer<Utf8> password = entryLoginController.text.toNativeUtf8(); // free'd by calloc.free
      printf("Checkpoint login_start: \"${entryLoginController.text}\"");
      torx.login_start(password);
      calloc.free(password);
      password = nullptr;
      changeNotifierLogin.callback(integer: 500); // must not be 0 or -1. Just to set the button_text.
    } else {
      return;
    }
  }

  String enter_password = text.enter_password;
  bool obscureText = true;
  @override
  Widget build(BuildContext context) {
    if (theme == 0) {
      initialize_theme(context);
    }
    return AnimatedBuilder(
        animation: changeNotifierLogin,
        builder: (BuildContext context, Widget? snapshot) {
          if (changeNotifierLogin.section.integer == 0) {
            if (threadsafe_read_global_Uint8("keyed") < 1) {
              torx.initial_keyed();
            }
            initialize_language(); // second time, in case it changed from keyed settings
            initialize_theme(context);
            setBottomIndex();
            return const RouteBottom();
          } else {
            //  namedController.value = TextEditingValue(text: passwd);
            //  printf("Checkpoint:\n\n\n_RouteLoginState\n\n\n");
            if (!initialized) {
              initialization_functions(context);
              if (threadsafe_read_global_Uint8("first_run") == 1) {
                enter_password = text.enter_password_first_run;
              }
            }
            if (threadsafe_read_global_Uint8("lockout") == 0) {
              if (login_failed && changeNotifierLogin.section.integer == -1) {
                entryLoginController.clear();
                login_failed = false;
              }
              button_text = text.enter;
            } else {
              button_text = text.wait;
            }
            return Scaffold(
              body: Center(
                child: SingleChildScrollView(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: color.main_box,
                        width: 50,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      color: color.main_box,
                    ),
                    child: Column(children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(path_logo, color: color.logo, width: 50, height: 50),
                          const Padding(padding: EdgeInsets.all(3.0)),
                          Text(
                            text.title,
                            textScaleFactor: 3,
                            //    textScaler: MediaQuery.textScalerOf(context),
                            style: TextStyle(color: color.title),
                          ),
                        ],
                      ),
                      const Padding(padding: EdgeInsets.all(5.0)),
                      Container(
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: color.search_field_background),
                          child: AnimatedBuilder(
                              animation: changeNotifierObscureText,
                              builder: (BuildContext context, Widget? snapshot) {
                                return TextField(
                                  controller: entryLoginController,
                                  obscureText: obscureText,
                                  autocorrect: false,
                                  enableSuggestions: false,
                                  enableIMEPersonalizedLearning: false,
                                  scribbleEnabled: false,
                                  spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
                                  showCursor: true,
                                  autofocus: true,
                                  textAlign: TextAlign.center,
                                  onSubmitted: (String value) {
                                    _submit();
                                  },
                                  style: TextStyle(color: color.search_field_text),
                                  decoration: InputDecoration(
                                    border: const OutlineInputBorder(),
                                    hintText: enter_password,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        obscureText ? Icons.visibility : Icons.visibility_off,
                                      ),
                                      onPressed: () {
                                        obscureText = !obscureText;
                                        changeNotifierObscureText.callback(integer: -1);
                                      },
                                    ),
                                  ),
                                );
                              })),
                      MaterialButton(
                        onPressed: () {
                          _submit();
                        },
                        height: 30,
                        minWidth: 60,
                        elevation: 5,
                        color: color.auth_button_background,
                        child: Text(
                          button_text,
                          style: TextStyle(color: color.auth_button_text),
                        ),
                      ),
                      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                        Text(text.censored_region, style: TextStyle(color: color.page_subtitle)),
                        AnimatedBuilder(
                            animation: changeNotifierSettingChange,
                            builder: (BuildContext context, Widget? snapshot) {
                              return Switch(
                                value: threadsafe_read_global_Uint8("censored_region") == 0 ? false : true,
                                activeColor: const Color(0xFF6200EE),
                                onChanged: (value) {
                                  int val;
                                  if (value == false) {
                                    val = 0;
                                  } else /*if (value == true)*/ {
                                    val = 1;
                                  }
                                  torx.pthread_rwlock_wrlock(torx.mutex_global_variable); // 🟥
                                  torx.censored_region.value = val;
                                  torx.pthread_rwlock_unlock(torx.mutex_global_variable); // 🟩
                                  set_setting_string(1, -1, "censored_region", val.toString());
                                  changeNotifierSettingChange.callback(integer: -1);
                                },
                              );
                            }),
                      ]),
                    ]),
                  ),
                ])),
              ),
              backgroundColor: color.window_auth,
            );
          }
        });
  }
}
