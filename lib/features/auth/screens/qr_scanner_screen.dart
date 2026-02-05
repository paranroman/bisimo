import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/constants/app_sizes.dart';

/// QR Scanner Screen for student login
/// Child-friendly UI with clear visual feedback
class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _hasScanned = false;
  String? _scannedCode;
  bool _isTorchOn = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final code = barcode.rawValue;
      if (code != null && _isValidTokenFormat(code)) {
        setState(() {
          _hasScanned = true;
          _scannedCode = code;
        });

        // Show success feedback and return
        _showSuccessAndReturn(code);
        break;
      }
    }
  }

  bool _isValidTokenFormat(String code) {
    // Token format: XXX-XXX (6 alphanumeric with optional dash)
    final normalized = code.trim().toUpperCase().replaceAll('-', '');
    if (normalized.length != 6) return false;
    return RegExp(r'^[A-Z0-9]{6}$').hasMatch(normalized);
  }

  void _showSuccessAndReturn(String code) async {
    // Show success animation briefly
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      // Format token with dash if needed
      String formattedCode = code.trim().toUpperCase().replaceAll('-', '');
      if (formattedCode.length == 6) {
        formattedCode = '${formattedCode.substring(0, 3)}-${formattedCode.substring(3)}';
      }
      Navigator.of(context).pop(formattedCode);
    }
  }

  void _toggleTorch() async {
    await _controller.toggleTorch();
    setState(() {
      _isTorchOn = !_isTorchOn;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera View
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error, _) {
              return _buildErrorView(error.errorCode.name);
            },
          ),

          // Overlay with scan area
          _buildScanOverlay(),

          // Top bar
          _buildTopBar(),

          // Bottom instruction
          _buildBottomInstruction(),

          // Success overlay
          if (_hasScanned) _buildSuccessOverlay(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 10,
          left: 16,
          right: 16,
          bottom: 16,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Back button
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
              ),
            ),

            // Title
            const Text(
              'Scan QR Code',
              style: TextStyle(
                fontFamily: AppFonts.sfProRounded,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),

            // Torch toggle
            IconButton(
              onPressed: _toggleTorch,
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _isTorchOn
                      ? AppColors.primary.withValues(alpha: 0.8)
                      : Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isTorchOn ? Icons.flash_on : Icons.flash_off,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanOverlay() {
    return Container(
      decoration: ShapeDecoration(
        shape: QRScannerOverlayShape(
          borderColor: AppColors.primary,
          borderRadius: 20,
          borderLength: 40,
          borderWidth: 6,
          cutOutSize: 280,
          overlayColor: Colors.black.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildBottomInstruction() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: 24,
          left: 24,
          right: 24,
          bottom: MediaQuery.of(context).padding.bottom + 32,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated scan line indicator
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppSizes.radiusL),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.qr_code_2_rounded, size: 32, color: AppColors.primaryLight),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Arahkan kamera ke QR Code yang diberikan oleh gurumu',
                      style: TextStyle(
                        fontFamily: AppFonts.sfProRounded,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Manual input hint
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Atau ketik kode secara manual',
                style: TextStyle(
                  fontFamily: AppFonts.sfProRounded,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primaryLight,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.primaryLight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.8),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success icon with animation
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, size: 64, color: AppColors.primary),
              ),
              const SizedBox(height: 24),
              const Text(
                'QR Code Terdeteksi!',
                style: TextStyle(
                  fontFamily: AppFonts.sfProRounded,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _scannedCode ?? '',
                style: const TextStyle(
                  fontFamily: AppFonts.sfProRounded,
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Sedang masuk...',
                style: TextStyle(
                  fontFamily: AppFonts.sfProRounded,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView(String error) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.camera_alt_outlined, size: 64, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text(
              'Tidak dapat mengakses kamera',
              style: const TextStyle(
                fontFamily: AppFonts.sfProRounded,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pastikan aplikasi memiliki izin untuk menggunakan kamera',
              style: const TextStyle(
                fontFamily: AppFonts.sfProRounded,
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusM),
                ),
              ),
              child: const Text(
                'Kembali',
                style: TextStyle(fontFamily: AppFonts.sfProRounded, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom overlay shape for QR Scanner
class QRScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  const QRScannerOverlayShape({
    this.borderColor = Colors.white,
    this.borderWidth = 3.0,
    this.overlayColor = Colors.black54,
    this.borderRadius = 12,
    this.borderLength = 30,
    this.cutOutSize = 250,
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()..addRect(rect);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..addRect(rect)
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: rect.center, width: cutOutSize, height: cutOutSize),
          Radius.circular(borderRadius),
        ),
      )
      ..fillType = PathFillType.evenOdd;
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final paint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    final cutOutRect = Rect.fromCenter(center: rect.center, width: cutOutSize, height: cutOutSize);

    final backgroundPath = Path()
      ..addRect(rect)
      ..addRRect(RRect.fromRectAndRadius(cutOutRect, Radius.circular(borderRadius)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(backgroundPath, paint);

    // Draw corner borders
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.round;

    final left = cutOutRect.left;
    final top = cutOutRect.top;
    final right = cutOutRect.right;
    final bottom = cutOutRect.bottom;

    // Top-left corner
    canvas.drawPath(
      Path()
        ..moveTo(left, top + borderRadius + borderLength)
        ..lineTo(left, top + borderRadius)
        ..arcToPoint(Offset(left + borderRadius, top), radius: Radius.circular(borderRadius))
        ..lineTo(left + borderRadius + borderLength, top),
      borderPaint,
    );

    // Top-right corner
    canvas.drawPath(
      Path()
        ..moveTo(right - borderRadius - borderLength, top)
        ..lineTo(right - borderRadius, top)
        ..arcToPoint(Offset(right, top + borderRadius), radius: Radius.circular(borderRadius))
        ..lineTo(right, top + borderRadius + borderLength),
      borderPaint,
    );

    // Bottom-left corner
    canvas.drawPath(
      Path()
        ..moveTo(left, bottom - borderRadius - borderLength)
        ..lineTo(left, bottom - borderRadius)
        ..arcToPoint(Offset(left + borderRadius, bottom), radius: Radius.circular(borderRadius))
        ..lineTo(left + borderRadius + borderLength, bottom),
      borderPaint,
    );

    // Bottom-right corner
    canvas.drawPath(
      Path()
        ..moveTo(right - borderRadius - borderLength, bottom)
        ..lineTo(right - borderRadius, bottom)
        ..arcToPoint(Offset(right, bottom - borderRadius), radius: Radius.circular(borderRadius))
        ..lineTo(right, bottom - borderRadius - borderLength),
      borderPaint,
    );
  }

  @override
  ShapeBorder scale(double t) {
    return QRScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth * t,
      overlayColor: overlayColor,
      borderRadius: borderRadius * t,
      borderLength: borderLength * t,
      cutOutSize: cutOutSize * t,
    );
  }
}
