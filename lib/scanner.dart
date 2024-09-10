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
            ValueListenableBuilder(
                valueListenable: cameraController,
                builder: (context, state, child) {
                  return IconButton(
                    icon: cameraController.value.torchState == TorchState.on ? Icon(Icons.flash_on, color: color.torch_on) : Icon(Icons.flash_off, color: color.torch_off),
                    iconSize: size_medium_icon,
                    onPressed: () => cameraController.toggleTorch(),
                  );
                }),
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
            ValueListenableBuilder(
                valueListenable: cameraController,
                builder: (context, state, child) {
                  return IconButton(
                    icon: cameraController.value.cameraDirection == CameraFacing.front
                        ? Icon(Icons.camera_front, color: color.torch_off)
                        : Icon(Icons.camera_rear, color: color.torch_off),
                    iconSize: size_medium_icon,
                    onPressed: () => cameraController.switchCamera(),
                  );
                })
          ],
        ),
        body: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            MobileScanner(
              controller: cameraController,
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  if (barcode.rawValue != null) {
                    printf('Barcode found! ${barcode.rawValue}');
                    entryAddPeeronionController.text = barcode.rawValue!;
                  }
                }
                cameraController.dispose(); // necessary or crash occurs
                Navigator.pop(context);
              },
            ), // DO NOT DELETE. Will be utilized when upgrading mobile_scanner, after SDK 34 transition
            // GOAT overlay follows mobilescanner. put any text or whatever as children HERE
          ],
        ));
  }
}
