import '../utils/date_util.dart';

class Category {
  final int id;
  final String name;
  final String? icon;
  final int sort;
  final int status;
  final DateTime? createTime;
  final DateTime? updateTime;

  Category({
    required this.id,
    required this.name,
    this.icon,
    this.sort = 0,
    this.status = 1,
    this.createTime,
    this.updateTime,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int,
      name: json['name'] as String,
      icon: json['icon'] as String?,
      sort: json['sort'] as int? ?? 0,
      status: json['status'] as int? ?? 1,
      createTime: DateUtil.parseAsLocalDateTime(json['createTime']),
      updateTime: DateUtil.parseAsLocalDateTime(json['updateTime']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'sort': sort,
      'status': status,
      'createTime': createTime?.toIso8601String(),
      'updateTime': updateTime?.toIso8601String(),
    };
  }
}
