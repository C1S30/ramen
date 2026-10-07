enum UrlType {
  youtubeVideo,
  youtubePlaylist,
  youtubeShorts,
  genericMedia,
  searchQuery,
  invalid,
}

class UrlValidator {
  UrlValidator._();

  static final RegExp _youtubeUrlRegex = RegExp(
    r'^(https?:\/\/)?(www\.)?(youtube\.com|youtu\.be)\/.+$',
    caseSensitive: false,
  );

  static final RegExp _playlistRegex = RegExp(
    r'[?&]list=([a-zA-Z0-9_-]+)',
    caseSensitive: false,
  );

  static final RegExp _shortsRegex = RegExp(
    r'youtube\.com\/shorts\/([a-zA-Z0-9_-]+)',
    caseSensitive: false,
  );

  static final RegExp _generalHttpRegex = RegExp(
    r'^https?:\/\/[^\s$.?#].[^\s]*$',
    caseSensitive: false,
  );

  static final RegExp _searchPrefixRegex = RegExp(
    r'^[a-z]+search\d*:',
    caseSensitive: false,
  );

  /// Analyzes the string and determines the media or search query type
  static UrlType categorize(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return UrlType.invalid;

    // Check for explicit yt-dlp search prefix like ytsearch: or ytsearch10:
    if (_searchPrefixRegex.hasMatch(trimmed)) {
      return UrlType.searchQuery;
    }

    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      // Allow pasting URLs without schema (e.g. youtube.com/watch?v=... or domain.com/video)
      if (_youtubeUrlRegex.hasMatch('https://$trimmed')) {
        return _categorizeYoutube('https://$trimmed');
      }
      if (trimmed.contains('.') &&
          !trimmed.contains(' ') &&
          _generalHttpRegex.hasMatch('https://$trimmed')) {
        return UrlType.genericMedia;
      }
      // If not a URL structure, treat as search query
      return UrlType.searchQuery;
    }

    if (_youtubeUrlRegex.hasMatch(trimmed)) {
      return _categorizeYoutube(trimmed);
    }

    if (_generalHttpRegex.hasMatch(trimmed)) {
      return UrlType.genericMedia;
    }

    return UrlType.searchQuery;
  }

  static UrlType _categorizeYoutube(String url) {
    if (_shortsRegex.hasMatch(url)) {
      return UrlType.youtubeShorts;
    }
    if (_playlistRegex.hasMatch(url)) {
      return UrlType.youtubePlaylist;
    }
    return UrlType.youtubeVideo;
  }

  static bool isYoutube(String url) {
    final type = categorize(url);
    return type == UrlType.youtubeVideo ||
        type == UrlType.youtubePlaylist ||
        type == UrlType.youtubeShorts;
  }

  static bool isPlaylist(String url) {
    return categorize(url) == UrlType.youtubePlaylist;
  }

  static bool isSearchQuery(String input) {
    return categorize(input) == UrlType.searchQuery;
  }

  static bool isValidMediaUrl(String url) {
    final type = categorize(url);
    return type != UrlType.invalid && type != UrlType.searchQuery;
  }

  static bool isValidInput(String input) {
    return categorize(input) != UrlType.invalid;
  }
}
