class PageData<T> {
  final List<T> records;
  final int total;
  final int size;
  final int current;
  final int pages;

  PageData({
    required this.records,
    required this.total,
    required this.size,
    required this.current,
    required this.pages,
  });

  factory PageData.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromJsonT,
  ) {
    return PageData<T>(
      records: (json['records'] as List)
          .map((item) => fromJsonT(item))
          .toList(),
      total: json['total'] as int,
      size: json['size'] as int,
      current: json['current'] as int,
      pages: json['pages'] as int,
    );
  }
}
