import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:edi/constants/utils.dart';
import 'package:edi/features/auth/services/django_api_service.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool isProcessing = false;

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    } else if (Platform.isIOS) {
      controller!.resumeCamera();
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) async {
      if (scanData.code != null && !isProcessing) {
        controller.pauseCamera();
        await _processQRCode(scanData.code!);
      }
    });
  }

  Future<void> _processQRCode(String code) async {
    setState(() {
      isProcessing = true;
    });

    try {
      // QR code should contain the attendance token
      final result = await DjangoApiService.takeAttendance(
        context: context,
        token: code,
      );

      if (result['success']) {
        showSnackBar(context, 'Attendance marked successfully!');
        Navigator.pop(context, true);
      } else {
        showSnackBar(context, 'Failed: ${result['response']['error'] ?? 'Unknown error'}');
        controller?.resumeCamera();
      }
    } catch (e) {
      showSnackBar(context, 'Error: $e');
      controller?.resumeCamera();
    }

    setState(() {
      isProcessing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
              overlay: QrScannerOverlayShape(
                borderColor: Colors.blue,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.black87,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.qr_code_scanner,
                    color: Colors.white,
                    size: 30,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Point camera at attendance QR code',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget for manual token entry
class ManualTokenEntry extends StatelessWidget {
  final TextEditingController tokenController = TextEditingController();

  ManualTokenEntry({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: tokenController,
            decoration: const InputDecoration(
              labelText: 'Enter Token',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.pin),
            ),
            keyboardType: TextInputType.number,
            maxLength: 6,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                if (tokenController.text.length == 6) {
                  final result = await DjangoApiService.takeAttendance(
                    context: context,
                    token: tokenController.text,
                  );
                  if (result['success']) {
                    showSnackBar(context, 'Attendance marked successfully!');
                    Navigator.pop(context, true);
                  }
                } else {
                  showSnackBar(context, 'Please enter a 6-digit token');
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Submit Attendance'),
            ),
          ),
        ],
      ),
    );
  }
}
