mixin PriceFormatMixin {
  int get priceMinor;
  String get currencyCode;

  String get formattedPrice {
    final major = priceMinor ~/ 100;
    final cents = priceMinor % 100;
    final majorStr = major.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '$currencyCode $majorStr.${cents.toString().padLeft(2, '0')}';
  }
}
