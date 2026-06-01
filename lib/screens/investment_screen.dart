import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../constants/app_colors.dart';
import '../models/investment_model.dart';
import '../services/database_service.dart';
import '../services/market_service.dart';
import '../services/currency_service.dart';
import '../services/activity_tracker.dart';
import '../widgets/ai_assistant_button.dart';

class InvestmentScreen extends StatefulWidget {
  const InvestmentScreen({super.key});

  @override
  State<InvestmentScreen> createState() => _InvestmentScreenState();
}

class _InvestmentScreenState extends State<InvestmentScreen> {
  List<Investment> _investments = [];
  bool _isLoading = true;
  final Map<String, Map<String, dynamic>> _quoteCache = {};
  DateTime _lastUpdate = DateTime.now();
  Timer? _refreshTimer;
  double _usdToTryRate = 32.50;

  @override
  void initState() {
    super.initState();
    _loadInvestments();
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _refreshQuotes();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadInvestments({bool showLoading = true}) async {
    if (showLoading) setState(() => _isLoading = true);
    final invs = await DBService.instance.getAllInvestments();
    _investments = invs;
    await _refreshQuotes();
    if (mounted) {
      setState(() {
        if (showLoading) _isLoading = false;
      });
    }
  }

  Future<void> _refreshQuotes() async {
    if (_investments.isEmpty) return;
    final futures = _investments.map((inv) async {
      final quote = await MarketService.fetchQuote(inv.symbol);
      if (!quote.containsKey('error')) {
        _quoteCache[inv.symbol] = quote;
      }
    });
    await Future.wait(futures);
    _usdToTryRate = await CurrencyService.getUSDToTRYRate();
    if (mounted) {
      setState(() {
        _lastUpdate = DateTime.now();
      });
    }
  }

  double _calcTotalValue() {
    double total = 0;
    for (var inv in _investments) {
      final cached = _quoteCache[inv.symbol];
      final price = cached?['price'] as double?;
      final rate = (inv.currency == 'USD') ? _usdToTryRate : 1.0;
      total += inv.quantity * (price ?? inv.buyPrice) * rate;
    }
    return total;
  }

  double _calcTotalCost() {
    double total = 0;
    for (var inv in _investments) {
      final rate = (inv.currency == 'USD') ? _usdToTryRate : 1.0;
      total += inv.totalBuyCost * rate;
    }
    return total;
  }

  void _showAddDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddInvestmentSheet(
        onSave: (inv) async {
          await DBService.instance.insertInvestment(inv);
          await ActivityTracker.logAction("Yatırım Eklendi", "Kullanıcı ${inv.quantity} adet ${inv.symbol} yatırımı ekledi.");
          await _loadInvestments();
        },
      ),
    );
  }

  void _showOptionsMenu(Investment inv) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface1,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(top: BorderSide(color: AppColors.borderMedium)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              inv.name,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.edit_rounded,
                  color: AppColors.accentPurple),
              title: Text('Düzenle',
                  style: GoogleFonts.inter(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (ctx) => _AddInvestmentSheet(
                    investmentToEdit: inv,
                    onSave: (updated) async {
                      await DBService.instance.updateInvestment(updated);
                      await _loadInvestments();
                    },
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.expensiveRed),
              title: Text('Sil',
                  style: GoogleFonts.inter(color: AppColors.expensiveRed)),
              onTap: () async {
                Navigator.pop(context);
                await DBService.instance.deleteInvestment(inv.id!);
                await ActivityTracker.logAction("Yatırım Silindi", "Kullanıcı '${inv.symbol}' yatırımını sildi.");
                await _loadInvestments();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Yatırım Takibi',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          const AIAssistantButton(),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                'Son: ${DateFormat('HH:mm').format(_lastUpdate)}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          )
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.accentPurple,
        backgroundColor: AppColors.surface1,
        onRefresh: () async {
          _quoteCache.clear();
          await _loadInvestments(showLoading: true);
        },
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                    color: AppColors.accentPurple))
            : _investments.isEmpty
                ? _buildEmptyState()
                : _buildList(),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7C6AF7), Color(0xFF6C5CE7)],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentPurple.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          backgroundColor: Colors.transparent,
          elevation: 0,
          onPressed: _showAddDialog,
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.show_chart_rounded,
              size: 64, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text(
            'Henüz yatırım yok',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '+ butonuna dokun ve ilk yatırımını ekle',
            style:
                GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    final totalValue = _calcTotalValue();
    final totalCost = _calcTotalCost();
    final pnl = totalValue - totalCost;
    final pnlPct = totalCost > 0 ? (pnl / totalCost * 100) : 0.0;
    final isProfit = pnl >= 0;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        // Portföy özeti
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isProfit
                  ? [
                      AppColors.activeGreen.withValues(alpha: 0.1),
                      AppColors.surface1,
                    ]
                  : [
                      AppColors.expensiveRed.withValues(alpha: 0.1),
                      AppColors.surface1,
                    ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isProfit
                      ? AppColors.activeGreen.withValues(alpha: 0.2)
                      : AppColors.expensiveRed.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Toplam Portföy Değeri',
                        style: GoogleFonts.inter(
                            fontSize: 13, color: AppColors.textSecondary),
                      ),
                      Text(
                        'Toplam Maliyet: ₺${NumberFormat('#,##0.00', 'tr_TR').format(totalCost)}',
                        style: GoogleFonts.inter(
                            fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '₺${NumberFormat('#,##0.00', 'tr_TR').format(totalValue)}',
                    style: GoogleFonts.inter(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        isProfit
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        color: isProfit
                            ? AppColors.activeGreen
                            : AppColors.expensiveRed,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Net Kar/Zarar: ${isProfit ? '+' : ''}₺${NumberFormat('#,##0.00', 'tr_TR').format(pnl)} (${isProfit ? '+' : ''}${pnlPct.toStringAsFixed(2)}%)',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isProfit
                              ? AppColors.activeGreen
                              : AppColors.expensiveRed,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fade(duration: 400.ms),

        // Yatırım kartları
        ..._investments.asMap().entries.map((e) {
          final inv = e.value;
          return GestureDetector(
            onLongPress: () => _showOptionsMenu(inv),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF141829),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Builder(
                builder: (context) {
                  final quote = _quoteCache[inv.symbol];
                  final hasQuote = quote != null;
                  
                  final currentPrice = hasQuote ? (quote['price'] as double) : inv.buyPrice;
                  final displayInv = inv.copyWith(currentPrice: currentPrice);
                  
                  final dailyChange = hasQuote ? (quote['change'] as double) : 0.0;
                  final dailyChangePct = hasQuote ? (quote['changePercent'] as double) : 0.0;
                  final isDailyProfit = dailyChange >= 0;

                  final double rate = (inv.currency == 'USD') ? _usdToTryRate : 1.0;
                  final cost = displayInv.totalBuyCost * rate;
                  final value = displayInv.totalCurrentValue * rate;
                  final pnl = displayInv.profitLoss * rate;
                  final pnlPct = displayInv.profitLossPercent;
                  final isProfit = pnl >= 0;
                  
                  // Progress bar ratio (0.0 to 1.0)
                  double progress = 0.5;
                  if (cost > 0) {
                    // if value > cost, progress > 0.5. if value < cost, progress < 0.5
                    progress = value / (cost * 2);
                    if (progress > 1.0) progress = 1.0;
                  }

                  return Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Sol: Hisse sembolü ve enstrüman adı
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      inv.symbol,
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      inv.typeEmoji,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  inv.name,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          
                          // Ortada: Anlık fiyat ve değişim yüzdesi
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                if (_isLoading && !hasQuote)
                                  const SizedBox(
                                    width: 16, height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentPurple),
                                  )
                                else ...[
                                  Text(
                                    '${quote?['currency'] == 'USD' ? '\$' : '₺'}${NumberFormat('#,##0.00', 'tr_TR').format(currentPrice)}',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isDailyProfit 
                                          ? AppColors.activeGreen.withValues(alpha: 0.2)
                                          : AppColors.expensiveRed.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${isDailyProfit ? '+' : ''}${dailyChangePct.toStringAsFixed(2)}%',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isDailyProfit ? AppColors.activeGreen : AppColors.expensiveRed,
                                      ),
                                    ),
                                  ),
                                ]
                              ],
                            ),
                          ),

                          // Sağda: Adet x alış fiyatı, Şimdiki Değer, Kar/Zarar
                          Expanded(
                            flex: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${inv.quantity} x ${inv.currency == 'USD' ? '\$' : '₺'}${inv.buyPrice.toStringAsFixed(2)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Değer: ₺${NumberFormat('#,##0.00', 'tr_TR').format(value)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Icon(
                                      isProfit ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                                      size: 12,
                                      color: isProfit ? AppColors.activeGreen : AppColors.expensiveRed,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      '${isProfit ? '+' : ''}₺${NumberFormat('#,##0.00', 'tr_TR').format(pnl)} (${isProfit ? '+' : ''}${pnlPct.toStringAsFixed(1)}%)',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isProfit ? AppColors.activeGreen : AppColors.expensiveRed,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      // Progress Bar
                      const SizedBox(height: 12),
                      Container(
                        height: 4,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.surface1,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: progress,
                          child: Container(
                            decoration: BoxDecoration(
                              color: isProfit ? AppColors.activeGreen : AppColors.expensiveRed,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ).animate().fade(
              delay: Duration(milliseconds: 50 * e.key),
              duration: 300.ms);
        }),
      ],
    );
  }
}

// Yatırım ekleme / düzenleme bottom sheet
class _AddInvestmentSheet extends StatefulWidget {
  final Investment? investmentToEdit;
  final Future<void> Function(Investment) onSave;

  const _AddInvestmentSheet({this.investmentToEdit, required this.onSave});

  @override
  State<_AddInvestmentSheet> createState() => _AddInvestmentSheetState();
}

class _AddInvestmentSheetState extends State<_AddInvestmentSheet> {
  final _formKey = GlobalKey<FormState>();
  String _selectedType = 'stock';
  final _nameController = TextEditingController();
  final _symbolController = TextEditingController();
  final _quantityController = TextEditingController();
  final _buyPriceController = TextEditingController();
  bool _isSaving = false;
  String _detectedCurrency = 'TRY';

  static const _types = [
    {'key': 'stock', 'label': 'Hisse', 'emoji': '📈'},
    {'key': 'crypto', 'label': 'Kripto', 'emoji': '₿'},
    {'key': 'gold', 'label': 'Emtia', 'emoji': '🥇'},
    {'key': 'currency', 'label': 'Döviz', 'emoji': '💵'},
  ];

  bool _isFetchingPrice = false;

  @override
  void initState() {
    super.initState();
    if (widget.investmentToEdit != null) {
      final inv = widget.investmentToEdit!;
      _selectedType = inv.type;
      _nameController.text = inv.name;
      _symbolController.text = inv.symbol;
      _quantityController.text = inv.quantity.toString();
      _buyPriceController.text = inv.buyPrice.toString();
      _detectedCurrency = inv.currency;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _symbolController.dispose();
    _quantityController.dispose();
    _buyPriceController.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrentPrice(String symbol) async {
    if (symbol.isEmpty) return;
    setState(() => _isFetchingPrice = true);
    final quote = await MarketService.fetchQuote(symbol);
    if (mounted) {
      setState(() {
        _isFetchingPrice = false;
        if (!quote.containsKey('error') && quote['price'] != null) {
          _buyPriceController.text = quote['price'].toString();
          _detectedCurrency = quote['currency'] ?? 'TRY';
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final inv = Investment(
      id: widget.investmentToEdit?.id,
      name: _nameController.text.trim(),
      symbol: _symbolController.text.trim().toUpperCase(),
      type: _selectedType,
      quantity: double.parse(_quantityController.text.trim()),
      buyPrice: double.parse(_buyPriceController.text.trim()),
      buyDate: DateTime.now().toIso8601String(),
      currency: _detectedCurrency,
      createdAt: widget.investmentToEdit?.createdAt ??
          DateTime.now().toIso8601String(),
    );

    await widget.onSave(inv);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = MarketService.getSuggestedSymbols(_selectedType);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
              Text(
                widget.investmentToEdit == null
                    ? 'Yatırım Ekle'
                    : 'Yatırımı Düzenle',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),

              // Tür seçici
              Row(
                children: _types.map((t) {
                  final isSelected = _selectedType == t['key'];
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _selectedType = t['key'] as String;
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.accentPurple
                              : AppColors.surface1,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.accentPurple
                                : AppColors.borderSubtle,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(t['emoji'] as String,
                                style: const TextStyle(fontSize: 18)),
                            const SizedBox(height: 2),
                            Text(
                              t['label'] as String,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textSecondary,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Hızlı sembol önerileri
              if (suggestions.isNotEmpty) ...[
                Text(
                  'Hızlı Seç',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 36,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: suggestions.length,
                    itemBuilder: (ctx, i) {
                      final s = suggestions[i];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _nameController.text = s['name']!;
                            _symbolController.text = s['symbol']!;
                          });
                          _fetchCurrentPrice(s['symbol']!);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.surface2,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: Text(
                            s['name']!,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
              ],

              _buildField('İsim', _nameController, 'Örn: Türk Hava Yolları'),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sembol',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _symbolController,
                    style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.surface1,
                      hintText: 'Örn: THYAO.IS',
                      hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search_rounded, color: AppColors.accentPurple),
                        onPressed: () => _fetchCurrentPrice(_symbolController.text.trim()),
                      ),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Zorunlu alan' : null,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildField('Adet', _quantityController, 'Örn: 100',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true)),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Alış Fiyatı (₺)',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _buyPriceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.surface1,
                      hintText: 'Örn: 245.50',
                      hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      suffixIcon: _isFetchingPrice
                          ? const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentPurple),
                              ),
                            )
                          : null,
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Zorunlu alan' : null,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(
                          'Kaydet',
                          style: GoogleFonts.inter(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller,
      String hint,
      {TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType ?? TextInputType.text,
          style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surface1,
            hintText: hint,
            hintStyle: GoogleFonts.inter(
                color: AppColors.textSecondary.withValues(alpha: 0.5)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderSubtle)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderSubtle)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: AppColors.accentPurple, width: 1.5)),
          ),
          validator: (v) => v == null || v.trim().isEmpty ? '$label gerekli' : null,
        ),
      ],
    );
  }
}
