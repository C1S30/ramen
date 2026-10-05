enum UrlType {
  youtubeVideo,
  youtubePlaylist,
  youtubeShorts,
  genericMedia,
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

  /// Analyzes the string and determines the media type
  static UrlType categorize(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return UrlType.invalid;

    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      // Allow user pasting without schema
      if (_youtubeUrlRegex.hasMatch('https://$trimmed')) {
        return _categorizeYoutube('https://$trimmed');
      }
      return UrlType.invalid;
    }

    if (_youtubeUrlRegex.hasMatch(trimmed)) {
      return _categorizeYoutube(trimmed);
    }

    if (_generalHttpRegex.hasMatch(trimmed)) {
      return UrlType.genericMedia;
    }

    return UrlType.invalid;
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

  static bool isValidMediaUrl(String url) {
    final type = categorize(url);
    return type != UrlType.invalid;
  }
}
