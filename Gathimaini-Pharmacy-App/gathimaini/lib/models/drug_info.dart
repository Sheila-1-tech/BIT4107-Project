class DrugInfo {
  final String name;
  final String purpose;
  final String manufacturer;
  final String warnings;
  final String usage;

  DrugInfo({
    required this.name,
    required this.purpose,
    required this.manufacturer,
    required this.warnings,
    required this.usage,
  });

  factory DrugInfo.fromJson(Map<String, dynamic> json) {
    final openFda = json['openfda'] ?? {};
    return DrugInfo(
      name: (openFda['brand_name'] as List?)?.first ?? 'Unknown Name',
      manufacturer:
          (openFda['manufacturer_name'] as List?)?.first ??
          'Unknown Manufacturer',
      purpose: (json['purpose'] as List?)?.first ?? 'Purpose not provided.',
      warnings: (json['warnings'] as List?)?.first ?? 'No warnings provided.',
      usage:
          (json['indications_and_usage'] as List?)?.first ??
          'Usage information unavailable.',
    );
  }
}
