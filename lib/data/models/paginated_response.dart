class PaginatedResponse<T> {
  final int currentPage;
  final int limit;
  final int start;
  final int end;
  final int totalRecords;
  final int totalPages;
  final int? nextPage;
  final int? previousPage;
  final List<T> data;

  PaginatedResponse({
    required this.currentPage,
    required this.limit,
    required this.start,
    required this.end,
    required this.totalRecords,
    required this.totalPages,
    this.nextPage,
    this.previousPage,
    required this.data,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return PaginatedResponse<T>(
      currentPage: json['currentPage'] ?? 1,
      limit: json['limit'] ?? 10,
      start: json['start'] ?? 1,
      end: json['end'] ?? 10,
      totalRecords: json['totalRecords'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      nextPage: json['nextPage'],
      previousPage: json['previousPage'],
      data: (json['data'] as List<dynamic>?)
              ?.map((item) => fromJsonT(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson(Map<String, dynamic> Function(T) toJsonT) {
    return {
      'currentPage': currentPage,
      'limit': limit,
      'start': start,
      'end': end,
      'totalRecords': totalRecords,
      'totalPages': totalPages,
      'nextPage': nextPage,
      'previousPage': previousPage,
      'data': data.map((item) => toJsonT(item)).toList(),
    };
  }

  bool get hasNextPage => nextPage != null && currentPage < totalPages;
  bool get hasPreviousPage => previousPage != null && currentPage > 1;
  bool get isLastPage => currentPage >= totalPages;
  bool get isFirstPage => currentPage <= 1;
}