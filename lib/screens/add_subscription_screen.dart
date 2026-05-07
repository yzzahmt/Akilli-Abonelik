import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/subscription_provider.dart';
import '../constants/app_colors.dart';
import '../constants/service_list.dart';
import '../models/subscription.dart';
import '../providers/settings_provider.dart';
import '../utils/translations.dart';
import 'package:fl_chart/fl_chart.dart';

class AddSubscriptionScreen extends ConsumerStatefulWidget {
  final Subscription? subscriptionToEdit;

  const AddSubscriptionScreen({super.key, this.subscriptionToEdit});

  @override
  ConsumerState<AddSubscriptionScreen> createState() => _AddSubscriptionScreenState();
}

class _AddSubscriptionScreenState extends ConsumerState<AddSubscriptionScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'Tümü';

  final List<String> _categories = [
    'Tümü',
    'Video',
    'Müzik',
    'Yapay Zeka',
    'Bulut',
    'Oyun',
    'Eğitim',
    'Spor',
    'Üretkenlik',
    'Güvenlik',
    'Diğer',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.subscriptionToEdit != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSubscriptionBottomSheet(
          context: context,
          presetName: widget.subscriptionToEdit!.name,
          presetEmoji: _getEmojiForService(widget.subscriptionToEdit!.name),
          presetPrice: widget.subscriptionToEdit!.price,
          presetCategory: widget.subscriptionToEdit!.category,
          presetCurrency: widget.subscriptionToEdit!.currency,
          presetIsUsd: widget.subscriptionToEdit!.currency == 'USD',
          editSub: widget.subscriptionToEdit,
        );
      });
    }
  }

  String _getEmojiForService(String name) {
    for (var preset in AppConstants.presetSubscriptions) {
      if (preset.name.toLowerCase() == name.toLowerCase()) {
        return preset.emoji;
      }
    }
    return '➕';
  }

  List<PresetSubscription> _getFilteredServices() {
    return AppConstants.presetSubscriptions.where((preset) {
      final matchesSearch = preset.name.toLowerCase().contains(_searchQuery.toLowerCase());
      if (!matchesSearch) return false;

      if (_selectedCategory == 'Tümü') return true;
      if (_selectedCategory == 'AI' && preset.category == 'Yapay Zeka') return true;
      return preset.category.toLowerCase() == _selectedCategory.toLowerCase();
    }).toList();
  }

  void _showSubscriptionBottomSheet({
    required BuildContext context,
    required String presetName,
    required String presetEmoji,
    required double presetPrice,
    required String presetCategory,
    required String presetCurrency,
    required bool presetIsUsd,
    Subscription? editSub,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _SubscriptionFormBottomSheet(
          presetName: presetName,
          presetEmoji: presetEmoji,
          presetPrice: presetPrice,
          presetCategory: presetCategory,
          presetCurrency: presetCurrency,
          presetIsUsd: presetIsUsd,
          editSub: editSub,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredPresets = _getFilteredServices();
    final lang = ref.watch(languageProvider);

    final Map<String, String> categoriesMap = {
      'Tümü': AppTranslations.translate(lang, 'all'),
      'Video': AppTranslations.translate(lang, 'video'),
      'Müzik': AppTranslations.translate(lang, 'music'),
      'Yapay Zeka': AppTranslations.translate(lang, 'ai'),
      'Bulut': AppTranslations.translate(lang, 'cloud'),
      'Oyun': AppTranslations.translate(lang, 'gaming'),
      'Eğitim': AppTranslations.translate(lang, 'education'),
      'Spor': AppTranslations.translate(lang, 'sports'),
      'Üretkenlik': AppTranslations.translate(lang, 'productivity'),
      'Güvenlik': AppTranslations.translate(lang, 'security'),
      'Diğer': AppTranslations.translate(lang, 'other'),
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.subscriptionToEdit == null
              ? AppTranslations.translate(lang, 'add_sub_title')
              : AppTranslations.translate(lang, 'edit_sub_title'),
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextFormField(
                style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.surface1,
                  hintText: AppTranslations.translate(lang, 'search_services'),
                  hintStyle: GoogleFonts.inter(color: AppColors.textSecondary.withOpacity(0.5)),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.borderSubtle, width: 1.2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.borderSubtle, width: 1.2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.accentPurple, width: 1.5),
                  ),
                ),
              ),
            ).animate().fade(),

            const SizedBox(height: 16),

            // Category tabs
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedCategory = cat;
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.accentPurple : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppColors.accentPurple : AppColors.borderSubtle,
                            width: 1.2,
                          ),
                        ),
                        child: Text(
                          categoriesMap[cat] ?? cat,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // Service grid (3 columns)
            Expanded(
              child: GridView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.88,
                ),
                itemCount: filteredPresets.length,
                itemBuilder: (context, index) {
                  final preset = filteredPresets[index];

                  if (preset.name == 'Diğer') {
                    return InkWell(
                      onTap: () => _showSubscriptionBottomSheet(
                        context: context,
                        presetName: '',
                        presetEmoji: '➕',
                        presetPrice: 0,
                        presetCategory: 'Diğer',
                        presetCurrency: 'TRY',
                        presetIsUsd: false,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface1,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.borderSubtle,
                            width: 1.2,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add, color: AppColors.accentPurple, size: 28),
                            const SizedBox(height: 6),
                            Text(
                              AppTranslations.translate(lang, 'other'),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fade();
                  }

                  return InkWell(
                    onTap: () => _showSubscriptionBottomSheet(
                      context: context,
                      presetName: preset.name,
                      presetEmoji: preset.emoji,
                      presetPrice: preset.isUsdBased ? preset.usdAmount! : preset.price,
                      presetCategory: preset.category,
                      presetCurrency: preset.currency,
                      presetIsUsd: preset.isUsdBased,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface2,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.borderSubtle,
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            preset.emoji,
                            style: const TextStyle(fontSize: 26),
                          ),
                          const SizedBox(height: 6),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              preset.name,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            preset.isUsdBased
                                ? '\$${preset.usdAmount}'
                                : '₺${preset.price.toStringAsFixed(0)}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.accentPurple,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fade(duration: 250.ms);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubscriptionFormBottomSheet extends ConsumerStatefulWidget {
  final String presetName;
  final String presetEmoji;
  final double presetPrice;
  final String presetCategory;
  final String presetCurrency;
  final bool presetIsUsd;
  final Subscription? editSub;

  const _SubscriptionFormBottomSheet({
    required this.presetName,
    required this.presetEmoji,
    required this.presetPrice,
    required this.presetCategory,
    required this.presetCurrency,
    required this.presetIsUsd,
    this.editSub,
  });

  @override
  ConsumerState<_SubscriptionFormBottomSheet> createState() => _SubscriptionFormBottomSheetState();
}

class _SubscriptionFormBottomSheetState extends ConsumerState<_SubscriptionFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _dayController;

  bool _isUsd = false;
  bool _sendReminder = true;
  int _reminderDays = 1;
  bool _updateAllSameName = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.editSub?.name ?? widget.presetName);
    _priceController = TextEditingController(
      text: widget.editSub != null
          ? widget.editSub!.price.toString()
          : widget.presetPrice.toString(),
    );
    _dayController = TextEditingController(
      text: widget.editSub != null ? widget.editSub!.firstRenewalDate.day.toString() : '15',
    );

    _isUsd = widget.editSub != null ? widget.editSub!.currency == 'USD' : widget.presetIsUsd;
    _sendReminder = widget.editSub != null ? widget.editSub!.reminderDaysBefore > 0 : true;
    _reminderDays = widget.editSub?.reminderDaysBefore ?? 1;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _dayController.dispose();
    super.dispose();
  }

  void _save(String lang) {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final price = double.parse(_priceController.text.trim());
    final day = int.parse(_dayController.text.trim());

    final now = DateTime.now();
    DateTime renewalDate;
    try {
      renewalDate = DateTime(now.year, now.month, day);
      if (renewalDate.isBefore(now)) {
        renewalDate = DateTime(now.year, now.month + 1, day);
      }
    } catch (_) {
      renewalDate = DateTime(now.year, now.month, 1);
    }

    final usdRate = ref.read(subscriptionProvider).rates['USD'] ?? 32.50;
    final sub = Subscription(
      id: widget.editSub?.id,
      name: name,
      emoji: widget.presetEmoji,
      category: widget.presetCategory,
      priceInTL: _isUsd ? price * usdRate : price,
      isUsdBased: _isUsd,
      usdAmount: _isUsd ? price : 0.0,
      renewalDay: day,
      notifyDaysBefore: _sendReminder ? _reminderDays : 0,
      isActive: true,
      createdAt: DateTime.now().toIso8601String(),
    );

    final notifier = ref.read(subscriptionProvider.notifier);
    if (widget.editSub == null) {
      notifier.addSubscription(sub);
    } else {
      notifier.updateSubscription(sub, updateAllWithName: _updateAllSameName);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.editSub == null
            ? AppTranslations.translate(lang, 'added_success')
            : AppTranslations.translate(lang, 'updated_success')),
        backgroundColor: AppColors.activeGreen,
      ),
    );

    Navigator.of(context).pop();
    Navigator.of(context).pop();
  }

  void _delete(String lang) {
    if (widget.editSub?.id != null) {
      ref.read(subscriptionProvider.notifier).deleteSubscription(widget.editSub!.id!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppTranslations.translate(lang, 'deleted_success')),
          backgroundColor: AppColors.expensiveRed,
        ),
      );
      Navigator.of(context).pop();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final subState = ref.watch(subscriptionProvider);
    final usdRate = subState.rates['USD'] ?? 32.50;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        border: Border(
          top: BorderSide(color: AppColors.borderMedium, width: 1.5),
        ),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        widget.presetEmoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        widget.presetName.isNotEmpty ? widget.presetName : AppTranslations.translate(lang, 'custom_sub'),
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  if (widget.editSub != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.expensiveRed),
                      onPressed: () => _delete(lang),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              // Name field (for custom subscriptions)
              if (widget.presetName.isEmpty) ...[
                _buildFieldTitle(AppTranslations.translate(lang, 'sub_name')),
                _buildTextFormField(
                  controller: _nameController,
                  hintText: AppTranslations.translate(lang, 'enter_name'),
                  validator: (val) => val == null || val.trim().isEmpty ? AppTranslations.translate(lang, 'enter_name') : null,
                ),
                const SizedBox(height: 14),
              ],

              // Price
              _buildFieldTitle(_isUsd ? AppTranslations.translate(lang, 'price_in_usd') : AppTranslations.translate(lang, 'price_in_tl')),
              _buildTextFormField(
                controller: _priceController,
                hintText: AppTranslations.translate(lang, 'monthly_price'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (val) =>
                    val == null || double.tryParse(val.trim()) == null ? AppTranslations.translate(lang, 'enter_price') : null,
              ),

              const SizedBox(height: 14),

              // Day of Month
              _buildFieldTitle(AppTranslations.translate(lang, 'renewal_day')),
              _buildTextFormField(
                controller: _dayController,
                hintText: 'Örn: 15',
                keyboardType: TextInputType.number,
                validator: (val) {
                  final parsed = int.tryParse(val ?? '');
                  if (parsed == null || parsed < 1 || parsed > 31) {
                    return AppTranslations.translate(lang, 'enter_day');
                  }
                  return null;
                },
              ),

              const SizedBox(height: 14),

              // USD Toggle
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  AppTranslations.translate(lang, 'is_usd_based'),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: _isUsd
                    ? Text(
                        AppTranslations.translate(lang, 'exchange_rate').replaceAll('{rate}', usdRate.toStringAsFixed(2)),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.activeGreen,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    : null,
                activeColor: AppColors.accentPurple,
                value: _isUsd,
                onChanged: (val) {
                  setState(() {
                    _isUsd = val;
                  });
                },
              ),

              const SizedBox(height: 8),

              // Notification Toggle
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  AppTranslations.translate(lang, 'remind_before'),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                activeColor: AppColors.accentPurple,
                value: _sendReminder,
                onChanged: (val) {
                  setState(() {
                    _sendReminder = val;
                  });
                },
              ),

              if (_sendReminder) ...[
                const SizedBox(height: 6),
                _buildFieldTitle(AppTranslations.translate(lang, 'how_many_days')),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [1, 2, 3].map((days) {
                    final sel = _reminderDays == days;
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _reminderDays = days;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: sel ? AppColors.accentPurple : AppColors.surface1,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: sel ? AppColors.accentPurple : AppColors.borderSubtle,
                              width: 1.2,
                            ),
                          ),
                          child: Text(
                            AppTranslations.translate(lang, 'days_param', param: '$days'),
                            style: GoogleFonts.inter(
                              color: sel ? AppColors.textPrimary : AppColors.textSecondary,
                              fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 8),

              // Update all with same name toggle
              if (widget.editSub != null)
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    lang == 'TR' ? 'Tüm benzer abonelikleri güncelle' : 'Update all similar subscriptions',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    lang == 'TR' 
                      ? 'Bu isimdeki tüm aboneliklerin fiyatı değişecektir.' 
                      : 'All subscriptions with this name will be updated.',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  activeColor: AppColors.accentPurple,
                  value: _updateAllSameName,
                  onChanged: (val) {
                    setState(() {
                      _updateAllSameName = val;
                    });
                  },
                ),

              const SizedBox(height: 24),

              // Price History Chart (PRO)
              if (widget.editSub != null && ref.watch(isPremiumProvider)) ...[
                _buildFieldTitle(AppTranslations.translate(lang, 'price_history')),
                Container(
                  height: 120,
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface1,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: [
                            const FlSpot(0, 1),
                            const FlSpot(1, 1.2),
                            const FlSpot(2, 1.5),
                            const FlSpot(3, 1.4),
                            const FlSpot(4, 2),
                            const FlSpot(5, 2.5),
                          ],
                          isCurved: true,
                          color: AppColors.accentPurple,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppColors.accentPurple.withOpacity(0.2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  AppTranslations.translate(lang, 'example_trend'),
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
                ),
                const SizedBox(height: 24),
              ],

              const SizedBox(height: 8),

              // Save Button
              Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C6AF7), Color(0xFF6C5CE7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentPurple.withOpacity(0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: AppColors.textPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => _save(lang),
                  child: Text(
                    widget.editSub == null
                        ? AppTranslations.translate(lang, 'save')
                        : AppTranslations.translate(lang, 'update'),
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.surface1,
        hintText: hintText,
        hintStyle: GoogleFonts.inter(color: AppColors.textSecondary.withOpacity(0.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderSubtle, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderSubtle, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accentPurple, width: 1.5),
        ),
      ),
      validator: validator,
    );
  }
}
