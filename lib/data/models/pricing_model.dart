class PricingModel {
  final String id;
  final int? minParticipants;
  final int? maxParticipants;
  final double price;
  final String pricingType;

  PricingModel({
    required this.id,
    this.minParticipants,
    this.maxParticipants,
    required this.price,
    required this.pricingType,
  });

  factory PricingModel.fromJson(Map<String, dynamic> json) => PricingModel(
        id: json['id'] as String,
        minParticipants: json['minParticipants'] as int?,
        maxParticipants: json['maxParticipants'] as int?,
        price: (json['price'] as num).toDouble(),
        pricingType: json['pricingType'] as String,
      );
}

class ActivityModel {
  final String id;
  final String name;
  final String? description;

  ActivityModel({required this.id, required this.name, this.description});

  factory ActivityModel.fromJson(Map<String, dynamic> json) => ActivityModel(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
      );
}
