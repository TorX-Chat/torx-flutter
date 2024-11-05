/*
TorX: Metadata-safe Tor Chat Library 
Copyright (C) 2024 TorX

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License version 3 as
published by the Free Software Foundation.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.

Appendix:

Section 7 Exceptions:
1) Modified versions of the material and resulting works must be clearly titled in the following manner: "Unofficial TorX by Financier", where the word Financier is replaced by the financier of the modifications. Where there is no financier, the word Financier shall be replaced by the organization or individual who is primarily responsible for causing the modifications. Example: "Unofficial TorX by The United States Department of Defense". This amended full-title must replace the word "TorX" in all source code files and all resulting works. Where utilizing spaces is not possible, underscores may be utilized. Example: "Unofficial_TorX_by_The_United_States_Department_of_Defense". The title must not be replaced by an acronym or short title in any form of distribution.

2) Modified versions of the material and resulting works must be distributed with alternate logos and imagery that is substantially different from the original TorX logo and imagery, especially the 7-headed snake logo. Modified material and resulting works, where distributed with a logo or imagery, should choose and distribute a logo or imagery that reflects the Financier, organization, or individual primarily responsible for causing modifications and must not cause any user to note similarities with any of the original TorX imagery. Example: Modifications or works financed by The United States Department of Defense should choose a logo and imagery similar to existing logos and imagery utilized by The United States Department of Defense.

3) Those who modify, distribute, or finance the modification or distribution of the material or resulting works, shall not avail themselves of any disclaimers of liability, such as those laid out by the original TorX author in sections 15 and 16 of the License.

4) Those who modify, distribute, or finance the modification or distribution of the material or resulting works, shall jointly and severally indemnify the original TorX author against any claims of damages incurred and any costs arising from litigation related to any changes they are have made, caused to be made, or financed. 

5) The original author of TorX may issue explicit exemptions from the above requirements (Such as, for example, necessary changes for package maintenance in official Debian repositories), but such exemptions should be interpretted in the narrowest possible scope and to only grant limited rights within the narrowest possible scope to those who explicitly receive the exemption and not those who receive the material or resulting works from the exemptee.

6) The original author of TorX grants no exceptions from trademark protection in any form.

7) Each aspect of these exemptions are to be considered independent and severable if found in contradiction with the License or applicable law.
*/
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

  void processCapture(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      String? result = barcode.rawValue;
      if (result != null) {
        entryAddPeeronionController.text = result;
      }
    }
    cameraController.dispose(); // necessary or crash occurs
  }

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
                  String? image = result.paths.first;
                  if (image != null) {
                    BarcodeCapture? capture = await cameraController.analyzeImage(image);
                    if (capture != null) {
                      processCapture(capture);
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    }
                  }
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
                processCapture(capture);
                Navigator.pop(context);
              },
            ),
            // GOAT overlay follows mobilescanner. put any text or whatever as children HERE
          ],
        ));
  }
}
