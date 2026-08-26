import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/common_widgets/app_button.dart';
import '../../../../core/common_widgets/app_loader.dart';
import '../../../../core/common_widgets/app_snackbar.dart';
import '../../../../core/common_widgets/app_text_field.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/host_entities.dart';
import '../providers/host_providers.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  final String eventId;

  const QrScannerScreen({super.key, required this.eventId});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen>
    with WidgetsBindingObserver {
  late final TextEditingController _qrInputController;
  MobileScannerController? _scannerController;
  Timer? _rebindTimer;

  CheckInResponse? _lastResult;
  bool _isScanning = false;
  bool _isBulkAdmitting = false;
  bool _isProcessingScan = false; // Synchronous in-memory gate lock
  String _lastScannedCode = '';
  int _lastScannedTime = 0;
  bool _isTorchOn = false;
  bool _cameraPermissionGranted = false;
  bool _cameraPermissionChecked = false;
  bool _cameraStarted = false;

  /// Safe setState wrapper that guarantees setState is only called when
  /// the widget is mounted and never during locked build/layout phases.
  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    if (SchedulerBinding.instance.schedulerPhase != SchedulerPhase.idle) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(fn);
      });
    } else {
      setState(fn);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _qrInputController = TextEditingController();
    // Safely check and request permission after the initial widget frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _requestCameraPermission();
      }
    });
  }

  void _initScanner() {
    _rebindTimer?.cancel();
    _scannerController?.dispose();
    _cameraStarted = false;
    _scannerController = MobileScannerController(
      autoStart: false,
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
      formats: const [BarcodeFormat.qrCode],
    );
  }

  /// Starts the camera safely after rendering, with a stop→start cycle
  /// to force SurfaceTexture frame binding on Oppo/Oplus devices.
  void _startCameraWithRebind() {
    if (_scannerController == null || _cameraStarted) return;
    _cameraStarted = true;

    // Start the camera
    _scannerController!.start().catchError((_) {});

    // Rebind frame surface
    _rebindTimer?.cancel();
    _rebindTimer = Timer(const Duration(milliseconds: 600), () {
      if (!mounted || _scannerController == null) return;
      _scannerController!.stop().then((_) {
        if (!mounted || _scannerController == null) return;
        _scannerController!.start().catchError((_) {});
      }).catchError((_) {});
    });
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.status;
    if (status.isGranted) {
      if (mounted) {
        _initScanner();
        _safeSetState(() {
          _cameraPermissionGranted = true;
          _cameraPermissionChecked = true;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _startCameraWithRebind();
        });
      }
      return;
    }
    final result = await Permission.camera.request();
    if (mounted) {
      if (result.isGranted) {
        _initScanner();
      }
      _safeSetState(() {
        _cameraPermissionGranted = result.isGranted;
        _cameraPermissionChecked = true;
      });
      if (result.isGranted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _startCameraWithRebind();
        });
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_scannerController == null) return;

    switch (state) {
      case AppLifecycleState.resumed:
        if (!_cameraPermissionGranted) {
          _requestCameraPermission();
        } else if (_cameraStarted) {
          // Reconnect camera hardware when user returns to the app
          _scannerController?.start().catchError((_) {});
        }
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        // Immediately release camera hardware when app is backgrounded or inactive
        _rebindTimer?.cancel();
        _scannerController?.stop().catchError((_) {});
        break;
    }
  }

  Future<void> _stopScannerSafely() async {
    _rebindTimer?.cancel();
    try {
      await _scannerController?.stop();
    } catch (_) {}
  }

  @override
  void deactivate() {
    // Stop camera as soon as the screen is navigating away
    _stopScannerSafely();
    super.deactivate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _rebindTimer?.cancel();
    _rebindTimer = null;
    _qrInputController.dispose();
    _scannerController?.dispose();
    _scannerController = null;
    super.dispose();
  }

  Future<void> _handleScan(String qrCode) async {
    if (qrCode.trim().isEmpty) {
      _isProcessingScan = false;
      return;
    }
    _safeSetState(() => _isScanning = true);
    try {
      final result = await ref
          .read(hostRepositoryProvider)
          .checkInAttendee(widget.eventId, qrCode.trim());
      
      if (mounted) {
        _safeSetState(() => _lastResult = result);
      }

      // Trigger vibration/haptic feedback
      if (result.success) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.heavyImpact();
      }

      // Refresh live gate stats & event details
      ref.invalidate(hostGateStatsProvider(widget.eventId));
      ref.invalidate(hostEventDetailProvider(widget.eventId));
    } catch (e) {
      if (mounted) {
        _safeSetState(() {
          _lastResult = CheckInResponse(
            success: false,
            isDuplicate: false,
            message: 'Error validating pass: $e',
          );
        });
      }
      HapticFeedback.heavyImpact();
    } finally {
      if (mounted) {
        _safeSetState(() => _isScanning = false);
      }
      // Release scanning lock after cooldown period
      Future.delayed(const Duration(milliseconds: 1500), () {
        _isProcessingScan = false;
      });
    }
  }

  Future<void> _handleBulkGroupCheckIn(
      String registrationId, int remainingCount) async {
    _safeSetState(() => _isBulkAdmitting = true);
    try {
      final res = await ref.read(hostRepositoryProvider).bulkCheckIn(
            widget.eventId,
            registrationId: registrationId,
            count: remainingCount,
          );
      if (!mounted) return;
      AppSnackbar.show(
        context,
        message: res.message,
        type: res.success ? SnackbarType.success : SnackbarType.error,
      );

      // Update result group status
      if (_lastResult != null && _lastResult!.groupSummary != null) {
        final old = _lastResult!;
        _safeSetState(() {
          _lastResult = CheckInResponse(
            success: true,
            isDuplicate: false,
            message:
                '✅ All ${old.groupSummary!.totalPassesBooked} Group Passes Checked In',
            checkedInAt: DateTime.now(),
            ticketId: old.ticketId,
            ticketNumber: old.ticketNumber,
            registrationId: old.registrationId,
            attendee: old.attendee,
            ticketType: old.ticketType,
            groupSummary: CheckInGroupSummary(
              totalPassesBooked: old.groupSummary!.totalPassesBooked,
              checkedInPasses: old.groupSummary!.totalPassesBooked,
              remainingPasses: 0,
            ),
          );
        });
      }

      ref.invalidate(hostGateStatsProvider(widget.eventId));
      ref.invalidate(hostEventDetailProvider(widget.eventId));
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.show(
        context,
        message: 'Bulk admit failed: $e',
        type: SnackbarType.error,
      );
    } finally {
      if (mounted) {
        _safeSetState(() => _isBulkAdmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(hostGateStatsProvider(widget.eventId));

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        _stopScannerSafely();
      },
      child: Scaffold(
        backgroundColor: AppColors.getBg(context),
        appBar: AppBar(
          backgroundColor: AppColors.getSurface(context),
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                color: AppColors.getTextPrimary(context), size: 18),
            onPressed: () async {
              await _stopScannerSafely();
              if (context.mounted) {
                context.pop();
              }
            },
          ),
          title: Text(
            'Gate Entry Scanner',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.getTextPrimary(context),
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 20),
              onPressed: () =>
                  ref.invalidate(hostGateStatsProvider(widget.eventId)),
            ),
          ],
        ),
        body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Live Gate Statistics Card ─────────────────────────────────
            statsAsync.when(
              loading: () => const SizedBox(
                height: 80,
                child: Center(child: AppLoader()),
              ),
              error: (_, __) => const SizedBox.shrink(),
              data: (stats) {
                if (stats == null) return const SizedBox.shrink();
                return Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.getSurface(context),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.getBorder(context)),
                    boxShadow: AppColors.getCardShadow(context),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'LIVE GATE METRICS',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.getTextSecondary(context),
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                          if (stats.duplicateAttempts > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${stats.duplicateAttempts} Duplicates Blocked',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFFEF4444),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _StatMiniBox(
                              label: 'Checked In',
                              value: '${stats.totalCheckedIn}',
                              color: const Color(0xFF10B981),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatMiniBox(
                              label: 'Remaining',
                              value: '${stats.remainingAttendees}',
                              color: const Color(0xFF3B82F6),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatMiniBox(
                              label: 'Total Sold',
                              value: '${stats.totalTicketsSold}',
                              color: AppColors.getTextPrimary(context),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatMiniBox(
                              label: 'Gate %',
                              value: '${stats.checkInPercentage.toStringAsFixed(0)}%',
                              color: const Color(0xFF8B5CF6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),

            // ── Live Camera Viewfinder Container ──────────────────────────
            Container(
              height: 280,
              width: double.infinity,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _lastResult == null
                      ? AppColors.primary
                      : (_lastResult!.success
                          ? const Color(0xFF10B981)
                          : (_lastResult!.isDuplicate
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFFEF4444))),
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Stack(
                fit: StackFit.expand,
                alignment: Alignment.center,
                children: [
                  // Live Camera Stream
                  ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: !_cameraPermissionChecked
                        // Still checking permission — show spinner
                        ? const Center(
                            child: SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white70,
                              ),
                            ),
                          )
                        : !_cameraPermissionGranted
                            // Permission denied — show guidance
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.no_photography_rounded,
                                          color: Colors.redAccent, size: 40),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Camera permission is required\nto scan QR codes.',
                                        style: GoogleFonts.plusJakartaSans(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 16),
                                      ElevatedButton.icon(
                                        onPressed: () async {
                                          await openAppSettings();
                                        },
                                        icon: const Icon(
                                            Icons.settings_rounded,
                                            size: 16),
                                        label: const Text('Open Settings'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 14, vertical: 8),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      TextButton(
                                        onPressed: _requestCameraPermission,
                                        child: Text(
                                          'Retry Permission',
                                          style: GoogleFonts.plusJakartaSans(
                                            color: Colors.white70,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            // Permission granted — show live scanner
                            : MobileScanner(
                                controller: _scannerController,
                                fit: BoxFit.cover,
                                placeholderBuilder: (context, child) =>
                                    const Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                                errorBuilder: (context, error, child) {
                                  if ((error.errorDetails?.message ?? '').contains('already started') ||
                                      error.errorCode == MobileScannerErrorCode.controllerAlreadyInitialized) {
                                    return const SizedBox.shrink();
                                  }
                                  return Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.videocam_off_rounded,
                                              color: Colors.redAccent,
                                              size: 36),
                                          const SizedBox(height: 8),
                                          Text(
                                            error.errorDetails?.message ??
                                                'Camera Error: ${error.errorCode.name}',
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 12),
                                          ElevatedButton.icon(
                                            onPressed: () async {
                                              if (_scannerController == null) return;
                                              await _scannerController!.stop();
                                              if (context.mounted) {
                                                _scannerController!.start();
                                              }
                                            },
                                            icon: const Icon(
                                                Icons.refresh_rounded,
                                                size: 16),
                                            label: const Text('Retry Camera',
                                                style:
                                                    TextStyle(fontSize: 12)),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.primary,
                                              foregroundColor: Colors.white,
                                              padding:const EdgeInsets.symmetric(
                                                  horizontal: 14, vertical: 8),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                                onDetect: (BarcodeCapture capture) {
                                  if (_isScanning || _isProcessingScan) return;
                                  final barcodes = capture.barcodes;
                                  for (final barcode in barcodes) {
                                    final raw = barcode.rawValue;
                                    if (raw != null && raw.trim().isNotEmpty) {
                                      final now =
                                          DateTime.now().millisecondsSinceEpoch;
                                      // Universal 2-second cooldown between scans
                                      if (now - _lastScannedTime < 2000) return;
                                      // Same-code debounce: 5 seconds
                                      if (raw == _lastScannedCode &&
                                          (now - _lastScannedTime < 5000)) {
                                        return;
                                      }
                                      // Synchronous lock immediately
                                      _isProcessingScan = true;
                                      _lastScannedCode = raw;
                                      _lastScannedTime = now;
                                      _qrInputController.text = raw;
                                      _handleScan(raw);
                                      break;
                                    }
                                  }
                                },
                              ),
                  ),

                  // Target scanner overlay frame
                  Center(
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _lastResult == null
                              ? AppColors.primary
                              : (_lastResult!.success
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFEF4444)),
                          width: 2.5,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),

                  // Top Camera Controls (Torch & Flip)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Torch Button
                        GestureDetector(
                          onTap: () async {
                            if (_scannerController == null) return;
                            await _scannerController!.toggleTorch();
                            _safeSetState(() => _isTorchOn = !_isTorchOn);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isTorchOn
                                  ? Icons.flash_on_rounded
                                  : Icons.flash_off_rounded,
                              color: _isTorchOn
                                  ? Colors.amberAccent
                                  : Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Flip Camera Button
                        GestureDetector(
                          onTap: () => _scannerController?.switchCamera(),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.cameraswitch_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bottom scanning status pill
                  Positioned(
                    bottom: 12,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isScanning) ...[
                            const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            _isScanning
                                ? 'Verifying Ticket…'
                                : 'Align Pass QR Code Inside Frame',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Scan Result Verification Card ─────────────────────────────
            if (_lastResult != null) ...[
              _EnhancedScanResultCard(
                result: _lastResult!,
                isBulkLoading: _isBulkAdmitting,
                onBulkCheckIn: (regId, count) =>
                    _handleBulkGroupCheckIn(regId, count),
              ),
              const SizedBox(height: 20),
            ],

            // ── Manual Payload Entry / Scanner Gun ─────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.getSurface(context),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.getBorder(context)),
                boxShadow: AppColors.getCardShadow(context),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Manual Verification & Testing Gun',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.getTextPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Scan via barcode gun or paste the unique pass payload token.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppColors.getTextSecondary(context),
                    ),
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    label: 'QR Pass Payload Token',
                    hint: 'e.g. EMSQR-FEF4F4-REG123-1-9A8B7C',
                    controller: _qrInputController,
                    prefixIcon: const Icon(Icons.qr_code_rounded, size: 20),
                  ),
                  const SizedBox(height: 16),
                  AppPrimaryButton(
                    text: _isScanning ? 'Validating Token…' : 'Simulate Scan Pass',
                    isLoading: _isScanning,
                    onPressed: _isScanning
                        ? null
                        : () => _handleScan(_qrInputController.text),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Recent Gate Check-Ins Stream ──────────────────────────────
            statsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (stats) {
                if (stats == null || stats.recentCheckIns.isEmpty) {
                  return const SizedBox.shrink();
                }
                final timeFormat = DateFormat('hh:mm:ss a');
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recent Gate Admissions',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.getTextPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.getSurface(context),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.getBorder(context)),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: stats.recentCheckIns.length.clamp(0, 5),
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: AppColors.getBorder(context),
                        ),
                        itemBuilder: (context, idx) {
                          final item = stats.recentCheckIns[idx];
                          return ListTile(
                            dense: true,
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_circle_rounded,
                                color: Color(0xFF10B981),
                                size: 18,
                              ),
                            ),
                            title: Text(
                              '${item.attendeeName} (Pass #${item.ticketNumber})',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.getTextPrimary(context),
                              ),
                            ),
                            subtitle: Text(
                              '${item.ticketType} • ${item.checkedInAt != null ? timeFormat.format(item.checkedInAt!) : 'Just now'}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: AppColors.getTextSecondary(context),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
}
}

class _StatMiniBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatMiniBox({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.getTextSecondary(context),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _EnhancedScanResultCard extends StatelessWidget {
  final CheckInResponse result;
  final bool isBulkLoading;
  final void Function(String registrationId, int count) onBulkCheckIn;

  const _EnhancedScanResultCard({
    required this.result,
    required this.isBulkLoading,
    required this.onBulkCheckIn,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color border;
    IconData icon;
    String statusHeading;

    if (result.success) {
      bg = const Color(0xFF10B981).withValues(alpha: 0.08);
      border = const Color(0xFF10B981);
      icon = Icons.check_circle_rounded;
      statusHeading = '🟢 ALLOW ENTRY: VERIFIED';
    } else if (result.isDuplicate) {
      bg = const Color(0xFFF59E0B).withValues(alpha: 0.08);
      border = const Color(0xFFF59E0B);
      icon = Icons.warning_amber_rounded;
      statusHeading = '🔴 REJECT: DUPLICATE SCAN ATTEMPT!';
    } else {
      bg = const Color(0xFFEF4444).withValues(alpha: 0.08);
      border = const Color(0xFFEF4444);
      icon = Icons.cancel_rounded;
      statusHeading = '🔴 INVALID OR UNRECOGNIZED QR CODE';
    }

    final hasGroup = result.groupSummary != null &&
        result.groupSummary!.totalPassesBooked > 1;
    final remainingCount = result.groupSummary?.remainingPasses ?? 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: border, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  statusHeading,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: border,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            result.message,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.getTextPrimary(context),
            ),
          ),

          // Attendee Details
          if (result.attendee != null || result.attendeeName != null) ...[
            const Divider(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Attendee Profile',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.getTextSecondary(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        result.attendeeName ?? 'Attendee',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.getTextPrimary(context),
                        ),
                      ),
                      if (result.attendeeEmail != null &&
                          result.attendeeEmail!.isNotEmpty)
                        Text(
                          result.attendeeEmail!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: AppColors.getTextSecondary(context),
                          ),
                        ),
                    ],
                  ),
                ),
                if (result.ticketTypeName != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      result.ticketTypeName!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ],

          // Group Booking Summary
          if (hasGroup) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.getSurface(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.getBorder(context)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _GroupMetric(
                    label: 'Total Booked',
                    value: '${result.groupSummary!.totalPassesBooked}',
                  ),
                  _GroupMetric(
                    label: 'Checked In',
                    value: '${result.groupSummary!.checkedInPasses}',
                    color: const Color(0xFF10B981),
                  ),
                  _GroupMetric(
                    label: 'Remaining',
                    value: '${result.groupSummary!.remainingPasses}',
                    color: remainingCount > 0
                        ? const Color(0xFF3B82F6)
                        : AppColors.getTextSecondary(context),
                  ),
                ],
              ),
            ),
          ],

          // Bulk Check-in Quick Action
          if (result.success &&
              remainingCount > 0 &&
              result.registrationId != null) ...[
            const SizedBox(height: 14),
            AppPrimaryButton(
              text: isBulkLoading
                  ? 'Admitting Group…'
                  : '⚡ Admit All Remaining $remainingCount Passes',
              isLoading: isBulkLoading,
              onPressed: isBulkLoading
                  ? null
                  : () => onBulkCheckIn(result.registrationId!, remainingCount),
            ),
          ],
        ],
      ),
    );
  }
}

class _GroupMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _GroupMetric({
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: color ?? AppColors.getTextPrimary(context),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            color: AppColors.getTextSecondary(context),
          ),
        ),
      ],
    );
  }
}
