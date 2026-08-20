import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/common_widgets/app_button.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../providers/catalog_providers.dart';

void showCatalogFilterModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _CatalogFilterSheet(),
  );
}

class _CatalogFilterSheet extends HookConsumerWidget {
  const _CatalogFilterSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentCategory = ref.watch(selectedCategoryFilterProvider);
    final currentCity = ref.watch(selectedCityProvider);
    final currentMinPrice = ref.watch(minPriceFilterProvider);
    final currentMaxPrice = ref.watch(maxPriceFilterProvider);
    final currentDate = ref.watch(selectedDateFilterProvider);
    final currentRating = ref.watch(minRatingFilterProvider);
    final currentSort = ref.watch(catalogSortByProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    final tempCategory = useState(currentCategory);
    final tempCity = useState(currentCity);
    final tempMinPrice = useState(currentMinPrice);
    final tempMaxPrice = useState(currentMaxPrice);
    final tempDate = useState(currentDate);
    final tempRating = useState(currentRating);
    final tempSort = useState(currentSort);

    final cities = const [
      'All',
      'Coimbatore',
      'Chennai',
      'Bengaluru',
      'Mumbai',
      'Delhi NCR',
      'Hyderabad',
      'Goa',
    ];

    final sortOptions = const [
      {'label': 'Newest First', 'value': 'createdAt_desc'},
      {'label': 'Price: Low to High', 'value': 'price_asc'},
      {'label': 'Price: High to Low', 'value': 'price_desc'},
      {'label': 'Top Rated', 'value': 'rating_desc'},
    ];

    final ratingOptions = const [
      {'label': 'All', 'value': null},
      {'label': '⭐ 4.5+', 'value': 4.5},
      {'label': '⭐ 4.0+', 'value': 4.0},
      {'label': '⭐ 3.5+', 'value': 3.5},
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle Bar
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

            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filters & Sorting',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.getTextPrimary(context),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    tempCategory.value = null;
                    tempCity.value = 'All';
                    tempMinPrice.value = null;
                    tempMaxPrice.value = null;
                    tempDate.value = null;
                    tempRating.value = null;
                    tempSort.value = 'createdAt_desc';
                  },
                  child: Text(
                    'Reset All',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accentRose,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── 0. Category Filter ──────────────────────────────────────────
            Text(
              'Category',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.getTextPrimary(context),
              ),
            ),
            const SizedBox(height: 8),
            categoriesAsync.when(
              loading: () => const SizedBox(height: 36),
              error: (_, __) => const SizedBox(),
              data: (categories) {
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('All Categories'),
                      selected: tempCategory.value == null,
                      labelStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: tempCategory.value == null
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: tempCategory.value == null
                            ? Colors.white
                            : AppColors.getTextSecondary(context),
                      ),
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.getCardAlt(context),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: tempCategory.value == null
                              ? AppColors.primary
                              : AppColors.getBorder(context),
                        ),
                      ),
                      onSelected: (val) {
                        if (val) tempCategory.value = null;
                      },
                    ),
                    ...categories.map((cat) {
                      final isSelected = tempCategory.value == cat.id;
                      return ChoiceChip(
                        label: Text(cat.name),
                        selected: isSelected,
                        labelStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : AppColors.getTextSecondary(context),
                        ),
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.getCardAlt(context),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.getBorder(context),
                          ),
                        ),
                        onSelected: (val) {
                          tempCategory.value = val ? cat.id : null;
                        },
                      );
                    }),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),

            // ── 1. City Filter ─────────────────────────────────────────────
            Text(
              'Location / City',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.getTextPrimary(context),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: cities.map((city) {
                final isSelected = tempCity.value == city;
                return ChoiceChip(
                  label: Text(city == 'All' ? 'All Cities' : city),
                  selected: isSelected,
                  labelStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.getTextSecondary(context),
                  ),
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.getCardAlt(context),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.getBorder(context),
                    ),
                  ),
                  onSelected: (val) {
                    if (val) tempCity.value = city;
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // ── 2. Event Date Filter ────────────────────────────────────────
            Text(
              'Event Date',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.getTextPrimary(context),
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: tempDate.value ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context),
                      child: child!,
                    );
                  },
                );
                if (picked != null) {
                  tempDate.value = picked;
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.getCardAlt(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.getBorder(context)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        tempDate.value != null
                            ? DateFormatter.formatDate(tempDate.value!)
                            : 'Select preferred event date…',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: tempDate.value != null
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: tempDate.value != null
                              ? AppColors.getTextPrimary(context)
                              : AppColors.getTextMuted(context),
                        ),
                      ),
                    ),
                    if (tempDate.value != null)
                      GestureDetector(
                        onTap: () => tempDate.value = null,
                        child: Icon(Icons.close_rounded,
                            size: 16, color: AppColors.getTextMuted(context)),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── 3. Price / Budget Range ─────────────────────────────────────
            Text(
              'Budget Range',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.getTextPrimary(context),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _budgetChip(
                  context: context,
                  label: 'Under ₹50k',
                  isSelected: tempMinPrice.value == null && tempMaxPrice.value == 5000000,
                  onTap: () {
                    tempMinPrice.value = null;
                    tempMaxPrice.value = 5000000;
                  },
                ),
                _budgetChip(
                  context: context,
                  label: '₹50k - ₹1.5L',
                  isSelected: tempMinPrice.value == 5000000 && tempMaxPrice.value == 15000000,
                  onTap: () {
                    tempMinPrice.value = 5000000;
                    tempMaxPrice.value = 15000000;
                  },
                ),
                _budgetChip(
                  context: context,
                  label: '₹1.5L - ₹5L',
                  isSelected: tempMinPrice.value == 15000000 && tempMaxPrice.value == 50000000,
                  onTap: () {
                    tempMinPrice.value = 15000000;
                    tempMaxPrice.value = 50000000;
                  },
                ),
                _budgetChip(
                  context: context,
                  label: '₹5L+',
                  isSelected: tempMinPrice.value == 50000000 && tempMaxPrice.value == null,
                  onTap: () {
                    tempMinPrice.value = 50000000;
                    tempMaxPrice.value = null;
                  },
                ),
                _budgetChip(
                  context: context,
                  label: 'Any Budget',
                  isSelected: tempMinPrice.value == null && tempMaxPrice.value == null,
                  onTap: () {
                    tempMinPrice.value = null;
                    tempMaxPrice.value = null;
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── 4. Minimum Rating ──────────────────────────────────────────
            Text(
              'Minimum Rating',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.getTextPrimary(context),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ratingOptions.map((opt) {
                final isSelected = tempRating.value == opt['value'];
                return ChoiceChip(
                  label: Text(opt['label'] as String),
                  selected: isSelected,
                  labelStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.getTextSecondary(context),
                  ),
                  selectedColor: AppColors.accentAmber,
                  backgroundColor: AppColors.getCardAlt(context),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: isSelected ? AppColors.accentAmber : AppColors.getBorder(context),
                    ),
                  ),
                  onSelected: (val) {
                    tempRating.value = opt['value'] as double?;
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // ── 5. Sorting ─────────────────────────────────────────────────
            Text(
              'Sort By',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.getTextPrimary(context),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: sortOptions.map((opt) {
                final isSelected = tempSort.value == opt['value'];
                return ChoiceChip(
                  label: Text(opt['label']!),
                  selected: isSelected,
                  labelStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.getTextSecondary(context),
                  ),
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.getCardAlt(context),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.getBorder(context),
                    ),
                  ),
                  onSelected: (val) {
                    if (val) tempSort.value = opt['value']!;
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 28),

            // ── Action Buttons ─────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: AppSecondaryButton(
                    text: 'Cancel',
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: AppPrimaryButton(
                    text: 'Apply Filters',
                    onPressed: () {
                      ref.read(selectedCategoryFilterProvider.notifier).state = tempCategory.value;
                      ref.read(selectedSubCategoryFilterProvider.notifier).state = null;
                      ref.read(selectedCityProvider.notifier).state = tempCity.value;
                      ref.read(minPriceFilterProvider.notifier).state = tempMinPrice.value;
                      ref.read(maxPriceFilterProvider.notifier).state = tempMaxPrice.value;
                      ref.read(selectedDateFilterProvider.notifier).state = tempDate.value;
                      ref.read(minRatingFilterProvider.notifier).state = tempRating.value;
                      ref.read(catalogSortByProvider.notifier).state = tempSort.value;
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _budgetChip({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.getCardAlt(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.getBorder(context),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.getTextSecondary(context),
          ),
        ),
      ),
    );
  }
}
