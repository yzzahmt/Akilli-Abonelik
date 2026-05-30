import re

with open('lib/screens/add_subscription_screen.dart', 'r', encoding='utf-8') as f:
    code = f.read()

new_state_class = '''class _SubscriptionFormBottomSheetState extends ConsumerState<_SubscriptionFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _dayController;
  late TextEditingController _cycleDaysController;

  String _currency = 'TRY';
  String _billingCycle = 'Aylık';
  bool _sendReminder = true;
  int _reminderDays = 1;
  bool _updateAllSameName = true;
  
  double _usdRate = 32.50;
  double _eurRate = 35.00;
  double _gbpRate = 40.00;
  bool _isLoadingRates = false;

  final List<String> _billingCycles = ['Haftalık', '2 Haftada Bir', 'Aylık', '3 Aylık', '6 Aylık', 'Yıllık', 'Özel'];
  final List<String> _currencies = ['TRY', 'USD', 'EUR', 'GBP'];
  final List<int> _reminderOptions = [1, 3, 7];

  // Hazır şablonlar
  final List<Map<String, dynamic>> _popularTemplates = [
    {'name': 'Netflix', 'price': 199.0, 'currency': 'TRY'},
    {'name': 'Spotify', 'price': 54.0, 'currency': 'TRY'},
    {'name': 'YouTube Premium', 'price': 79.0, 'currency': 'TRY'},
    {'name': 'Amazon Prime', 'price': 36.0, 'currency': 'TRY'},
    {'name': 'Disney+', 'price': 149.0, 'currency': 'TRY'},
    {'name': 'iCloud 50GB', 'price': 29.0, 'currency': 'TRY'},
    {'name': 'Microsoft 365', 'price': 179.0, 'currency': 'TRY'},
    {'name': 'Exxen', 'price': 99.0, 'currency': 'TRY'},
    {'name': 'BluTV', 'price': 149.0, 'currency': 'TRY'},
    {'name': 'Gain', 'price': 89.0, 'currency': 'TRY'},
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.editSub?.name ?? widget.presetName);
    _priceController = TextEditingController(
      text: widget.editSub != null
          ? widget.editSub!.originalPrice > 0 ? widget.editSub!.originalPrice.toString() : widget.editSub!.price.toString()
          : widget.presetPrice.toString(),
    );
    _dayController = TextEditingController(
      text: widget.editSub != null ? widget.editSub!.firstRenewalDate.day.toString() : '15',
    );
    _cycleDaysController = TextEditingController(
      text: widget.editSub?.cycleDays.toString() ?? '30',
    );

    _currency = widget.editSub?.currency ?? (widget.presetIsUsd ? 'USD' : 'TRY');
    if (!_currencies.contains(_currency)) _currency = 'TRY';
    
    _billingCycle = widget.editSub?.billingCycle ?? 'Aylık';
    if (!_billingCycles.contains(_billingCycle)) _billingCycle = 'Aylık';

    _sendReminder = widget.editSub != null ? widget.editSub!.notifyDaysBefore > 0 : true;
    _reminderDays = widget.editSub?.notifyDaysBefore ?? 1;
    if (_reminderDays == 0) _reminderDays = 1;
    
    _fetchRates();
  }
  
  Future<void> _fetchRates() async {
    setState(() => _isLoadingRates = true);
    try {
      final subState = ref.read(subscriptionProvider);
      _usdRate = subState.rates['USD'] ?? 32.50;
      
      // Yahoo Finance fetch
      import 'dart:convert';
      import 'package:http/http.dart' as http;
      
      Future<double?> fetchRate(String symbol) async {
        try {
          final url = Uri.parse('https://query1.finance.yahoo.com/v8/finance/chart/$symbol?interval=1d&range=1d');
          final response = await http.get(url);
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            final result = data['chart']['result'][0];
            final meta = result['meta'];
            return (meta['regularMarketPrice'] as num).toDouble();
          }
        } catch (_) {}
        return null;
      }
      
      if (_currency == 'USD') {
        final rate = await fetchRate('USDTRY=X');
        if (rate != null) _usdRate = rate;
      } else if (_currency == 'EUR') {
        final rate = await fetchRate('EURTRY=X');
        if (rate != null) _eurRate = rate;
      } else if (_currency == 'GBP') {
        final rate = await fetchRate('GBPTRY=X');
        if (rate != null) _gbpRate = rate;
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingRates = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _dayController.dispose();
    _cycleDaysController.dispose();
    super.dispose();
  }
  
  double get _currentRate {
    if (_currency == 'USD') return _usdRate;
    if (_currency == 'EUR') return _eurRate;
    if (_currency == 'GBP') return _gbpRate;
    return 1.0;
  }
  
  double get _monthlyEquivalent {
    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
    if (price == 0) return 0;
    
    double monthly = price;
    if (_billingCycle == 'Haftalık') monthly = price * 52 / 12;
    else if (_billingCycle == '2 Haftada Bir') monthly = price * 26 / 12;
    else if (_billingCycle == '3 Aylık') monthly = price / 3;
    else if (_billingCycle == '6 Aylık') monthly = price / 6;
    else if (_billingCycle == 'Yıllık') monthly = price / 12;
    else if (_billingCycle == 'Özel') {
      final days = int.tryParse(_cycleDaysController.text.trim()) ?? 30;
      if (days > 0) monthly = (price / days) * 30;
    }
    
    return monthly * _currentRate;
  }

  void _save(String lang) {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final price = double.parse(_priceController.text.trim());
    final day = int.parse(_dayController.text.trim());
    final cycleDays = int.tryParse(_cycleDaysController.text.trim()) ?? 30;

    final sub = Subscription(
      id: widget.editSub?.id,
      name: name,
      emoji: widget.presetEmoji,
      category: widget.presetCategory,
      priceInTL: price * _currentRate,
      isUsdBased: _currency == 'USD',
      usdAmount: _currency == 'USD' ? price : 0.0,
      renewalDay: day,
      notifyDaysBefore: _sendReminder ? _reminderDays : 0,
      isActive: true,
      createdAt: widget.editSub?.createdAt ?? DateTime.now().toIso8601String(),
      billingCycle: _billingCycle,
      cycleDays: cycleDays,
      currency: _currency,
      originalPrice: price,
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
  
  void _applyTemplate(Map<String, dynamic> template) {
    setState(() {
      if (widget.presetName.isEmpty) _nameController.text = template['name'];
      _priceController.text = template['price'].toString();
      _currency = template['currency'];
      _billingCycle = 'Aylık';
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        border: Border(top: BorderSide(color: AppColors.borderMedium, width: 1.5)),
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
                      Text(widget.presetEmoji, style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 10),
                      Text(
                        widget.presetName.isNotEmpty ? widget.presetName : AppTranslations.translate(lang, 'custom_sub'),
                        style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
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
              const SizedBox(height: 16),
              
              // Templates (only show if it's a new custom subscription)
              if (widget.editSub == null && widget.presetName.isEmpty) ...[
                Text(lang == 'TR' ? 'Hızlı Şablonlar' : 'Quick Templates', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _popularTemplates.length,
                    itemBuilder: (context, index) {
                      final template = _popularTemplates[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          label: Text('${template['name']} (₺${template['price']})', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textPrimary)),
                          backgroundColor: AppColors.surface2,
                          side: const BorderSide(color: AppColors.borderSubtle),
                          onPressed: () => _applyTemplate(template),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Name field
              if (widget.presetName.isEmpty) ...[
                _buildFieldTitle(AppTranslations.translate(lang, 'sub_name')),
                _buildTextFormField(
                  controller: _nameController,
                  hintText: AppTranslations.translate(lang, 'enter_name'),
                  validator: (val) => val == null || val.trim().isEmpty ? AppTranslations.translate(lang, 'enter_name') : null,
                ),
                const SizedBox(height: 14),
              ],

              // Price & Currency Row
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldTitle(lang == 'TR' ? 'Tutar' : 'Amount'),
                        _buildTextFormField(
                          controller: _priceController,
                          hintText: AppTranslations.translate(lang, 'monthly_price'),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) => setState((){}),
                          validator: (val) => val == null || double.tryParse(val.trim()) == null ? AppTranslations.translate(lang, 'enter_price') : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldTitle(lang == 'TR' ? 'Para Birimi' : 'Currency'),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppColors.surface1,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.borderSubtle, width: 1.2),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _currency,
                              isExpanded: true,
                              dropdownColor: AppColors.surface2,
                              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
                              style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
                              items: _currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _currency = val;
                                    _fetchRates();
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              if (_currency != 'TRY') ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (_isLoadingRates) const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentPurple)),
                    if (!_isLoadingRates) Text('1 $_currency = ₺${_currentRate.toStringAsFixed(2)}', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ],
              const SizedBox(height: 14),
              
              // Billing Cycle
              _buildFieldTitle(lang == 'TR' ? 'Ödeme Dönemi' : 'Billing Cycle'),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _billingCycles.map((cycle) {
                    final isSelected = _billingCycle == cycle;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(cycle, style: GoogleFonts.inter(fontSize: 13, color: isSelected ? Colors.white : AppColors.textSecondary)),
                        selected: isSelected,
                        selectedColor: AppColors.accentPurple,
                        backgroundColor: AppColors.surface1,
                        side: BorderSide(color: isSelected ? AppColors.accentPurple : AppColors.borderSubtle),
                        onSelected: (selected) {
                          if (selected) setState(() => _billingCycle = cycle);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              
              if (_billingCycle == 'Özel') ...[
                const SizedBox(height: 14),
                _buildFieldTitle(lang == 'TR' ? 'Kaç günde bir?' : 'Every how many days?'),
                _buildTextFormField(
                  controller: _cycleDaysController,
                  hintText: '30',
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState((){}),
                  validator: (val) => val == null || int.tryParse(val.trim()) == null ? 'Sayı girin' : null,
                ),
              ],
              
              const SizedBox(height: 10),
              
              // Monthly equivalent calculation
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.accentPurple.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.calculate_outlined, color: AppColors.accentPurple, size: 18),
                    const SizedBox(width: 8),
                    Text('≈ Aylık ₺${_monthlyEquivalent.toStringAsFixed(2)}', style: GoogleFonts.inter(fontSize: 14, color: AppColors.accentPurple, fontWeight: FontWeight.w600)),
                  ],
                ),
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

              // Reminders
              _buildFieldTitle(lang == 'TR' ? 'Hatırlatıcı (Kaç gün önce?)' : 'Reminder (Days before)'),
              Row(
                children: [
                  Switch(
                    value: _sendReminder,
                    activeColor: AppColors.accentPurple,
                    onChanged: (val) => setState(() => _sendReminder = val),
                  ),
                  const SizedBox(width: 8),
                  if (_sendReminder)
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _reminderOptions.map((days) {
                            final isSelected = _reminderDays == days;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text('$days ${lang == 'TR' ? 'gün' : 'days'}', style: GoogleFonts.inter(fontSize: 12, color: isSelected ? Colors.white : AppColors.textSecondary)),
                                selected: isSelected,
                                selectedColor: AppColors.activeGreen,
                                backgroundColor: AppColors.surface1,
                                side: BorderSide(color: isSelected ? AppColors.activeGreen : AppColors.borderSubtle),
                                onSelected: (selected) {
                                  if (selected) setState(() => _reminderDays = days);
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  if (!_sendReminder) Text(lang == 'TR' ? 'Kapalı' : 'Off', style: GoogleFonts.inter(color: AppColors.textSecondary)),
                ],
              ),

              const SizedBox(height: 14),

              if (widget.editSub != null) ...[
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    AppTranslations.translate(lang, 'update_all_similar'),
                    style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    AppTranslations.translate(lang, 'update_all_similar_desc'),
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  activeTrackColor: AppColors.accentPurple,
                  value: _updateAllSameName,
                  onChanged: (val) => setState(() => _updateAllSameName = val),
                ),
                const SizedBox(height: 16),
              ],

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () => _save(lang),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentPurple,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    widget.editSub == null ? AppTranslations.translate(lang, 'add_sub') : AppTranslations.translate(lang, 'save'),
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 4),
      child: Text(
        text,
        style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String hintText,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.surface1,
        hintText: hintText,
        hintStyle: GoogleFonts.inter(color: AppColors.textMuted, fontWeight: FontWeight.normal),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.borderSubtle, width: 1.2)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.borderSubtle, width: 1.2)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.accentPurple, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.expensiveRed, width: 1.2)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.expensiveRed, width: 1.5)),
      ),
    );
  }
}'''

start_idx = code.find('class _SubscriptionFormBottomSheetState extends ConsumerState<_SubscriptionFormBottomSheet> {')
end_idx = code.rfind('}') + 1

new_code = code[:start_idx] + new_state_class + code[end_idx:]

with open('lib/screens/add_subscription_screen.dart', 'w', encoding='utf-8') as f:
    f.write(new_code)
