class BookingTypeModel {
  final String id;
  final String name;
  final String? description;
  final double defaultPrice;
  final bool hasCapacity;
  final int? capacity;
  final bool hasSchedule;
  final bool isActive;

  BookingTypeModel({
    required this.id,
    required this.name,
    this.description,
    required this.defaultPrice,
    required this.hasCapacity,
    this.capacity,
    required this.hasSchedule,
    required this.isActive,
  });

  factory BookingTypeModel.fromJson(Map<String, dynamic> json) => BookingTypeModel(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        defaultPrice: (json['defaultPrice'] as num).toDouble(),
        hasCapacity: json['hasCapacity'] as bool,
        capacity: json['capacity'] as int?,
        hasSchedule: json['hasSchedule'] as bool,
        isActive: json['isActive'] as bool,
      );
}
