class Subscription {
  final int? id;
  final String name;
  final String emoji;
  final String category;
  final double priceInTL;
  final bool isUsdBased;
  final double usdAmount;
  final int renewalDay;
  final int notifyDaysBefore;
  final bool isActive;
  final int isFavorite;
  final String createdAt;

  final String _billingCycle;
  final int cycleDays;
  final String _currency;
  final double originalPrice;

  Subscription({
    this.id,
    required this.name,
    required this.emoji,
    required this.category,
    required this.priceInTL,
    this.isUsdBased = false,
    required this.usdAmount,
    required this.renewalDay,
    this.notifyDaysBefore = 2,
    this.isActive = true,
    this.isFavorite = 0,
    required this.createdAt,
    String billingCycle = 'Aylık',
    this.cycleDays = 30,
    String currency = 'TRY',
    this.originalPrice = 0.0,
  })  : _billingCycle = billingCycle,
        _currency = currency;

  // Calculate next renewal date from the original renewal date
  DateTime get nextRenewalDate {
    final now = DateTime.now();
    DateTime firstDate;
    try {
      firstDate = DateTime.parse(createdAt);
    } catch (_) {
      firstDate = DateTime(now.year, now.month, renewalDay);
    }
    
    // SubsTrack yeni özellik — periyot bazlı tarih hesaplama (Bölüm 8)
    DateTime nextDate = firstDate;
    while (nextDate.isBefore(now)) {
      if (_billingCycle == 'Haftalık') {
        nextDate = nextDate.add(const Duration(days: 7));
      } else if (_billingCycle == '2 Haftada Bir') {
        nextDate = nextDate.add(const Duration(days: 14));
      } else if (_billingCycle == 'Aylık') {
        nextDate = DateTime(nextDate.year, nextDate.month + 1, renewalDay);
      } else if (_billingCycle == '3 Aylık') {
        nextDate = DateTime(nextDate.year, nextDate.month + 3, renewalDay);
      } else if (_billingCycle == '6 Aylık') {
        nextDate = DateTime(nextDate.year, nextDate.month + 6, renewalDay);
      } else if (_billingCycle == 'Yıllık') {
        nextDate = DateTime(nextDate.year + 1, nextDate.month, renewalDay);
      } else if (_billingCycle == 'Özel') {
        nextDate = nextDate.add(Duration(days: cycleDays));
      } else {
        nextDate = DateTime(nextDate.year, nextDate.month + 1, renewalDay);
      }
    }
    return nextDate;
  }

  bool get isRenewingSoon {
    final now = DateTime.now();
    final renewal = nextRenewalDate;
    final diff = renewal.difference(DateTime(now.year, now.month, now.day)).inDays;
    return diff >= 0 && diff <= notifyDaysBefore;
  }

  // price alias for backward compatibility or use original_price if available
  double get price => originalPrice > 0 ? originalPrice : (isUsdBased ? usdAmount : priceInTL);

  // currency getter
  String get currency => _currency.isNotEmpty && _currency != 'TRY' ? _currency : (isUsdBased ? 'USD' : 'TRY');

  // billingCycle getter
  String get billingCycle => _billingCycle.isNotEmpty ? _billingCycle : 'Aylık';

  // firstRenewalDate alias
  DateTime get firstRenewalDate => nextRenewalDate;

  // reminderDaysBefore alias
  int get reminderDaysBefore => notifyDaysBefore;

  // iconKey alias
  String get iconKey => name.toLowerCase();

  // notes alias
  String? get notes => null;

  factory Subscription.fromMap(Map<String, dynamic> map) {
    return Subscription(
      id: map['id'],
      name: map['name'],
      emoji: map['emoji'] ?? '➕',
      category: map['category'] ?? 'Diğer',
      priceInTL: (map['priceInTL'] as num?)?.toDouble() ?? 0.0,
      isUsdBased: (map['isUsdBased'] == 1 || map['isUsdBased'] == true),
      usdAmount: (map['usdAmount'] as num?)?.toDouble() ?? 0.0,
      renewalDay: map['renewalDay'] ?? 15,
      notifyDaysBefore: map['notifyDaysBefore'] ?? 2,
      isActive: (map['isActive'] == 1 || map['isActive'] == true),
      isFavorite: map['is_favorite'] ?? map['isFavorite'] ?? 0,
      createdAt: map['createdAt'] ?? DateTime.now().toIso8601String(),
      billingCycle: map['billingCycle'] ?? 'Aylık',
      cycleDays: map['cycleDays'] ?? 30,
      currency: map['currency'] ?? 'TRY',
      originalPrice: (map['originalPrice'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'emoji': emoji,
      'category': category,
      'priceInTL': priceInTL,
      'isUsdBased': isUsdBased ? 1 : 0,
      'usdAmount': usdAmount,
      'renewalDay': renewalDay,
      'notifyDaysBefore': notifyDaysBefore,
      'isActive': isActive ? 1 : 0,
      'is_favorite': isFavorite,
      'createdAt': createdAt,
      'billingCycle': _billingCycle,
      'cycleDays': cycleDays,
      'currency': _currency,
      'originalPrice': originalPrice,
    };
  }

  Subscription copyWith({
    int? id,
    String? name,
    String? emoji,
    String? category,
    double? priceInTL,
    bool? isUsdBased,
    double? usdAmount,
    int? renewalDay,
    int? notifyDaysBefore,
    bool? isActive,
    int? isFavorite,
    String? createdAt,
    String? billingCycle,
    int? cycleDays,
    String? currency,
    double? originalPrice,
  }) {
    return Subscription(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      category: category ?? this.category,
      priceInTL: priceInTL ?? this.priceInTL,
      isUsdBased: isUsdBased ?? this.isUsdBased,
      usdAmount: usdAmount ?? this.usdAmount,
      renewalDay: renewalDay ?? this.renewalDay,
      notifyDaysBefore: notifyDaysBefore ?? this.notifyDaysBefore,
      isActive: isActive ?? this.isActive,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      billingCycle: billingCycle ?? _billingCycle,
      cycleDays: cycleDays ?? this.cycleDays,
      currency: currency ?? _currency,
      originalPrice: originalPrice ?? this.originalPrice,
    );
  }
}
