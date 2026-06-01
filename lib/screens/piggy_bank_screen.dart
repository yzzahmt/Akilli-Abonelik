import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../services/database_service.dart';
import '../services/market_service.dart';
import '../services/currency_service.dart';
import '../models/cash_account_model.dart';

class PiggyBankScreen extends ConsumerStatefulWidget {
  const PiggyBankScreen({super.key});

  @override
  ConsumerState<PiggyBankScreen> createState() => _PiggyBankScreenState();
}

class _PiggyBankScreenState extends ConsumerState<PiggyBankScreen> {
  double _totalWealth = 0;
  List<CashAccount> _cashAccounts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWealth();
  }

  Future<void> _loadWealth() async {
    final invs = await DBService.instance.getAllInvestments();
    final cashAccounts = await DBService.instance.getAllCashAccounts();
    final usdRate = await CurrencyService.getUSDToTRYRate();

    double total = 0;
    
    // Yatırımlar (Borsa, Kripto vs.)
    for (var inv in invs) {
      try {
        final quote = await MarketService.fetchQuote(inv.symbol);
        final rate = (inv.currency == 'USD') ? usdRate : 1.0;
        if (!quote.containsKey('error') && quote['price'] != null) {
          total += (quote['price'] as double) * inv.quantity * rate;
        } else {
          total += inv.totalBuyCost * rate;
        }
      } catch (_) {
        final rate = (inv.currency == 'USD') ? usdRate : 1.0;
        total += inv.totalBuyCost * rate;
      }
    }

    // Nakitler
    for (var cash in cashAccounts) {
      total += cash.amount; // Şimdilik hep TRY varsayıyoruz. Gerekirse kura çevrilebilir.
    }

    if (mounted) {
      setState(() {
        _cashAccounts = cashAccounts;
        _totalWealth = total;
        _isLoading = false;
      });
    }
  }

  void _showAddCashDialog() {
    final nameController = TextEditingController();
    final amountController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface1,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nakit / Banka Hesabı Ekle',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Hesap Adı (Örn: Ziraat, Yastık Altı)',
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.surface2,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Miktar (₺)',
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.surface2,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warningAmber,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  final name = nameController.text.trim();
                  final amount = double.tryParse(amountController.text) ?? 0;
                  if (name.isNotEmpty && amount > 0) {
                    await DBService.instance.insertCashAccount(
                      CashAccount(name: name, amount: amount),
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) {
                      setState(() => _isLoading = true);
                      _loadWealth();
                    }
                  }
                },
                child: Text(
                  'Ekle',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.background,
                  ),
                ),
              ),
            )
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
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Kumbara',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.warningAmber, size: 28),
            onPressed: _showAddCashDialog,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Arka plan ışık efekti
          Positioned(
            top: MediaQuery.of(context).size.height * 0.05,
            left: 0,
            right: 0,
            child: Container(
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.warningAmber.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                  radius: 0.7,
                ),
              ),
            ),
          ),
          
          // Ana İçerik
          Column(
            children: [
              const SizedBox(height: 24),
              // Altın İkonu
              const Icon(
                Icons.monetization_on_rounded, // Değiştirilen ikon (Domuz yerine Altın)
                size: 120,
                color: AppColors.warningAmber,
              )
                  .animate(onPlay: (controller) => controller.repeat(reverse: true))
                  .scaleXY(begin: 1.0, end: 1.05, duration: 2.seconds, curve: Curves.easeInOut),
              
              const SizedBox(height: 24),
              
              Text(
                'Toplam Mal Varlığım',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ).animate().fadeIn(delay: 500.ms, duration: 600.ms).slideY(begin: 0.5, end: 0),
              
              const SizedBox(height: 12),
              
              _isLoading
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: CircularProgressIndicator(color: AppColors.warningAmber),
                    )
                  : Text(
                      '₺${NumberFormat('#,##0.00', 'tr_TR').format(_totalWealth)}',
                      style: GoogleFonts.inter(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -1,
                      ),
                    ).animate().fadeIn(delay: 800.ms, duration: 800.ms).scale(begin: const Offset(0.8, 0.8)),
              
              const SizedBox(height: 24),
              
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.activeGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.activeGreen.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.trending_up_rounded, color: AppColors.activeGreen, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Birikimlerin güvende',
                      style: GoogleFonts.inter(
                        color: AppColors.activeGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 1200.ms).slideY(begin: 1.0, end: 0),
              
              const SizedBox(height: 32),
              
              // Nakit Hesaplar Listesi
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: AppColors.surface1,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Nakit / Banka Hesaplarım',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (_cashAccounts.isNotEmpty)
                            Text(
                              '${_cashAccounts.length} Hesap',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: _isLoading 
                          ? const Center(child: CircularProgressIndicator(color: AppColors.accentPurple))
                          : _cashAccounts.isEmpty 
                            ? Center(
                                child: Text(
                                  'Henüz nakit hesabı eklemediniz.',
                                  style: GoogleFonts.inter(color: AppColors.textSecondary),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _cashAccounts.length,
                                itemBuilder: (context, index) {
                                  final account = _cashAccounts[index];
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface2,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: AppColors.warningAmber.withValues(alpha: 0.15),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.warningAmber, size: 20),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Text(
                                            account.name,
                                            style: GoogleFonts.inter(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '₺${NumberFormat('#,##0', 'tr_TR').format(account.amount)}',
                                          style: GoogleFonts.inter(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: AppColors.expensiveRed, size: 20),
                                          onPressed: () async {
                                            await DBService.instance.deleteCashAccount(account.id!);
                                            _loadWealth();
                                          },
                                        )
                                      ],
                                    ),
                                  ).animate().fadeIn(delay: (200 + (index * 100)).ms).slideX(begin: 0.2, end: 0);
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 1500.ms).slideY(begin: 0.2, end: 0),
            ],
          ),

          // Para Yağmuru Animasyonu
          ...List.generate(40, (index) => _buildCoin(index)),
        ],
      ),
    );
  }

  Widget _buildCoin(int index) {
    final random = Random();
    final startX = random.nextDouble() * MediaQuery.of(context).size.width;
    final delay = random.nextInt(1200);
    final duration = 1500 + random.nextInt(1500);
    final size = 24.0 + random.nextDouble() * 24.0;
    
    final emojis = ['💸', '💵', '💰', '🪙'];
    final emoji = emojis[random.nextInt(emojis.length)];

    return Positioned(
      left: startX,
      top: -100,
      child: IgnorePointer(
        child: Text(
          emoji,
          style: TextStyle(fontSize: size),
        )
            .animate(delay: delay.ms)
            .slideY(
              begin: 0,
              end: 45, // Ekranın altına kadar düşsün
              duration: duration.ms,
              curve: Curves.easeIn,
            )
            .rotate(
              begin: 0,
              end: random.nextDouble() * 4,
              duration: duration.ms,
            )
            .fadeOut(
              delay: (duration - 400).ms, // Son anlarda kaybolsun
              duration: 400.ms,
            ),
      ),
    );
  }
}
