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
  final String createdAt;

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
    required this.createdAt,
  });

  // Calculate next renewal date from the original renewal date
  DateTime get nextRenewalDate {
    final now = DateTime.now();
    DateTime renewalDate = DateTime(now.year, now.month, renewalDay);
    if (renewalDate.isBefore(now)) {
      renewalDate = DateTime(now.year, now.month + 1, renewalDay);
    }
    return renewalDate;
  }

  bool get isRenewingSoon {
    final now = DateTime.now();
    final renewal = nextRenewalDate;
    final diff = renewal.difference(DateTime(now.year, now.month, now.day)).inDays;
    return diff >= 0 && diff <= notifyDaysBefore;
  }

  // price alias for backward compatibility
  double get price => isUsdBased ? usdAmount : priceInTL;

  // currency alias for backward compatibility
  String get currency => isUsdBased ? 'USD' : 'TRY';

  // billingCycle alias for backward compatibility
  String get billingCycle => 'Aylık';

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
      createdAt: map['createdAt'] ?? DateTime.now().toIso8601String(),
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
      'createdAt': createdAt,
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
    String? createdAt,
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
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
