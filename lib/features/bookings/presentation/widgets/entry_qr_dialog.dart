import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/common_widgets/app_button.dart';
import '../../../../core/common_widgets/app_snackbar.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../home/domain/entities/catalog_entities.dart';
import '../../domain/entities/booking_entities.dart';

class EntryQrDialog extends HookWidget {
  final EventTicketPass pass;

  const EntryQrDialog({
    super.key,
    required this.pass,
  });

  static Future<void> show(BuildContext context, EventTicketPass pass) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => EntryQrDialog(pass: pass),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tickets = pass.tickets.isNotEmpty
        ? pass.tickets
        : [
            IndividualTicketModel(
              id: pass.registrationId,
              ticketNumber: 1,
              qrCode: pass.qrCodeData,
              isCheckedIn: pass.isCheckedIn,
            )
          ];

    final pageController = usePageController();
    final currentPage = useState(0);

    final currentTicket = tickets[currentPage.value.clamp(0, tickets.length - 1)];
    final qrData = currentTicket.qrCode ?? pass.qrCodeData;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.getBorder(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Entry Pass QR Code',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.getTextPrimary(context),
                        ),
                      ),
                      Text(
                        pass.eventTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColors.getTextSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: AppColors.getTextMuted(context),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          const Divider(height: 24),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  // Pass Pagination Badge if multi-ticket
                  if (tickets.length > 1) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        'Pass ${currentPage.value + 1} of ${tickets.length}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Swipeable QR Code Box
                  SizedBox(
                    height: 250,
                    child: PageView.builder(
                      controller: pageController,
                      itemCount: tickets.length,
                      onPageChanged: (idx) => currentPage.value = idx,
                      itemBuilder: (context, index) {
                        final t = tickets[index];
                        final code = t.qrCode ?? pass.qrCodeData;

                        return Center(
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                              border: Border.all(
                                color: currentTicket.isCheckedIn
                                    ? AppColors.primary
                                    : AppColors.getBorder(context),
                                width: 2,
                              ),
                            ),
                            child: QrImageView(
                              data: code,
                              version: QrVersions.auto,
                              size: 200.0,
                              backgroundColor: Colors.white,
                              eyeStyle: const QrEyeStyle(
                                eyeShape: QrEyeShape.square,
                                color: Color(0xFF1E0A3C),
                              ),
                              dataModuleStyle: const QrDataModuleStyle(
                                dataModuleShape: QrDataModuleShape.square,
                                color: Color(0xFF1E0A3C),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Carousel Indicator Dots
                  if (tickets.length > 1) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        tickets.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: currentPage.value == index ? 20 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: currentPage.value == index
                                ? AppColors.primary
                                : AppColors.getBorder(context),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: currentTicket.isCheckedIn
                          ? const Color(0xFF3B82F6).withValues(alpha: 0.12)
                          : (pass.isConfirmed
                              ? const Color(0xFF10B981).withValues(alpha: 0.12)
                              : const Color(0xFFF59E0B).withValues(alpha: 0.12)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          currentTicket.isCheckedIn
                              ? Icons.verified_user_rounded
                              : (pass.isConfirmed
                                  ? Icons.check_circle_rounded
                                  : Icons.hourglass_top_rounded),
                          size: 16,
                          color: currentTicket.isCheckedIn
                              ? const Color(0xFF2563EB)
                              : (pass.isConfirmed
                                  ? const Color(0xFF059669)
                                  : const Color(0xFFD97706)),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          currentTicket.isCheckedIn
                              ? 'CHECKED IN'
                              : (pass.isConfirmed ? 'CONFIRMED PASS' : 'PENDING REVIEW'),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: currentTicket.isCheckedIn
                                ? const Color(0xFF2563EB)
                                : (pass.isConfirmed
                                    ? const Color(0xFF059669)
                                    : const Color(0xFFD97706)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Ticket Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.getCardAlt(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.getBorder(context)),
                    ),
                    child: Column(
                      children: [
                        _DetailRow(
                          label: 'Ticket Tier',
                          value: pass.ticketTypeName,
                        ),
                        const Divider(height: 16),
                        _DetailRow(
                          label: 'Date & Time',
                          value: DateFormatter.formatEventDate(pass.eventDate),
                        ),
                        const Divider(height: 16),
                        _DetailRow(
                          label: 'Venue / Mode',
                          value: pass.venueName,
                        ),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Pass Token',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: AppColors.getTextSecondary(context),
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: qrData));
                                AppSnackbar.show(
                                  context,
                                  message: 'Pass token copied to clipboard!',
                                  type: SnackbarType.success,
                                );
                              },
                              child: Row(
                                children: [
                                  Text(
                                    qrData.length > 20
                                        ? '${qrData.substring(0, 10)}...${qrData.substring(qrData.length - 6)}'
                                        : qrData,
                                    style: GoogleFonts.firaCode(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.copy_rounded, size: 14, color: AppColors.primary),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Action Buttons
                  AppPrimaryButton(
                    text: 'Done',
                    onPressed: () => Navigator.of(context).pop(),
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

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: AppColors.getTextSecondary(context),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.getTextPrimary(context),
            ),
          ),
        ),
      ],
    );
  }
}
