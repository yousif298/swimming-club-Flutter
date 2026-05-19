class PoolModel {
  final String id;
  final String name;
  final int totalLanes;

  PoolModel({required this.id, required this.name, required this.totalLanes});

  factory PoolModel.fromJson(Map<String, dynamic> json) => PoolModel(
        id: json['id'] as String,
        name: json['name'] as String,
        totalLanes: json['totalLanes'] as int,
      );
}

class LaneModel {
  final String id;
  final int laneNumber;
  final String poolId;

  LaneModel({required this.id, required this.laneNumber, required this.poolId});

  factory LaneModel.fromJson(Map<String, dynamic> json) => LaneModel(
        id: json['id'] as String,
        laneNumber: json['laneNumber'] as int,
        poolId: json['poolId'] as String,
      );
}
