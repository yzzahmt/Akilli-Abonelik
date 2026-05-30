class CashAccount {
  final int? id;
  final String name; // e.g. "Ziraat Bankası", "Nakit", "Yastık Altı"
  final double amount;
  final String currency; // 'TRY', 'USD', 'EUR' vs.

  CashAccount({
    this.id,
    required this.name,
    required this.amount,
    this.currency = 'TRY',
  });

  factory CashAccount.fromMap(Map<String, dynamic> map) {
    return CashAccount(
      id: map['id'],
      name: map['name'],
      amount: (map['amount'] as num).toDouble(),
      currency: map['currency'] ?? 'TRY',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'amount': amount,
      'currency': currency,
    };
  }

  CashAccount copyWith({
    int? id,
    String? name,
    double? amount,
    String? currency,
  }) {
    return CashAccount(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
    );
  }
}
