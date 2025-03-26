class Currency {
  final String id;
  final String country;
  final String currency;
  final String currencyName;

  Currency({
    required this.id,
    required this.country,
    required this.currency,
    required this.currencyName,
  });

  factory Currency.fromJson(Map<String, dynamic> json) {
    return Currency(
      id: json['id'] as String,
      country: json['country'] as String,
      currency: json['currency'] as String,
      currencyName: json['currency_name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'country': country,
      'currency': currency,
      'currency_name': currencyName,
    };
  }
}
