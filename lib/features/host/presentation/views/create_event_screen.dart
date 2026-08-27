import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../app/app_providers.dart';
import '../../../../app/app_router.dart';
import '../../../../core/common_widgets/app_button.dart';
import '../../../../core/common_widgets/app_network_image.dart';
import '../../../../core/common_widgets/app_snackbar.dart';
import '../../../../core/common_widgets/app_text_field.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../home/domain/entities/catalog_entities.dart';
import '../../../home/presentation/providers/catalog_providers.dart';
import '../../domain/entities/host_entities.dart';
import '../providers/host_providers.dart';
import '../widgets/quota_limit_dialog.dart';

class CreateEventScreen extends HookConsumerWidget {
  const CreateEventScreen({super.key});

  static const List<String> _coverPresets = [
    'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=1200&q=80',
    'https://images.unsplash.com/photo-1511578314322-379afb476865?w=1200&q=80',
    'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=1200&q=80',
    'https://images.unsplash.com/photo-1501281668745-f7f57925c3b4?w=1200&q=80',
    'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=1200&q=80',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentStep = useState(1);
    final isSubmitting = useState(false);
    final isGeneratingMeet = useState(false);

    // ── Step 1: Basics & Visuals ──────────────────────────────────────────
    final titleController = useTextEditingController();
    final descriptionController = useTextEditingController();
    final selectedCategory = useState<EventCategory?>(null);
    final selectedCoverUrl = useState<String>(_coverPresets.first);
    final customCoverController = useTextEditingController();
    final selectedLocalFile = useState<File?>(null);
    final isUploadingCover = useState(false);
    final timezone = useState('Asia/Kolkata');
    final startDate = useState(DateTime.now().add(const Duration(days: 7, hours: 2)));
    final endDate = useState<DateTime?>(DateTime.now().add(const Duration(days: 7, hours: 6)));

    // ── Step 2: Format & Venue / Stream ───────────────────────────────────
    final eventMode = useState(EventMode.OFFLINE);
    final venueNameController = useTextEditingController();
    final venueAddressController = useTextEditingController();
    final venueCityController = useTextEditingController(text: 'Coimbatore');
    final meetingUrlController = useTextEditingController();
    final meetingPasswordController = useTextEditingController();
    final capacityType = useState('LIMITED'); // 'LIMITED' | 'UNLIMITED'
    final maxCapacityController = useTextEditingController(text: '200');

    // ── Step 3: Ticket Tiers ──────────────────────────────────────────────
    final tiers = useState<List<_TierDraftItem>>([
      _TierDraftItem(
        name: 'General Admission',
        description: 'Standard access to all keynote sessions and exhibition hall.',
        price: 0,
        isFree: true,
        quantity: 150,
      ),
    ]);

    // ── Step 4: Access Policies & Visibility ──────────────────────────────
    final approvalMode = useState(ApprovalMode.INSTANT);
    final visibility = useState('PUBLIC'); // 'PUBLIC' | 'PRIVATE'

    final categoriesAsync = ref.watch(eventCategoriesProvider);

    // Auto-select first category if loaded
    categoriesAsync.whenData((cats) {
      if (selectedCategory.value == null && cats.isNotEmpty) {
        selectedCategory.value = cats.first;
      }
    });

    // ── Navigation & Validation ───────────────────────────────────────────

    bool validateStep(int step) {
      if (step == 1) {
        if (titleController.text.trim().length < 3) {
          AppSnackbar.show(context, message: 'Please enter a valid title (min 3 characters).', type: SnackbarType.error);
          return false;
        }
        if (selectedCategory.value == null) {
          AppSnackbar.show(context, message: 'Please select an event category.', type: SnackbarType.error);
          return false;
        }
        if (startDate.value.isBefore(DateTime.now())) {
          AppSnackbar.show(context, message: 'Start date & time must be in the future.', type: SnackbarType.error);
          return false;
        }
        return true;
      } else if (step == 2) {
        if (eventMode.value == EventMode.OFFLINE) {
          if (venueNameController.text.trim().isEmpty || venueCityController.text.trim().isEmpty) {
            AppSnackbar.show(context, message: 'Please specify the venue name and host city.', type: SnackbarType.error);
            return false;
          }
        } else {
          if (meetingUrlController.text.trim().isEmpty) {
            AppSnackbar.show(context, message: 'Please provide or generate a meeting stream URL.', type: SnackbarType.error);
            return false;
          }
        }
        return true;
      } else if (step == 3) {
        if (tiers.value.isEmpty) {
          AppSnackbar.show(context, message: 'Please create at least one ticket tier.', type: SnackbarType.error);
          return false;
        }
        for (final t in tiers.value) {
          if (t.name.trim().isEmpty) {
            AppSnackbar.show(context, message: 'Every ticket tier must have a name.', type: SnackbarType.error);
            return false;
          }
        }
        return true;
      }
      return true;
    }

    // ── Local Image Picker & Upload ──────────────────────────────────────
    Future<void> handlePickImage(ImageSource source) async {
      try {
        final picker = ImagePicker();
        final pickedFile = await picker.pickImage(
          source: source,
          imageQuality: 85,
          maxWidth: 1920,
          maxHeight: 1080,
        );
        if (pickedFile == null) return;

        final file = File(pickedFile.path);
        selectedLocalFile.value = file;
        isUploadingCover.value = true;

        try {
          final dioClient = ref.read(dioClientProvider);
          final formData = FormData.fromMap({
            'file': await MultipartFile.fromFile(
              file.path,
              filename: pickedFile.name.isNotEmpty ? pickedFile.name : 'event_cover.jpg',
            ),
          });

          final uploadUrl = '${ApiConstants.baseUrl}${ApiConstants.organizerUpload}';
          final response = await dioClient.dio.post(
            uploadUrl,
            data: formData,
          );

          if (response.data != null) {
            final data = response.data;
            final url = data is Map ? (data['url'] ?? data['fileUrl'] ?? data['location'] ?? data['key']) : null;
            if (url != null && url.toString().isNotEmpty) {
              customCoverController.text = url.toString();
              selectedCoverUrl.value = url.toString();
            }
          }
          if (context.mounted) {
            AppSnackbar.show(
              context,
              message: '📸 Image selected & uploaded successfully!',
              type: SnackbarType.success,
            );
          }
        } catch (e) {
          // If server upload is unreachable/offline, still retain local image for preview
          if (context.mounted) {
            AppSnackbar.show(
              context,
              message: 'Image loaded from device storage.',
              type: SnackbarType.info,
            );
          }
        } finally {
          isUploadingCover.value = false;
        }
      } catch (e) {
        if (context.mounted) {
          AppSnackbar.show(
            context,
            message: 'Failed to pick image: $e',
            type: SnackbarType.error,
          );
        }
      }
    }

    void showImagePickerOptions() {
      showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.getSurface(context),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.cloud_upload_outlined, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Upload Cover Artwork',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.getTextPrimary(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.photo_library_rounded, color: AppColors.primary, size: 22),
                  ),
                  title: Text(
                    'Choose from Gallery',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                      color: AppColors.getTextPrimary(context),
                    ),
                  ),
                  subtitle: Text(
                    'Select photo from your device storage',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppColors.getTextSecondary(context),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    handlePickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF2563EB), size: 22),
                  ),
                  title: Text(
                    'Take a Photo',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                      color: AppColors.getTextPrimary(context),
                    ),
                  ),
                  subtitle: Text(
                    'Capture a new photo with camera',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppColors.getTextSecondary(context),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    handlePickImage(ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    Future<void> handleAutoGenerateMeet() async {
      final title = titleController.text.trim().isNotEmpty
          ? titleController.text.trim()
          : 'Virtual Event Stream';
      isGeneratingMeet.value = true;
      try {
        final res = await ref.read(hostRepositoryProvider).generateMeetRoom(title);
        meetingUrlController.text = res.meetUrl;
        if (context.mounted) {
          AppSnackbar.show(
            context,
            message: '🎉 Google Meet room auto-generated successfully!',
            type: SnackbarType.success,
          );
        }
      } catch (e) {
        if (context.mounted) {
          AppSnackbar.show(
            context,
            message: 'Failed to generate Meet room: ${e.toString()}',
            type: SnackbarType.error,
          );
        }
      } finally {
        isGeneratingMeet.value = false;
      }
    }

    Future<void> handleSaveOrPublish({required bool shouldPublish}) async {
      // 1. Proactive Check: Check if hosting quota limit is already reached
      final userSub = ref.read(userEventSubscriptionProvider).valueOrNull;
      if (userSub != null && userSub.usage.isLimitReached) {
        await showQuotaLimitDialog(
          context,
          currentPlanName: userSub.subscription?.plan?.name ?? 'Basic Event Host',
          maxAllowed: userSub.usage.maxActiveEvents ?? 5,
        );
        return;
      }

      isSubmitting.value = true;
      try {
        final coverImg = customCoverController.text.trim().isNotEmpty
            ? customCoverController.text.trim()
            : selectedCoverUrl.value;

        final capacity = int.tryParse(maxCapacityController.text.trim()) ?? 200;

        final createReq = CreateEventRequest(
          title: titleController.text.trim(),
          categoryId: selectedCategory.value?.id ?? 'general-cat',
          description: descriptionController.text.trim(),
          coverImageUrl: coverImg,
          mode: eventMode.value == EventMode.ONLINE ? 'ONLINE' : 'OFFLINE',
          visibility: visibility.value,
          approvalMode: approvalMode.value == ApprovalMode.APPROVAL_REQUIRED
              ? 'APPROVAL_REQUIRED'
              : 'INSTANT_CONFIRM',
          capacityType: capacityType.value,
          maxCapacity: capacity,
          venueName: eventMode.value == EventMode.OFFLINE ? venueNameController.text.trim() : null,
          venueAddress: eventMode.value == EventMode.OFFLINE ? venueAddressController.text.trim() : null,
          venueCity: eventMode.value == EventMode.OFFLINE ? venueCityController.text.trim() : null,
          meetingUrl: eventMode.value == EventMode.ONLINE ? meetingUrlController.text.trim() : null,
          meetingPassword: eventMode.value == EventMode.ONLINE ? meetingPasswordController.text.trim() : null,
          startDatetime: startDate.value,
          endDatetime: endDate.value,
          timezone: timezone.value,
        );

        final createdEvent = await ref.read(hostedEventsProvider.notifier).createEvent(createReq);

        // Add Ticket Tiers
        for (final tier in tiers.value) {
          try {
            await ref.read(hostRepositoryProvider).createTicketTier(
                  createdEvent.id,
                  CreateTicketTierRequest(
                    name: tier.name.trim(),
                    description: tier.description?.trim(),
                    priceInPaise: (tier.isFree ? 0 : (tier.price * 100)).round(),
                    quantity: tier.quantity,
                  ),
                );
          } catch (_) {}
        }

        // Publish if requested
        if (shouldPublish) {
          await ref.read(hostedEventsProvider.notifier).publishEvent(createdEvent.id);
        }

        // Invalidate customer discovery feeds immediately so fresh events are fetched
        ref.invalidate(eventsProvider);
        ref.invalidate(homeFeedProvider);

        if (context.mounted) {
          AppSnackbar.show(
            context,
            message: shouldPublish
                ? '🚀 Event published & live on discovery feeds!'
                : '💾 Event draft saved successfully!',
            type: SnackbarType.success,
          );
          context.pop();
        }
      } catch (e) {
        if (context.mounted) {
          if (isSubscriptionQuotaError(e)) {
            showQuotaLimitDialog(
              context,
              message: e.toString(),
              currentPlanName: userSub?.subscription?.plan?.name ?? 'Basic Event Host',
              maxAllowed: userSub?.usage.maxActiveEvents ?? 5,
            );
          } else {
            AppSnackbar.show(
              context,
              message: 'Failed to save event: ${e.toString().replaceAll('Exception: ', '').replaceAll('NetworkException: ', '')}',
              type: SnackbarType.error,
            );
          }
        }
      } finally {
        isSubmitting.value = false;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        backgroundColor: AppColors.getSurface(context),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.getTextPrimary(context), size: 18),
          onPressed: () {
            if (currentStep.value > 1) {
              currentStep.value--;
            } else {
              context.pop();
            }
          },
        ),
        title: Text(
          '5-Step Event Studio',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.getTextPrimary(context),
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'Step ${currentStep.value}/5',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Horizontal Stepper Progress Indicator ─────────────────────────
          _StepperBar(
            currentStep: currentStep.value,
            onStepTapped: (step) {
              if (step < currentStep.value || validateStep(currentStep.value)) {
                currentStep.value = step;
              }
            },
          ),

          // ── Active Step Form Body ─────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Builder(
                builder: (context) {
                  switch (currentStep.value) {
                    case 1:
                      return _Step1Basics(
                        titleController: titleController,
                        descriptionController: descriptionController,
                        selectedCategory: selectedCategory,
                        categoriesAsync: categoriesAsync,
                        selectedCoverUrl: selectedCoverUrl,
                        customCoverController: customCoverController,
                        selectedLocalFile: selectedLocalFile,
                        isUploadingCover: isUploadingCover,
                        onPickImage: showImagePickerOptions,
                        coverPresets: _coverPresets,
                        timezone: timezone,
                        startDate: startDate,
                        endDate: endDate,
                      );
                    case 2:
                      return _Step2FormatVenue(
                        eventMode: eventMode,
                        venueNameController: venueNameController,
                        venueAddressController: venueAddressController,
                        venueCityController: venueCityController,
                        meetingUrlController: meetingUrlController,
                        meetingPasswordController: meetingPasswordController,
                        capacityType: capacityType,
                        maxCapacityController: maxCapacityController,
                        isGeneratingMeet: isGeneratingMeet.value,
                        onGenerateMeet: handleAutoGenerateMeet,
                      );
                    case 3:
                      return _Step3TicketTiers(
                        tiers: tiers,
                      );
                    case 4:
                      return _Step4Policies(
                        approvalMode: approvalMode,
                        visibility: visibility,
                      );
                    default:
                      return _Step5Review(
                        title: titleController.text.trim(),
                        category: selectedCategory.value?.name ?? 'Event',
                        coverImageUrl: customCoverController.text.trim().isNotEmpty
                            ? customCoverController.text.trim()
                            : selectedCoverUrl.value,
                        startDate: startDate.value,
                        endDate: endDate.value,
                        mode: eventMode.value,
                        venue: eventMode.value == EventMode.OFFLINE
                            ? '${venueNameController.text.trim()}, ${venueCityController.text.trim()}'
                            : 'Google Meet Virtual Stream',
                        tiers: tiers.value,
                        approvalMode: approvalMode.value,
                        visibility: visibility.value,
                        capacity: int.tryParse(maxCapacityController.text.trim()) ?? 200,
                      );
                  }
                },
              ),
            ),
          ),

          // ── Bottom Step Navigation Bar ────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.getSurface(context),
              border: Border(top: BorderSide(color: AppColors.getBorder(context))),
              boxShadow: AppColors.getCardShadow(context),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  if (currentStep.value > 1) ...[
                    Expanded(
                      flex: 1,
                      child: AppSecondaryButton(
                        text: 'Previous',
                        onPressed: isSubmitting.value ? null : () => currentStep.value--,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (currentStep.value < 5)
                    Expanded(
                      flex: 2,
                      child: AppPrimaryButton(
                        text: 'Continue to Step ${currentStep.value + 1}',
                        onPressed: () {
                          if (validateStep(currentStep.value)) {
                            currentStep.value++;
                          }
                        },
                      ),
                    )
                  else ...[
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: AppColors.getBorder(context)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: isSubmitting.value ? null : () => handleSaveOrPublish(shouldPublish: false),
                        child: Text(
                          'Save Draft',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.getTextPrimary(context),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AppPrimaryButton(
                        text: isSubmitting.value ? 'Publishing...' : 'Launch & Publish 🚀',
                        isLoading: isSubmitting.value,
                        backgroundColor: AppColors.primary,
                        onPressed: isSubmitting.value ? null : () => handleSaveOrPublish(shouldPublish: true),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stepper Header Bar ────────────────────────────────────────────────────────

class _StepperBar extends StatelessWidget {
  final int currentStep;
  final ValueChanged<int> onStepTapped;

  const _StepperBar({required this.currentStep, required this.onStepTapped});

  static const _labels = ['Basics', 'Venue', 'Tiers', 'Access', 'Review'];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.getSurface(context),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: List.generate(5, (index) {
          final stepNum = index + 1;
          final isDone = stepNum < currentStep;
          final isActive = stepNum == currentStep;

          return Expanded(
            child: InkWell(
              onTap: () => onStepTapped(stepNum),
              borderRadius: BorderRadius.circular(8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      // Left segment line
                      if (index > 0)
                        Expanded(
                          child: Container(
                            height: 2.5,
                            color: isDone || isActive
                                ? AppColors.primary
                                : AppColors.getBorder(context),
                          ),
                        ),

                      // Circle Indicator
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDone
                              ? AppColors.primary // Completed -> Brand Red
                              : (isActive
                                  ? Colors.white // Current -> White
                                  : AppColors.getCardAlt(context)), // Upcoming -> Grey
                          border: Border.all(
                            color: isActive
                                ? Colors.white
                                : (isDone ? AppColors.primary : AppColors.getBorder(context)),
                            width: 2,
                          ),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : (isDone
                                  ? [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.3),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null),
                        ),
                        child: Center(
                          child: isDone
                              ? const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 15,
                                )
                              : Text(
                                  '$stepNum',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    color: isActive
                                        ? Colors.black // Current step number in bold black
                                        : AppColors.getTextSecondary(context),
                                  ),
                                ),
                        ),
                      ),

                      // Right segment line
                      if (index < 4)
                        Expanded(
                          child: Container(
                            height: 2.5,
                            color: isDone
                                ? AppColors.primary
                                : AppColors.getBorder(context),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Step Label Text
                  Text(
                    _labels[index],
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
                      color: isActive
                          ? Colors.white // Current step text -> White
                          : (isDone
                              ? AppColors.primary // Completed step text -> Red
                              : AppColors.getTextSecondary(context)), // Upcoming -> Grey
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Step 1: Basics & Visuals ──────────────────────────────────────────────────

class _Step1Basics extends ConsumerWidget {
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final ValueNotifier<EventCategory?> selectedCategory;
  final AsyncValue<List<EventCategory>> categoriesAsync;
  final ValueNotifier<String> selectedCoverUrl;
  final TextEditingController customCoverController;
  final ValueNotifier<File?> selectedLocalFile;
  final ValueNotifier<bool> isUploadingCover;
  final VoidCallback onPickImage;
  final List<String> coverPresets;
  final ValueNotifier<String> timezone;
  final ValueNotifier<DateTime> startDate;
  final ValueNotifier<DateTime?> endDate;

  const _Step1Basics({
    required this.titleController,
    required this.descriptionController,
    required this.selectedCategory,
    required this.categoriesAsync,
    required this.selectedCoverUrl,
    required this.customCoverController,
    required this.selectedLocalFile,
    required this.isUploadingCover,
    required this.onPickImage,
    required this.coverPresets,
    required this.timezone,
    required this.startDate,
    required this.endDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('EEE, d MMM yyyy • hh:mm a');
    final userSub = ref.watch(userEventSubscriptionProvider).valueOrNull;
    final isLimitReached = userSub?.usage.isLimitReached ?? false;
    final maxEvents = userSub?.usage.maxActiveEvents ?? 5;
    final activeEvents = userSub?.usage.activeEvents ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isLimitReached)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Active Hosting Limit Reached ($activeEvents/$maxEvents)',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
                          color: Colors.redAccent,
                        ),
                      ),
                      Text(
                        'Upgrade your plan to publish more live events without restrictions.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: AppColors.getTextSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => context.push(AppRoutes.hostSubscription),
                  child: Text(
                    'UPGRADE',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        _SectionHeading(
          icon: Icons.edit_note_rounded,
          title: '1. Basics & Visuals',
          subtitle: 'Set event title, category, cover artwork, and scheduled date/time.',
        ),
        const SizedBox(height: 18),

        AppTextField(
          label: 'Event Title *',
          hint: 'e.g. National AI & Tech Summit 2026',
          controller: titleController,
          prefixIcon: Icon(Icons.title_rounded, color: AppColors.getTextSecondary(context), size: 20),
        ),
        const SizedBox(height: 16),

        // Category Selector
        Text(
          'Category *',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.getTextPrimary(context),
          ),
        ),
        const SizedBox(height: 8),
        categoriesAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, __) => const Text('Failed to load categories'),
          data: (cats) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.getSurface(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.getBorder(context)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<EventCategory>(
                isExpanded: true,
                value: selectedCategory.value,
                dropdownColor: AppColors.getSurface(context),
                hint: const Text('Select Category'),
                items: cats
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(
                            c.name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.getTextPrimary(context),
                            ),
                          ),
                        ))
                    .toList(),
                onChanged: (cat) => selectedCategory.value = cat,
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Cover Presets & Local Upload
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Cover Banner Artwork',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.getTextPrimary(context),
              ),
            ),
            GestureDetector(
              onTap: onPickImage,
              child: Row(
                children: [
                  const Icon(Icons.add_photo_alternate_outlined, color: AppColors.primary, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Upload Image',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Prominent preview when a local image is selected
        if (selectedLocalFile.value != null) ...[
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      selectedLocalFile.value!,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isUploadingCover.value)
                          const SizedBox(
                            width: 10,
                            height: 10,
                            child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white),
                          )
                        else
                          const Icon(Icons.check_circle_rounded, size: 12, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          isUploadingCover.value ? 'Uploading…' : 'Local File Active',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: onPickImage,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.edit_rounded, size: 12, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                'Change',
                                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () {
                          selectedLocalFile.value = null;
                          customCoverController.clear();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Cover Presets & Upload Tile Carousel
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: coverPresets.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, idx) {
              if (idx == 0) {
                // Upload button tile
                return GestureDetector(
                  onTap: onPickImage,
                  child: Container(
                    width: 100,
                    decoration: BoxDecoration(
                      color: AppColors.getCardAlt(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selectedLocalFile.value != null ? AppColors.primary : AppColors.getBorder(context),
                        width: selectedLocalFile.value != null ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.cloud_upload_outlined, color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Upload File',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.getTextPrimary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final url = coverPresets[idx - 1];
              final isSelected = selectedCoverUrl.value == url && customCoverController.text.isEmpty && selectedLocalFile.value == null;

              return GestureDetector(
                onTap: () {
                  selectedCoverUrl.value = url;
                  selectedLocalFile.value = null;
                  customCoverController.clear();
                },
                child: Container(
                  width: 130,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: AppNetworkImage(url: url, fit: BoxFit.cover),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        AppTextField(
          label: 'Or Custom Image URL',
          hint: 'https://domain.com/banner.jpg',
          controller: customCoverController,
          prefixIcon: Icon(Icons.link_rounded, color: AppColors.getTextSecondary(context), size: 20),
        ),

        const SizedBox(height: 20),

        // Start Date & Time
        Text(
          'Start Date & Time *',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.getTextPrimary(context),
          ),
        ),
        const SizedBox(height: 8),
        _DateTimePickerBox(
          valueText: dateFormat.format(startDate.value),
          icon: Icons.calendar_today_rounded,
          onTap: () async {
            final pickedDate = await showDatePicker(
              context: context,
              initialDate: startDate.value,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (pickedDate != null && context.mounted) {
              final pickedTime = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(startDate.value),
              );
              if (pickedTime != null) {
                startDate.value = DateTime(
                  pickedDate.year,
                  pickedDate.month,
                  pickedDate.day,
                  pickedTime.hour,
                  pickedTime.minute,
                );
              }
            }
          },
        ),

        const SizedBox(height: 14),

        // End Date & Time
        Text(
          'End Date & Time (Optional)',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.getTextPrimary(context),
          ),
        ),
        const SizedBox(height: 8),
        _DateTimePickerBox(
          valueText: endDate.value != null ? dateFormat.format(endDate.value!) : 'Set end date & time',
          icon: Icons.event_available_rounded,
          onTap: () async {
            final pickedDate = await showDatePicker(
              context: context,
              initialDate: endDate.value ?? startDate.value.add(const Duration(hours: 4)),
              firstDate: startDate.value,
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (pickedDate != null && context.mounted) {
              final pickedTime = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(endDate.value ?? startDate.value.add(const Duration(hours: 4))),
              );
              if (pickedTime != null) {
                endDate.value = DateTime(
                  pickedDate.year,
                  pickedDate.month,
                  pickedDate.day,
                  pickedTime.hour,
                  pickedTime.minute,
                );
              }
            }
          },
        ),

        const SizedBox(height: 16),

        AppTextField(
          label: 'Event Story & Agenda',
          hint: 'Detailed agenda, guest speakers, schedule, networking perks...',
          controller: descriptionController,
          maxLines: 4,
        ),
      ],
    );
  }
}

// ── Step 2: Format & Venue / Stream ───────────────────────────────────────────

class _Step2FormatVenue extends StatelessWidget {
  final ValueNotifier<EventMode> eventMode;
  final TextEditingController venueNameController;
  final TextEditingController venueAddressController;
  final TextEditingController venueCityController;
  final TextEditingController meetingUrlController;
  final TextEditingController meetingPasswordController;
  final ValueNotifier<String> capacityType;
  final TextEditingController maxCapacityController;
  final bool isGeneratingMeet;
  final VoidCallback onGenerateMeet;

  const _Step2FormatVenue({
    required this.eventMode,
    required this.venueNameController,
    required this.venueAddressController,
    required this.venueCityController,
    required this.meetingUrlController,
    required this.meetingPasswordController,
    required this.capacityType,
    required this.maxCapacityController,
    required this.isGeneratingMeet,
    required this.onGenerateMeet,
  });

  @override
  Widget build(BuildContext context) {
    final isOnline = eventMode.value == EventMode.ONLINE;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeading(
          icon: Icons.hub_outlined,
          title: '2. Format & Venue / Virtual Stream',
          subtitle: 'Choose between an in-person physical hall or digital video stream.',
        ),
        const SizedBox(height: 18),

        // Mode Segment Switcher
        Row(
          children: [
            Expanded(
              child: _ModeSelectorCard(
                icon: Icons.location_on_rounded,
                title: 'In-Person',
                subtitle: 'Physical Venue Hall',
                isSelected: !isOnline,
                onTap: () => eventMode.value = EventMode.OFFLINE,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ModeSelectorCard(
                icon: Icons.videocam_rounded,
                title: 'Virtual Stream',
                subtitle: 'Google Meet / Zoom',
                isSelected: isOnline,
                onTap: () => eventMode.value = EventMode.ONLINE,
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        if (!isOnline) ...[
          AppTextField(
            label: 'Venue Name *',
            hint: 'e.g. Codissia Trade Fair Complex',
            controller: venueNameController,
            prefixIcon: Icon(Icons.business_rounded, color: AppColors.getTextSecondary(context), size: 20),
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: 'Host City *',
            hint: 'e.g. Coimbatore, Mumbai, Bangalore',
            controller: venueCityController,
            prefixIcon: Icon(Icons.location_city_rounded, color: AppColors.getTextSecondary(context), size: 20),
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: 'Full Street Address',
            hint: 'G.V. Fair Grounds, Avinashi Road',
            controller: venueAddressController,
            prefixIcon: Icon(Icons.map_rounded, color: AppColors.getTextSecondary(context), size: 20),
          ),
        ] else ...[
          // Virtual Stream Card with 1-Tap Google Meet
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.video_call_rounded, color: Color(0xFF2563EB), size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Google Meet Integration',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.getTextPrimary(context),
                            ),
                          ),
                          Text(
                            'Generate a secure room with 1 tap',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              color: AppColors.getTextSecondary(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: isGeneratingMeet
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.auto_awesome_rounded, size: 16),
                      label: Text(
                        'Auto-Gen Meet',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      onPressed: isGeneratingMeet ? null : onGenerateMeet,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: 'Meeting Join URL *',
            hint: 'https://meet.google.com/xyz-abcd-efg',
            controller: meetingUrlController,
            prefixIcon: Icon(Icons.link_rounded, color: AppColors.getTextSecondary(context), size: 20),
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: 'Meeting Passcode (Optional)',
            hint: 'e.g. TECH2026',
            controller: meetingPasswordController,
            prefixIcon: Icon(Icons.lock_outline_rounded, color: AppColors.getTextSecondary(context), size: 20),
          ),
        ],

        const SizedBox(height: 20),

        // Capacity Configuration
        Text(
          'Audience Capacity',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.getTextPrimary(context),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                value: 'LIMITED',
                groupValue: capacityType.value,
                title: Text('Limited Seats', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600)),
                contentPadding: EdgeInsets.zero,
                onChanged: (v) => capacityType.value = v!,
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                value: 'UNLIMITED',
                groupValue: capacityType.value,
                title: Text('Unlimited', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600)),
                contentPadding: EdgeInsets.zero,
                onChanged: (v) => capacityType.value = v!,
              ),
            ),
          ],
        ),

        if (capacityType.value == 'LIMITED')
          AppTextField(
            label: 'Maximum Attendees *',
            hint: 'e.g. 200',
            keyboardType: TextInputType.number,
            controller: maxCapacityController,
            prefixIcon: Icon(Icons.groups_rounded, color: AppColors.getTextSecondary(context), size: 20),
          ),
      ],
    );
  }
}

// ── Step 3: Ticket Tiers & Pricing ────────────────────────────────────────────

class _Step3TicketTiers extends HookWidget {
  final ValueNotifier<List<_TierDraftItem>> tiers;

  const _Step3TicketTiers({required this.tiers});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeading(
          icon: Icons.confirmation_number_outlined,
          title: '3. Ticket Tiers & Pricing',
          subtitle: 'Configure Free Passes, Early Bird passes, or VIP access tiers.',
        ),
        const SizedBox(height: 18),

        ...tiers.value.asMap().entries.map((entry) {
          final idx = entry.key;
          final tier = entry.value;

          return Container(
            key: ValueKey('tier_${tier.id}'),
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.getSurface(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.getBorder(context)),
              boxShadow: AppColors.getCardShadow(context),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Tier #${idx + 1}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    if (tiers.value.length > 1)
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
                        onPressed: () {
                          final updated = List<_TierDraftItem>.from(tiers.value)..removeAt(idx);
                          tiers.value = updated;
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Tier Name *',
                  hint: 'e.g. VIP Pass',
                  controller: tier.nameCtrl,
                  onChanged: (val) => tier.name = val,
                ),
                const SizedBox(height: 10),
                AppTextField(
                  label: 'Description',
                  hint: 'Access privileges...',
                  controller: tier.descCtrl,
                  onChanged: (val) => tier.description = val,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SwitchListTile(
                        value: tier.isFree,
                        title: Text('Free Pass', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700)),
                        contentPadding: EdgeInsets.zero,
                        onChanged: (isFree) {
                          tier.isFree = isFree;
                          if (isFree) {
                            tier.price = 0;
                            tier.priceCtrl.text = '0';
                          }
                          tiers.value = List.from(tiers.value);
                        },
                      ),
                    ),
                    if (!tier.isFree)
                      Expanded(
                        child: AppTextField(
                          label: 'Price (₹ INR) *',
                          hint: '499',
                          keyboardType: TextInputType.number,
                          controller: tier.priceCtrl,
                          onChanged: (val) => tier.price = double.tryParse(val) ?? 0,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                AppTextField(
                  label: 'Quantity Limit (Optional)',
                  hint: '100',
                  keyboardType: TextInputType.number,
                  controller: tier.qtyCtrl,
                  onChanged: (val) => tier.quantity = int.tryParse(val),
                ),
              ],
            ),
          );
        }),

        // Add Tier Button
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            side: const BorderSide(color: AppColors.primary, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          icon: const Icon(Icons.add_rounded, color: AppColors.primary),
          label: Text(
            '➕ Add Another Ticket Tier',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          onPressed: () {
            tiers.value = [
              ...tiers.value,
              _TierDraftItem(
                name: 'VIP Front-Row Pass',
                description: 'Full day access, speaker lounge, and networking dinner.',
                price: 999,
                isFree: false,
                quantity: 50,
              ),
            ];
          },
        ),
      ],
    );
  }
}

// ── Step 4: Access Policies & Visibility ──────────────────────────────────────

class _Step4Policies extends StatelessWidget {
  final ValueNotifier<ApprovalMode> approvalMode;
  final ValueNotifier<String> visibility;

  const _Step4Policies({
    required this.approvalMode,
    required this.visibility,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeading(
          icon: Icons.shield_outlined,
          title: '4. Access Policies & Visibility',
          subtitle: 'Define approval requirements and directory listing visibility.',
        ),
        const SizedBox(height: 18),

        Text(
          'Registration Approval Workflow',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppColors.getTextPrimary(context),
          ),
        ),
        const SizedBox(height: 10),

        _PolicyRadioCard(
          title: 'Instant Confirmation (Default)',
          subtitle: 'Attendees receive tickets and entry QR code immediately upon checkout.',
          isSelected: approvalMode.value == ApprovalMode.INSTANT,
          onTap: () => approvalMode.value = ApprovalMode.INSTANT,
        ),
        const SizedBox(height: 10),
        _PolicyRadioCard(
          title: 'Host Approval Required',
          subtitle: 'Attendees register in PENDING status. You review and approve/decline each attendee from your Host Hub.',
          isSelected: approvalMode.value == ApprovalMode.APPROVAL_REQUIRED,
          onTap: () => approvalMode.value = ApprovalMode.APPROVAL_REQUIRED,
        ),

        const SizedBox(height: 24),

        Text(
          'Event Visibility',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppColors.getTextPrimary(context),
          ),
        ),
        const SizedBox(height: 10),

        _PolicyRadioCard(
          title: 'Public Listing (Recommended)',
          subtitle: 'Visible on discovery feeds, search, and category browse.',
          isSelected: visibility.value == 'PUBLIC',
          onTap: () => visibility.value = 'PUBLIC',
        ),
        const SizedBox(height: 10),
        _PolicyRadioCard(
          title: 'Private (Unlisted)',
          subtitle: 'Only accessible via direct secret URL.',
          isSelected: visibility.value == 'PRIVATE',
          onTap: () => visibility.value = 'PRIVATE',
        ),
      ],
    );
  }
}

// ── Step 5: Review & Live Card Preview ────────────────────────────────────────

class _Step5Review extends StatelessWidget {
  final String title;
  final String category;
  final String coverImageUrl;
  final DateTime startDate;
  final DateTime? endDate;
  final EventMode mode;
  final String venue;
  final List<_TierDraftItem> tiers;
  final ApprovalMode approvalMode;
  final String visibility;
  final int capacity;

  const _Step5Review({
    required this.title,
    required this.category,
    required this.coverImageUrl,
    required this.startDate,
    required this.endDate,
    required this.mode,
    required this.venue,
    required this.tiers,
    required this.approvalMode,
    required this.visibility,
    required this.capacity,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEE, d MMM yyyy • hh:mm a');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeading(
          icon: Icons.preview_rounded,
          title: '5. Review & Live Preview',
          subtitle: 'Verify your event details before saving draft or launching live.',
        ),
        const SizedBox(height: 18),

        // Live Event Card Preview
        Text(
          'Live Card Preview',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.getTextPrimary(context),
          ),
        ),
        const SizedBox(height: 8),

        Container(
          decoration: BoxDecoration(
            color: AppColors.getSurface(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.getBorder(context)),
            boxShadow: AppColors.getCardShadow(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: AppNetworkImage(url: coverImageUrl, fit: BoxFit.cover),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: mode == EventMode.ONLINE ? const Color(0xFF3B82F6) : AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        mode == EventMode.ONLINE ? 'VIRTUAL STREAM' : 'IN-PERSON',
                        style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title.isNotEmpty ? title : 'Untitled Event',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.getTextPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.getTextSecondary(context)),
                        const SizedBox(width: 6),
                        Text(
                          dateFormat.format(startDate),
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.getTextSecondary(context)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded, size: 14, color: AppColors.getTextSecondary(context)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            venue,
                            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.getTextSecondary(context)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Metrics Breakdown Table
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.getCardAlt(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.getBorder(context)),
          ),
          child: Column(
            children: [
              _ReviewRow(label: 'Total Ticket Tiers', value: '${tiers.length} Tiers'),
              const Divider(height: 16),
              _ReviewRow(label: 'Audience Capacity', value: '$capacity Attendees'),
              const Divider(height: 16),
              _ReviewRow(
                label: 'Approval Mode',
                value: approvalMode == ApprovalMode.APPROVAL_REQUIRED ? 'Review Required' : 'Instant Confirm',
              ),
              const Divider(height: 16),
              _ReviewRow(label: 'Visibility', value: visibility),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Internal Helpers ──────────────────────────────────────────────────────────

class _TierDraftItem {
  final String id;
  String name;
  String? description;
  double price;
  bool isFree;
  int? quantity;
  final TextEditingController nameCtrl;
  final TextEditingController descCtrl;
  final TextEditingController priceCtrl;
  final TextEditingController qtyCtrl;

  _TierDraftItem({
    String? id,
    required this.name,
    this.description,
    this.price = 0,
    this.isFree = true,
    this.quantity,
  })  : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        nameCtrl = TextEditingController(text: name),
        descCtrl = TextEditingController(text: description ?? ''),
        priceCtrl = TextEditingController(text: price > 0 ? price.toStringAsFixed(0) : ''),
        qtyCtrl = TextEditingController(text: quantity != null ? quantity.toString() : '');
}

class _SectionHeading extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionHeading({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.getTextPrimary(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: AppColors.getTextSecondary(context),
            height: 1.3,
          ),
        ),
      ],
    );
  }
}

class _DateTimePickerBox extends StatelessWidget {
  final String valueText;
  final IconData icon;
  final VoidCallback onTap;

  const _DateTimePickerBox({required this.valueText, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.getSurface(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.getBorder(context)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                valueText,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.getTextPrimary(context),
                ),
              ),
            ),
            Icon(Icons.arrow_drop_down_rounded, color: AppColors.getTextSecondary(context)),
          ],
        ),
      ),
    );
  }
}

class _ModeSelectorCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeSelectorCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.getSurface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.getBorder(context),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : AppColors.getTextSecondary(context), size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: isSelected ? AppColors.primary : AppColors.getTextPrimary(context),
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.getTextSecondary(context)),
            ),
          ],
        ),
      ),
    );
  }
}

class _PolicyRadioCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _PolicyRadioCard({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.06)
              : AppColors.getSurface(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.getBorder(context),
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: isSelected ? AppColors.primary : AppColors.getTextSecondary(context),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.getTextPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppColors.getTextSecondary(context),
                      height: 1.3,
                    ),
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

class _ReviewRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReviewRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.getTextSecondary(context)),
        ),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.getTextPrimary(context),
          ),
        ),
      ],
    );
  }
}
