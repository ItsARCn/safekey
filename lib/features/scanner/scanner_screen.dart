import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:base32/base32.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:drift/drift.dart' as drift;
import 'package:image_picker/image_picker.dart';
import 'package:otpauth_migration/generated/GoogleAuthenticatorImport.pb.dart';
import '../../core/providers.dart';
import '../../database/database.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  final bool isGoogleImport;
  const ScannerScreen({super.key, this.isGoogleImport = false});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
  );
  bool _isProcessing = false;

  Future<void> _scanFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _isProcessing = true;
      });
      
      final BarcodeCapture? capture = await _controller.analyzeImage(image.path);
      
      if (capture != null && capture.barcodes.isNotEmpty) {
        _processBarcode(capture);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No valid QR code found in image')),
          );
          setState(() {
            _isProcessing = false;
          });
        }
      }
    }
  }

  Future<bool> _addAccountFromUri(Uri uri) async {
    try {
      final queryParams = uri.queryParameters;
      final secret = queryParams['secret']?.toUpperCase().replaceAll(' ', '') ?? '';
      
      if (secret.isEmpty) return false;
      
      base32.decode(secret);

      String issuer = queryParams['issuer'] ?? '';
      String accountName = '';
      
      final pathParts = uri.path.substring(1).split(':');
      if (pathParts.length > 1) {
        if (issuer.isEmpty) issuer = Uri.decodeComponent(pathParts[0]);
        accountName = Uri.decodeComponent(pathParts.sublist(1).join(':'));
      } else if (pathParts.isNotEmpty) {
        accountName = Uri.decodeComponent(pathParts[0]);
      }
      
      if (issuer.isEmpty) issuer = 'Unknown';
      if (accountName.isEmpty) accountName = 'Unknown';

      final algorithm = queryParams['algorithm'] ?? 'SHA1';
      final digits = int.tryParse(queryParams['digits'] ?? '6') ?? 6;
      
      final newAccount = AccountsCompanion.insert(
        issuer: issuer,
        accountName: accountName,
        secret: secret,
        algorithm: drift.Value(algorithm),
        digits: drift.Value(digits),
      );

      await ref.read(accountRepositoryProvider).insertAccount(newAccount);
      return true;
    } catch (e) {
      return false;
    }
  }

  void _processBarcode(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    
    final String? rawValue = barcodes.first.rawValue;
    if (rawValue == null) return;
    
    if (widget.isGoogleImport) {
      if (!rawValue.startsWith('otpauth-migration://offline?data=')) return;
      
      setState(() {
        _isProcessing = true;
      });

      try {
        final exp = RegExp(r"otpauth-migration\:\/\/offline\?data=(.*)$");
        final match = exp.firstMatch(rawValue);
        final encoded = match?.group(1);
        
        if (encoded != null) {
          String normalized = encoded.replaceAll('-', '+').replaceAll('_', '/');
          normalized = Uri.decodeComponent(normalized);
          while (normalized.length % 4 != 0) {
            normalized += '=';
          }
          
          final decodedBytes = base64.decode(normalized);
          final gai = GoogleAuthenticatorImport.fromBuffer(decodedBytes);
          
          int batchIndex = gai.batchIndex;
          int batchSize = gai.batchSize;
          int addedCount = 0;
          
          for (final param in gai.otpParameters) {
            final secretBytes = Uint8List.fromList(param.secret);
            final secret = base32.encode(secretBytes);
            
            String issuer = param.issuer;
            if (issuer.isEmpty) issuer = 'Unknown';
            String accountName = param.name;
            if (accountName.isEmpty) accountName = 'Unknown';
            
            String algorithm = 'SHA1';
            if (param.algorithm == GoogleAuthenticatorImport_Algorithm.ALGORITHM_SHA256) algorithm = 'SHA256';
            if (param.algorithm == GoogleAuthenticatorImport_Algorithm.ALGORITHM_SHA512) algorithm = 'SHA512';
            
            int digits = 6;
            if (param.digits == GoogleAuthenticatorImport_DigitCount.DIGIT_COUNT_EIGHT) digits = 8;
            
            final newAccount = AccountsCompanion.insert(
              issuer: issuer,
              accountName: accountName,
              secret: secret,
              algorithm: drift.Value(algorithm),
              digits: drift.Value(digits),
            );

            await ref.read(accountRepositoryProvider).insertAccount(newAccount);
            addedCount++;
          }
        
          if (mounted) {
             if (batchSize > 1 && batchIndex < batchSize - 1) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Imported $addedCount accounts. Please scan part ${batchIndex + 2} of $batchSize')),
                );
                setState(() {
                  _isProcessing = false;
                });
                _controller.start();
             } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Import complete! Added $addedCount accounts.')),
                );
                context.pop();
             }
          }
        } else {
           throw Exception("No data payload found");
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Parse error: $e')),
          );
          setState(() {
            _isProcessing = false;
          });
          _controller.start();
        }
      }
      return;
    }

    // Standard QR code scan
    if (!rawValue.startsWith('otpauth://totp/')) return;
    
    setState(() {
      _isProcessing = true;
    });

    final success = await _addAccountFromUri(Uri.parse(rawValue));
    
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account added successfully')),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid QR Code')),
        );
        setState(() {
          _isProcessing = false;
        });
        _controller.start();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isGoogleImport ? 'Scan Google Auth QR' : 'Scan QR Code'),
        actions: [
          IconButton(
            icon: const Icon(Icons.image),
            onPressed: _scanFromGallery,
          ),
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _controller,
              builder: (context, state, child) {
                switch (state.torchState) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off, color: Colors.grey);
                  case TorchState.on:
                    return const Icon(Icons.flash_on, color: Colors.yellow);
                  case TorchState.auto:
                    return const Icon(Icons.flash_auto, color: Colors.grey);
                  default:
                    return const Icon(Icons.flash_off, color: Colors.grey);
                }
              },
            ),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _controller,
              builder: (context, state, child) {
                switch (state.cameraDirection) {
                  case CameraFacing.front:
                    return const Icon(Icons.camera_front);
                  case CameraFacing.back:
                    return const Icon(Icons.camera_rear);
                  default:
                    return const Icon(Icons.camera);
                }
              },
            ),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _processBarcode,
          ),
          // Scanner Overlay overlay
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).colorScheme.primary, width: 4),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
