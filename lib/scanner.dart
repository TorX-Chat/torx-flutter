import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'colors.dart';
import 'main.dart';
import 'language.dart';

/* NOTES:
 - Multiple detections is a known issue on Android
*/
// GOAT remove this ignore
// ignore: must_be_immutable
class RouteScan extends StatelessWidget {
  RouteScan({super.key});
  MobileScannerController cameraController = MobileScannerController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: color.chat_headerbar,
          title: Text(
            text.scan_qr,
            style: TextStyle(color: color.page_title),
          ),
          actions: [
            IconButton(
              icon: ValueListenableBuilder(
                valueListenable: cameraController.torchState,
                builder: (context, state, child) {
                  switch (state) {
                    case TorchState.off:
                      return Icon(Icons.flash_off, color: color.torch_off);
                    case TorchState.on:
                      return Icon(Icons.flash_on, color: color.torch_on);
                  }
                },
              ),
              iconSize: size_medium_icon,
              onPressed: () => cameraController.toggleTorch(),
            ),
            IconButton(
              icon: Icon(Icons.image, color: color.torch_off),
              iconSize: size_medium_icon,
              onPressed: () async {
                FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowMultiple: false, allowedExtensions: ["png", "jpg", "gif", "jpeg"]);
                if (result != null) {
                  String image = result.paths.first!;
                  await cameraController.analyzeImage(image); // if found, it will trigger as if it scanned from camera (see below)
                }
              },
            ),
            IconButton(
              icon: ValueListenableBuilder(
                valueListenable: cameraController.cameraFacingState,
                builder: (context, state, child) {
                  switch (state) {
                    case CameraFacing.front:
                      return Icon(Icons.camera_front, color: color.torch_off);
                    case CameraFacing.back:
                      return Icon(Icons.camera_rear, color: color.torch_off);
                  }
                },
              ),
              iconSize: size_medium_icon,
              onPressed: () => cameraController.switchCamera(),
            ),
          ],
        ),
        body: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            MobileScanner(
                allowDuplicates: false,
                controller: cameraController,
                onDetect: (barcode, args) async {
                  if (barcode.rawValue == null) {
                    // no barcode found, bad error that should not happen
                    entryAddPeeronionController.clear();
                    //  printf("checkpoint NO IMAGE POSITION BODY");
                  } else {
                    // barcode found
                    entryAddPeeronionController.text = barcode.rawValue!;
                    //    printf("checkpoint FOUND IMAGE POSITION BODY");
                  }
                  Navigator.pop(context);
                }),
            /*    MobileScanner(
              controller: cameraController,
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  printf('Barcode found! ${barcode.rawValue}');
                  entryAddPeeronionController.text = barcode.rawValue!;
                }
                Navigator.pop(context);
              },
            ), */ // DO NOT DELETE. Will be utilized when upgrading mobile_scanner, after SDK 34 transition
            // GOAT overlay follows mobilescanner. put any text or whatever as children HERE
          ],
        ));
  }
}
