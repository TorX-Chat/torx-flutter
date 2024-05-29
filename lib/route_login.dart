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

/*
  void _check_keystate(Timer timer) {
    if (lockout == false) {
      timer.cancel();
      if (keyed == true) {
        // This must be triggered only by login_cb()
        setBottomIndex();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) {
              return const RouteBottom();
            },
          ),
        );
      } else {
        setState(() {
          button_text = text.enter;
        });
        entryLoginController.clear();
      }
    }
  } */

  void _submit() {
    if (threadsafe_read_global_Uint8("lockout") == 0) {
      button_text = text.wait;
      Pointer<Utf8> password = entryLoginController.text.toNativeUtf8(); // free'd by calloc.free
      printf("Checkpoint login_start: \"${entryLoginController.text}\"");
      torx.login_start(password);
      calloc.free(password);
      password = nullptr;
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
                          child: TextField(
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
                              setState(() {});
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
                                  setState(() {
                                    obscureText = !obscureText;
                                  });
                                },
                              ),
                            ),
                          )),
                      MaterialButton(
                        onPressed: () {
                          _submit();
                          setState(() {});
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
                        Switch(
                          value: threadsafe_read_global_Uint8("censored_region") == 0 ? false : true,
                          activeColor: const Color(0xFF6200EE),
                          onChanged: (value) {
                            int val;
                            if (value == false) {
                              val = 0;
                            } else /*if (value == true)*/ {
                              val = 1;
                            }
                            torx.pthread_rwlock_wrlock(torx.mutex_global_variable);
                            torx.censored_region.value = val;
                            torx.pthread_rwlock_unlock(torx.mutex_global_variable);
                            set_setting_string(1, -1, "censored_region", val.toString());
                            setState(() {});
                          },
                        ),
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
