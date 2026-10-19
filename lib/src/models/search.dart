/// A single hit returned by `POST /v1/tools/search`.
class SearchResult {
  /// Creates a search result.
  const SearchResult({
    required this.title,
    required this.url,
    this.snippet = '',
    this.summary = '',
    this.content = '',
    this.rerankScore,
    this.siteName,
    this.siteIcon,
    this.date,
    this.authority,
  });

  /// Parses a search result JSON object.
  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      title: json['title'] as String? ?? '',
      url: json['url'] as String? ?? '',
      snippet: json['snippet'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      content: json['content'] as String? ?? '',
      rerankScore: (json['rerank_score'] as num?)?.toDouble(),
      siteName: json['site_name'] as String?,
      siteIcon: json['site_icon'] as String?,
      date: json['date'] as String?,
      authority: (json['authority'] as num?)?.toInt(),
    );
  }

  /// Page title.
  final String title;

  /// Page URL.
  final String url;

  /// Short excerpt matching the query.
  final String snippet;

  /// Generated summary of the page.
  final String summary;

  /// Page content. Empty unless the search was made with `needContent: true`.
  final String content;

  /// Relevance score assigned by the reranker.
  final double? rerankScore;

  /// Name of the site, when known.
  final String? siteName;

  /// Favicon URL, when known.
  final String? siteIcon;

  /// Publication date as an ISO 8601 string, when known.
  final String? date;

  /// Source authority rating.
  final int? authority;
}

/// Response of `POST /v1/tools/search`.
class SearchResponse {
  /// Creates a search response.
  const SearchResponse({required this.results});

  /// Parses the search response JSON.
  factory SearchResponse.fromJson(Map<String, dynamic> json) {
    final results = json['results'] as List<dynamic>? ?? [];
    return SearchResponse(
      results: results
          .map((r) => SearchResult.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Results, most relevant first.
  final List<SearchResult> results;
}

/// Response of `POST /v1/tools/fetch`.
class FetchResponse {
  /// Creates a fetch response.
  const FetchResponse({required this.title, required this.content});

  /// Parses the fetch response JSON.
  factory FetchResponse.fromJson(Map<String, dynamic> json) {
    return FetchResponse(
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
    );
  }

  /// Page title.
  final String title;

  /// Page content as Markdown.
  final String content;
}
