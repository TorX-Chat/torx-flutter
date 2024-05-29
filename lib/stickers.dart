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

bool enable_spinners = false;
bool save_all_stickers = false;
bool send_sticker_data = true; // not really that useful because if we don't send stickers, people can't request stickers.
double sticker_size = 80;
double sticker_border_width = 3; // for sticker chooser

class sticker {
  Pointer<Uint8> checksum;
  Pointer<Uint8> data;
  int data_len;
  bool saved; // is saved to disk
  List<int> peers;

  sticker({required this.checksum, required this.data, required this.data_len, required this.saved, List<int>? peers}) : peers = peers ?? [];
}

List<sticker> stickers = [];

Image? sticker_generator(int s) {
  if (stickers.isNotEmpty) {
    Uint8List bytes = stickers[s].data.asTypedList(stickers[s].data_len);
    return Image.memory(height: sticker_size * 2, fit: BoxFit.contain, bytes);
  }
  return null;
}

void ui_sticker_send(int s) {
  if (s < 0) {
    return;
  }
  int g = -1;
  int g_invite_required = 0;
  int owner = torx.getter_uint8(global_n, -1, -1, -1, offsetof("peer", "owner"));
  if (owner == ENUM_OWNER_GROUP_CTRL) {
    g = torx.set_g(global_n, nullptr);
    g_invite_required = torx.getter_group_uint8(g, offsetof("group", "invite_required"));
  }
  int recipient_n = global_n;
  if (t_peer.pm_n[global_n] > -1) {
    recipient_n = t_peer.pm_n[global_n];
    torx.message_send(recipient_n, ENUM_PROTOCOL_STICKER_HASH_PRIVATE, stickers[s].checksum as Pointer<Void>, CHECKSUM_BIN_LEN);
  } else if (owner == ENUM_OWNER_GROUP_CTRL && g_invite_required != 0) {
    // date && sign private group messages
    torx.message_send(recipient_n, ENUM_PROTOCOL_STICKER_HASH_DATE_SIGNED, stickers[s].checksum as Pointer<Void>, CHECKSUM_BIN_LEN);
  } else {
    // regular messages, private messages (in authenticated pipes), public messages in public groups (in authenticated pipes)
    torx.message_send(recipient_n, ENUM_PROTOCOL_STICKER_HASH, stickers[s].checksum as Pointer<Void>, CHECKSUM_BIN_LEN);
  }
  // THE FOLLOWING IS IMPORTANT TO PREVENT FINGERPRINTING BY STICKER WALLET. XXX Note: this is in two places because reliability is better this way
  int iter = 0;
  while (iter < stickers[s].peers.length && stickers[s].peers[iter] != recipient_n && stickers[s].peers[iter] > -1) {
    iter++;
  }
  if (stickers[s].peers[iter] < 0) {
    // Register a new recipient of sticker so that they can request data
    stickers[s].peers[iter] = recipient_n;
  }
}

int ui_sticker_set(Pointer<Uint8> checksum) {
  if (checksum == nullptr) {
    error(0, "Null passed to set_sticker. Coding error. Report this.");
    return -1;
  }
  int s = 0;
  while (s < stickers.length && torx.memcmp(stickers[s].checksum as Pointer<Void>, checksum as Pointer<Void>, CHECKSUM_BIN_LEN) != 0) {
    s++;
  }
  if (s == stickers.length) {
    return -1; // sticker not found
  }
  return s;
}

void ui_sticker_save(int s) {
  if (s < 0) {
    error(0, "Cannot save sticker. No data. Coding error. Report this.");
    return;
  }
  Pointer<Utf8> encoded_p = torx.b64_encode(stickers[s].checksum as Pointer<Void>, CHECKSUM_BIN_LEN); // free'd by torx_free
  String setting_name = "sticker-gif-${encoded_p.toDartString()}";
  torx.torx_free_simple(encoded_p as Pointer<Void>);
  encoded_p = nullptr;
  Pointer<Utf8> setting_name_p = setting_name.toNativeUtf8(); // free'd by calloc.free
  torx.sql_setting(0, -1, setting_name_p, stickers[s].data as Pointer<Utf8>, stickers[s].data_len);
  calloc.free(setting_name_p);
  setting_name_p = nullptr;
  stickers[s].saved = true;
}

void ui_sticker_delete(int s) {
  if (s < 0) {
    return; // should not happen
  }
  Pointer<Utf8> encoded_p = torx.b64_encode(stickers[s].checksum as Pointer<Void>, CHECKSUM_BIN_LEN); // free'd by torx_free
  String setting_name = "sticker-gif-${encoded_p.toDartString()}";
  torx.torx_free_simple(encoded_p as Pointer<Void>);
  encoded_p = nullptr;
  Pointer<Utf8> setting_name_p = setting_name.toNativeUtf8(); // free'd by calloc.free
  torx.sql_delete_setting(0, -1, setting_name_p);
  calloc.free(setting_name_p);
  setting_name_p = nullptr;
  torx.torx_free_simple(stickers[s].checksum as Pointer<Void>);
  stickers[s].checksum = nullptr;
  torx.torx_free_simple(stickers[s].data as Pointer<Void>);
  stickers[s].data = nullptr;
  stickers.removeAt(s);
}

int ui_sticker_register(Pointer<Uint8> data, int data_len) {
  Pointer<Uint8> checksum = torx.torx_secure_malloc(CHECKSUM_BIN_LEN) as Pointer<Uint8>; // DO NOT FREE
  torx.b3sum_bin(checksum, nullptr, data, 0, data_len);
  int s = ui_sticker_set(checksum);
  if (s < 0) {
    Pointer<Uint8> allocated = torx.torx_secure_malloc(data_len) as Pointer<Uint8>;
    torx.memcpy(allocated as Pointer<Void>, data as Pointer<Void>, data_len);
    stickers.add(sticker(checksum: checksum, data: allocated, data_len: data_len, saved: false));
    s = ui_sticker_set(checksum);
    for (int iter = MAX_PEERS - 1; iter > -1; iter--) {
      stickers[s].peers.add(-1);
    }
  }
  return s;
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
                  return GridView.extent(
                    maxCrossAxisExtent: 180,
                    children: List.generate(stickers.length + 1, (index) {
                      if (index == stickers.length) {
                        return GridTile(
                            child: InkWell(
                                onTap: () async {
                                  FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowMultiple: true, allowedExtensions: ['gif']);
                                  if (result != null) {
                                    List<File> files = result.paths.map((path) => File(path!)).toList();
                                    int file_iter = 0;
                                    while (file_iter < files.length) {
                                      if (files[file_iter].path.endsWith(".gif")) {
                                        error(0,
                                            "Checkpoint new sticker: ${files[file_iter].path}"); // GOAT file_picker caches. we don't want caching. https://github.com/miguelpruivo/flutter_file_picker/issues/40 https://github.com/miguelpruivo/flutter_file_picker/issues/1093
                                        Pointer<Utf8> path_p = files[file_iter].path.toNativeUtf8(); // free'd by calloc.free
                                        Pointer<Size_t> len_p = malloc(8); // free'd by calloc.free
                                        Pointer<Uint8> bytes = torx.read_bytes(len_p, path_p); // free'd by torx_free
                                        int s = ui_sticker_register(bytes, len_p.value);
                                        torx.torx_free_simple(bytes as Pointer<Void>);
                                        bytes = nullptr;
                                        calloc.free(path_p);
                                        path_p = nullptr;
                                        calloc.free(len_p);
                                        len_p = nullptr;
                                        ui_sticker_save(s);
                                      } else {
                                        error(0, "Rejected attempt to use non-gif sticker");
                                      }
                                      file_iter++;
                                    }
                                    setState(() {});
                                  }
                                },
                                child: Icon(Icons.add, color: color.torch_off, size: sticker_size)));
                      } else {
                        return GridTile(
                            child: InkWell(
                                onTap: () {
                                  ui_sticker_send(index);
                                  Navigator.pop(context);
                                },
                                onLongPress: () {
                                  showMenu(context: context, position: getPosition(context), items: generate_message_menu(context, null, -1, -1, -1, index));
                                },
                                child: Container(
                                    decoration: BoxDecoration(
                                        color: stickers[index].saved ? Colors.transparent : color.unsaved_sticker, // color.unsaved_sticker,
                                        border: Border.all(
                                          color: stickers[index].saved ? Colors.transparent : color.unsaved_sticker, // Border color
                                          width: sticker_border_width, // Border width
                                        )),
                                    child: sticker_generator(index))));
                      }
                    }),
                  );
                })));
  }
}
