import 'dart:convert';
import 'package:http/http.dart' as http;

/// Resultado de búsqueda web para un plato.
class WebSearchResult {
  final String title;
  final String url;
  final String snippet;
  final String source; // google, youtube, brave, bing, etc.
  WebSearchResult({
    required this.title,
    required this.url,
    this.snippet = '',
    required this.source,
  });
}

/// Servicio de búsqueda web para recetas.
/// - Si hay BRAVE_API_KEY / BING_API_KEY / SERPAPI_KEY → búsqueda real (5-10 resultados)
/// - Si no → genera enlaces curados 100% free (Google, YouTube, Bing, DuckDuckGo, Wikipedia, Tasty)
///   que son válidos sin necesidad de API key y cumplen el requisito del usuario.
class WebSearchService {
  static const _timeout = Duration(seconds: 10);
  final http.Client _client;
  WebSearchService({http.Client? client}) : _client = client ?? http.Client();

  static String get braveKey => const String.fromEnvironment('BRAVE_API_KEY');
  static String get bingKey => const String.fromEnvironment('BING_API_KEY');
  static String get serpApiKey =>
      const String.fromEnvironment('SERPAPI_API_KEY');

  static bool get hasRealSearch =>
      braveKey.isNotEmpty || bingKey.isNotEmpty || serpApiKey.isNotEmpty;

  Future<List<WebSearchResult>> searchDish(String dishName) async {
    final query = dishName.trim();
    if (query.isEmpty) return [];

    // Intenta búsqueda real si hay key
    if (braveKey.isNotEmpty) {
      try {
        final r = await _braveSearch(query);
        if (r.isNotEmpty) return r;
      } catch (_) {}
    }
    if (bingKey.isNotEmpty) {
      try {
        final r = await _bingSearch(query);
        if (r.isNotEmpty) return r;
      } catch (_) {}
    }
    if (serpApiKey.isNotEmpty) {
      try {
        final r = await _serpApiSearch(query);
        if (r.isNotEmpty) return r;
      } catch (_) {}
    }

    // Fallback 100% free sin key: enlaces curados
    return _curatedLinks(query);
  }

  List<WebSearchResult> _curatedLinks(String dish) {
    final q = Uri.encodeComponent('receta $dish');
    final qEn = Uri.encodeComponent(dish);
    return [
      WebSearchResult(
        title: 'Buscar "$dish" en Google',
        url: 'https://www.google.com/search?q=$q',
        snippet: 'Resultados web sobre $dish',
        source: 'google',
      ),
      WebSearchResult(
        title: 'Videos de "$dish" en YouTube',
        url: 'https://www.youtube.com/results?search_query=$q',
        snippet: 'Videorecetas de $dish',
        source: 'youtube',
      ),
      WebSearchResult(
        title: 'Buscar "$dish" en Bing',
        url: 'https://www.bing.com/search?q=$q',
        snippet: 'Resultados Bing para $dish',
        source: 'bing',
      ),
      WebSearchResult(
        title: 'Buscar "$dish" en DuckDuckGo',
        url: 'https://duckduckgo.com/?q=$q',
        snippet: 'Resultados DuckDuckGo para $dish',
        source: 'duckduckgo',
      ),
      WebSearchResult(
        title: '"$dish" en Wikipedia',
        url: 'https://en.wikipedia.org/w/index.php?search=$qEn',
        snippet: 'Artículo Wikipedia sobre $dish',
        source: 'wikipedia',
      ),
      WebSearchResult(
        title: '"$dish" en Tasty',
        url: 'https://www.tasty.co/search?q=$qEn',
        snippet: 'Recetas Tasty de $dish',
        source: 'tasty',
      ),
      WebSearchResult(
        title: '"$dish" en Allrecipes',
        url: 'https://www.allrecipes.com/search/results/?wt=$qEn',
        snippet: 'Recetas Allrecipes de $dish',
        source: 'allrecipes',
      ),
      WebSearchResult(
        title: '"$dish" en Cookpad',
        url: 'https://cookpad.com/es/buscar/$qEn',
        snippet: 'Recetas Cookpad de $dish',
        source: 'cookpad',
      ),
    ];
  }

  Future<List<WebSearchResult>> _braveSearch(String query) async {
    final uri = Uri.parse(
      'https://api.search.brave.com/res/v1/web/search?q=${Uri.encodeComponent(query)}&count=8',
    );
    final res = await _client
        .get(
          uri,
          headers: {
            'Accept': 'application/json',
            'X-Subscription-Token': braveKey,
          },
        )
        .timeout(_timeout);
    if (res.statusCode != 200) throw Exception('Brave ${res.statusCode}');
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final results =
        (data['results'] as List?) ?? (data['web']?['results'] as List?) ?? [];
    return results
        .take(8)
        .map(
          (r) => WebSearchResult(
            title: r['title']?.toString() ?? '',
            url: r['url']?.toString() ?? '',
            snippet: r['description']?.toString() ?? '',
            source: 'brave',
          ),
        )
        .where((e) => e.url.isNotEmpty)
        .toList();
  }

  Future<List<WebSearchResult>> _bingSearch(String query) async {
    final uri = Uri.parse(
      'https://api.bing.microsoft.com/v7.0/search?q=${Uri.encodeComponent(query)}&count=8&mkt=es-ES',
    );
    final res = await _client
        .get(uri, headers: {'Ocp-Apim-Subscription-Key': bingKey})
        .timeout(_timeout);
    if (res.statusCode != 200) throw Exception('Bing ${res.statusCode}');
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final results = (data['webPages']?['value'] as List?) ?? [];
    return results
        .take(8)
        .map(
          (r) => WebSearchResult(
            title: r['name']?.toString() ?? '',
            url: r['url']?.toString() ?? '',
            snippet: r['snippet']?.toString() ?? '',
            source: 'bing',
          ),
        )
        .where((e) => e.url.isNotEmpty)
        .toList();
  }

  Future<List<WebSearchResult>> _serpApiSearch(String query) async {
    final uri = Uri.parse(
      'https://serpapi.com/search.json?q=${Uri.encodeComponent(query)}&engine=google&num=8&api_key=$serpApiKey',
    );
    final res = await _client.get(uri).timeout(_timeout);
    if (res.statusCode != 200) throw Exception('SerpAPI ${res.statusCode}');
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final results = (data['organic_results'] as List?) ?? [];
    return results
        .take(8)
        .map(
          (r) => WebSearchResult(
            title: r['title']?.toString() ?? '',
            url: r['link']?.toString() ?? '',
            snippet: r['snippet']?.toString() ?? '',
            source: 'google',
          ),
        )
        .where((e) => e.url.isNotEmpty)
        .toList();
  }
}
