// SubsTrack yeni özellik — Yatırım modeli (Bölüm 7)
class Investment {
  final int? id;
  final String name;
  final String symbol;
  final String type; // 'stock', 'crypto', 'gold', 'currency'
  final double quantity;
  final double buyPrice;
  final String buyDate;
  final String currency;
  final String? notes;
  final String createdAt;

  // Anlık fiyat (DB'de saklanmaz, runtime'da çekilir)
  final double? currentPrice;

  Investment({
    this.id,
    required this.name,
    required this.symbol,
    required this.type,
    required this.quantity,
    required this.buyPrice,
    required this.buyDate,
    this.currency = 'TRY',
    this.notes,
    required this.createdAt,
    this.currentPrice,
  });

  double get totalBuyCost => quantity * buyPrice;

  double get totalCurrentValue =>
      currentPrice != null ? quantity * currentPrice! : totalBuyCost;

  double get profitLoss => totalCurrentValue - totalBuyCost;

  double get profitLossPercent =>
      totalBuyCost > 0 ? (profitLoss / totalBuyCost) * 100 : 0;

  bool get isProfit => profitLoss >= 0;

  String get typeLabel {
    switch (type) {
      case 'stock':
        return 'Hisse';
      case 'crypto':
        return 'Kripto';
      case 'gold':
        return 'Altın';
      case 'currency':
        return 'Döviz';
      default:
        return 'Diğer';
    }
  }

  String get typeEmoji {
    switch (type) {
      case 'stock':
        return '📈';
      case 'crypto':
        return '₿';
      case 'gold':
        return '🥇';
      case 'currency':
        return '💵';
      default:
        return '📊';
    }
  }

  factory Investment.fromMap(Map<String, dynamic> map) {
    return Investment(
      id: map['id'],
      name: map['name'],
      symbol: map['symbol'],
      type: map['type'] ?? 'stock',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      buyPrice: (map['buy_price'] as num?)?.toDouble() ?? 0.0,
      buyDate: map['buy_date'] ?? DateTime.now().toIso8601String(),
      currency: map['currency'] ?? 'TRY',
      notes: map['notes'],
      createdAt: map['created_at'] ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'symbol': symbol,
      'type': type,
      'quantity': quantity,
      'buy_price': buyPrice,
      'buy_date': buyDate,
      'currency': currency,
      'notes': notes,
      'created_at': createdAt,
    };
  }

  Investment copyWith({
    int? id,
    String? name,
    String? symbol,
    String? type,
    double? quantity,
    double? buyPrice,
    String? buyDate,
    String? currency,
    String? notes,
    String? createdAt,
    double? currentPrice,
  }) {
    return Investment(
      id: id ?? this.id,
      name: name ?? this.name,
      symbol: symbol ?? this.symbol,
      type: type ?? this.type,
      quantity: quantity ?? this.quantity,
      buyPrice: buyPrice ?? this.buyPrice,
      buyDate: buyDate ?? this.buyDate,
      currency: currency ?? this.currency,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      currentPrice: currentPrice ?? this.currentPrice,
    );
  }
}
