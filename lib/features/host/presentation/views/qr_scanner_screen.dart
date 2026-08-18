import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/common_widgets/app_button.dart';
import '../../../../core/common_widgets/app_text_field.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/host_entities.dart';
import '../providers/host_providers.dart';

class QrScannerScreen extends HookConsumerWidget {
  final String eventId;

  const QrScannerScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qrInputController = useTextEditingController(
      text: 'ES-PASS-2026-SUNBURN-ROHITH-001',
    );
    final lastResult = useState<QrCheckInResult?>(null);
    final isScanning = useState(false);

    Future<void> handleScan(String qrCode) async {
      isScanning.value = true;
      final result = await ref
          .read(hostRepositoryProvider)
          .scanQrCode(eventId, qrCode.trim());
      lastResult.value = result;
      isScanning.value = false;
    }

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: AppColors.lightSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Venue Entrance Scanner',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Viewfinder
            Container(
              height: 260,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: lastResult.value == null
                      ? AppColors.primary
                      : (lastResult.value!.status == CheckInResultStatus.VALID
                          ? AppColors.statusCompleted
                          : AppColors.accentRose),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 170,
                    height: 170,
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.5), width: 2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.qr_code_scanner_rounded,
                          color: Colors.white70, size: 56),
                      const SizedBox(height: 12),
                      Text(
                        'Align Pass QR Inside Frame',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Scan Result Card
            if (lastResult.value != null) ...[
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: lastResult.value!.status == CheckInResultStatus.VALID
                      ? AppColors.statusCompleted.withValues(alpha: 0.1)
                      : AppColors.accentRose.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: lastResult.value!.status == CheckInResultStatus.VALID
                        ? AppColors.statusCompleted
                        : AppColors.accentRose,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      lastResult.value!.status == CheckInResultStatus.VALID
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      color:
                          lastResult.value!.status == CheckInResultStatus.VALID
                              ? AppColors.statusCompleted
                              : AppColors.accentRose,
                      size: 32,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lastResult.value!.status ==
                                    CheckInResultStatus.VALID
                                ? 'ADMIT PASS - VALID'
                                : 'ENTRY DENIED',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: lastResult.value!.status ==
                                      CheckInResultStatus.VALID
                                  ? AppColors.statusCompleted
                                  : AppColors.accentRose,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            lastResult.value!.message,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (lastResult.value!.attendee != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Pass: ${lastResult.value!.attendee!.ticketType}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Manual Code Input
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.lightSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.lightBorder),
                boxShadow: AppColors.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Manual Verification & Testing',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'Pass QR Payload String',
                    hint: 'ES-PASS-…',
                    controller: qrInputController,
                  ),
                  const SizedBox(height: 16),
                  AppPrimaryButton(
                    text: isScanning.value ? 'Validating…' : 'Simulate Scan Pass',
                    isLoading: isScanning.value,
                    onPressed: isScanning.value
                        ? null
                        : () => handleScan(qrInputController.text),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
