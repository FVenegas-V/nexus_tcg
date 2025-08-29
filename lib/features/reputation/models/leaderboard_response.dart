import 'leaderboard_entry.dart';

/// Respuesta del endpoint de leaderboard con paginación
class LeaderboardResponse {
  final List<LeaderboardEntry> results;
  final int count;
  final String? next;
  final String? previous;
  final int totalPages;
  final int currentPage;
  final int pageSize;

  const LeaderboardResponse({
    required this.results,
    required this.count,
    this.next,
    this.previous,
    required this.totalPages,
    required this.currentPage,
    required this.pageSize,
  });

  factory LeaderboardResponse.fromJson(Map<String, dynamic> json) {
    return LeaderboardResponse(
      results: (json['results'] as List<dynamic>)
          .map(
            (item) => LeaderboardEntry.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      count: json['count'] as int,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      totalPages: json['total_pages'] as int,
      currentPage: json['current_page'] as int,
      pageSize: json['page_size'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'results': results.map((entry) => entry.toJson()).toList(),
      'count': count,
      'next': next,
      'previous': previous,
      'total_pages': totalPages,
      'current_page': currentPage,
      'page_size': pageSize,
    };
  }

  /// Verifica si hay más páginas disponibles
  bool get hasNext => next != null;

  /// Verifica si hay páginas anteriores disponibles
  bool get hasPrevious => previous != null;

  /// Verifica si es la primera página
  bool get isFirstPage => currentPage == 1;

  /// Verifica si es la última página
  bool get isLastPage => currentPage == totalPages;

  @override
  String toString() {
    return 'LeaderboardResponse(results: ${results.length} entries, '
        'page: $currentPage/$totalPages, count: $count)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LeaderboardResponse &&
        other.results == results &&
        other.count == count &&
        other.next == next &&
        other.previous == previous &&
        other.totalPages == totalPages &&
        other.currentPage == currentPage &&
        other.pageSize == pageSize;
  }

  @override
  int get hashCode {
    return Object.hash(
      results,
      count,
      next,
      previous,
      totalPages,
      currentPage,
      pageSize,
    );
  }
}
