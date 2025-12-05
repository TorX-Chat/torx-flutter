// ignore_for_file: constant_identifier_names

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
// ignore_for_file: non_constant_identifier_names, camel_case_types

import 'dart:ffi';
import 'dart:ffi' as ffi;
import 'dart:io';

import 'package:chat/main.dart';
import 'package:ffi/ffi.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'change_notifiers.dart';
import 'colors.dart';
import 'language.dart';
import 'manual_bindings.dart';

const bool enable_spinners = false;
const double sticker_size = 80;
const double sticker_border_width = 3; // for sticker chooser

Image? sticker_generator(int s) {
  int sticker_count = torx.sticker_retrieve_count();
  if (sticker_count > 0 && s < sticker_count) {
    Pointer<Uint8> data = torx.sticker_retrieve_data(s);
    Uint8List bytes = data.asTypedList(torx.torx_allocation_len(data)).sublist(0);
    torx.torx_free_simple(data);
    data = nullptr;
    return Image.memory(height: sticker_size * 2, fit: BoxFit.contain, bytes, gaplessPlayback: true);
  }
  return null;
}

void ui_sticker_send(int s) {
  if (s < 0) {
    return;
  }
  int g = -1;
  int g_invite_required = 0;
  int owner = torx.getter_uint8(global_n, INT_MIN, -1, offsetof("peer", "owner"));
  if (owner == ENUM_OWNER_GROUP_CTRL) {
    g = torx.set_g(global_n, nullptr);
    g_invite_required = torx.getter_group_uint8(g, offsetof("group", "invite_required"));
  }
  Pointer<Uint8> checksum = torx.sticker_retrieve_checksum(s);
  int recipient_n = global_n;
  if (t_peer.pm_n[global_n] > -1) {
    recipient_n = t_peer.pm_n[global_n];
    torx.message_send(recipient_n, ENUM_PROTOCOL_STICKER_HASH_PRIVATE, checksum, CHECKSUM_BIN_LEN);
  } else if (owner == ENUM_OWNER_GROUP_CTRL && g_invite_required != 0) {
    // date && sign private group messages
    torx.message_send(recipient_n, ENUM_PROTOCOL_STICKER_HASH_DATE_SIGNED, checksum, CHECKSUM_BIN_LEN);
  } else {
    // regular messages, private messages (in authenticated pipes), public messages in public groups (in authenticated pipes)
    torx.message_send(recipient_n, ENUM_PROTOCOL_STICKER_HASH, checksum, CHECKSUM_BIN_LEN);
  }
  torx.torx_free_simple(checksum);
  checksum = nullptr;
}

class RouteStickers extends StatefulWidget {
  const RouteStickers({super.key});

  @override
  State<RouteStickers> createState() => _RouteStickersState();
}

class _RouteStickersState extends State<RouteStickers> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: color.right_panel_background,
        appBar: AppBar(
            backgroundColor: color.chat_headerbar,
            title: Text(
              text.select_sticker,
              style: TextStyle(color: color.page_title),
            )),
        body: Padding(
            padding: const EdgeInsets.all(8.0),
            child: AnimatedBuilder(
                animation: changeNotifierStickerReady,
                builder: (BuildContext context, Widget? snapshot) {
                  int sticker_count = torx.sticker_retrieve_count();
                  return GridView.extent(
                    maxCrossAxisExtent: 180,
                    children: List.generate(sticker_count + 1, (s) {
                      if (s == sticker_count) {
                        return GridTile(
                            child: InkWell(
                                onTap: () async {
                                  FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowMultiple: true, allowedExtensions: ['gif']);
                                  if (result != null) {
                                    List<File> files = result.paths.map((path) => File(path!)).toList();
                                    int file_iter = 0;
                                    int s = -1;
                                    while (file_iter < files.length) {
                                      if (files[file_iter].path.endsWith(".gif")) {
                                        error(0,
                                            "Checkpoint new sticker: ${files[file_iter].path}"); // GOAT file_picker caches. we don't want caching. https://github.com/miguelpruivo/flutter_file_picker/issues/40 https://github.com/miguelpruivo/flutter_file_picker/issues/1093
                                        Pointer<Utf8> path_p = files[file_iter].path.toNativeUtf8(); // free'd by calloc.free
                                        Pointer<Uint8> bytes = torx.read_bytes(path_p); // free'd by torx_free
                                        s = torx.sticker_register(bytes, torx.torx_allocation_len(bytes));
                                        torx.torx_free_simple(bytes as Pointer<Void>);
                                        bytes = nullptr;
                                        calloc.free(path_p);
                                        path_p = nullptr;
                                        torx.sticker_save(s);
                                      } else {
                                        error(0, "Rejected attempt to use non-gif sticker");
                                      }
                                      file_iter++;
                                    }
                                    if (s > -1) changeNotifierStickerReady.callback(integer: s);
                                  }
                                },
                                child: Icon(Icons.add, color: color.torch_off, size: sticker_size)));
                      } else {
                        bool saved = torx.sticker_retrieve_saved(s) == 1 ? true : false;
                        return GridTile(
                            child: InkWell(
                                onTap: () {
                                  ui_sticker_send(s);
                                  Navigator.pop(context);
                                },
                                onLongPress: () {
                                  showMenu(context: context, position: getPosition(context), items: generate_message_menu(context, null, -1, INT_MIN, s));
                                },
                                child: Container(
                                    decoration: BoxDecoration(
                                        color: saved ? Colors.transparent : color.unsaved_sticker, // color.unsaved_sticker,
                                        border: Border.all(
                                          color: saved ? Colors.transparent : color.unsaved_sticker, // Border color
                                          width: sticker_border_width, // Border width
                                        )),
                                    child: sticker_generator(s))));
                      }
                    }),
                  );
                })));
  }
}
