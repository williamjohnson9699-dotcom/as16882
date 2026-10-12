import '../utils/date_util.dart';

class Shop {
  final int id;
  final String name;
  final String? logo;
  final int level;
  final double rating;
  final int followCount;
  final int views;
  final double creditScore;
  final int userId;
  final int status;
  final bool? isFollowed;
  final DateTime? createTime;
  final DateTime? updateTime;

  Shop({
    required this.id,
    required this.name,
    this.logo,
    this.level = 1,
    this.rating = 5.0,
    this.followCount = 0,
    this.views = 0,
    this.creditScore = 100.0,
    required this.userId,
    this.status = 1,
    this.isFollowed,
    this.createTime,
    this.updateTime,
  });

  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      id: json['id'] as int,
      name: json['name'] as String,
      logo: json['logo'] as String?,
      level: json['level'] as int? ?? 1,
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      followCount: json['followCount'] as int? ?? 0,
      views: json['views'] as int? ?? 0,
      creditScore: (json['creditScore'] as num?)?.toDouble() ?? 100.0,
      userId: json['userId'] as int,
      status: json['status'] as int? ?? 1,
      isFollowed: json['isFollowed'] as bool?,
      createTime: DateUtil.parseAsLocalDateTime(json['createTime']),
      updateTime: DateUtil.parseAsLocalDateTime(json['updateTime']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'logo': logo,
      'level': level,
      'rating': rating,
      'followCount': followCount,
      'views': views,
      'creditScore': creditScore,
      'userId': userId,
      'status': status,
      'isFollowed': isFollowed,
      'createTime': createTime?.toIso8601String(),
      'updateTime': updateTime?.toIso8601String(),
    };
  }
}
