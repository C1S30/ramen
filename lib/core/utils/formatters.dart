import 'dart:math';

class Formatters {
  Formatters._();

  /// Converts bytes to human-readable string (KB, MB, GB)
  static String formatBytes(int? bytes) {
    if (bytes == null || bytes <= 0) return 'Unknown size';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    final i = (log(bytes) / log(1024)).floor();
    final clampedIndex = i.clamp(0, suffixes.length - 1);
    final size = bytes / pow(1024, clampedIndex);
    return '${size.toStringAsFixed(size >= 100 ? 0 : 1)} ${suffixes[clampedIndex]}';
  }

  /// Converts seconds to HH:MM:SS or MM:SS
  static String formatDuration(int? seconds) {
    if (seconds == null || seconds <= 0) return '--:--';
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final secs = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  /// Formats view count into compact string (e.g. 1.4M, 240K)
  static String formatCompactNumber(int? count) {
    if (count == null || count <= 0) return '0';
    if (count >= 1000000000) {
      return '${(count / 1000000000).toStringAsFixed(1)}B';
    }
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  /// Clean speed string representation
  static String formatSpeed(String? rawSpeed) {
    if (rawSpeed == null || rawSpeed.isEmpty) return '0.0 KB/s';
    return rawSpeed.trim();
  }

  static String formatReleaseTimestamp(int? epochSeconds) {
    if (epochSeconds == null || epochSeconds <= 0) return 'Scheduled';
    final dt = DateTime.fromMillisecondsSinceEpoch(
      epochSeconds * 1000,
      isUtc: true,
    ).toLocal();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = months[dt.month - 1];
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$month ${dt.day}, $hour:$minute';
  }

  static String errorCodeLabel(String? rawError) {
    if (rawError == null || rawError.trim().isEmpty) return 'ERR // ENGINE';
    final lower = rawError.toLowerCase();
    if (lower.contains('403') || lower.contains('forbidden')) {
      return 'ERR // HTTP_403';
    }
    if (lower.contains('cookies') ||
        lower.contains('login required') ||
        lower.contains('sign in') ||
        lower.contains('empty media response') ||
        lower.contains('age-restricted')) {
      return 'ERR // AUTH_REQUIRED';
    }
    if (lower.contains('private video') || lower.contains('members-only')) {
      return 'ERR // PRIVATE_MEDIA';
    }
    if (lower.contains('live event will begin') ||
        lower.contains('premieres in') ||
        lower.contains('not currently live')) {
      return 'ERR // LIVE_OFFLINE';
    }
    if (lower.contains('geo') ||
        lower.contains('not available in your country')) {
      return 'ERR // GEO_RESTRICTED';
    }
    if (lower.contains('unsupported url')) {
      return 'ERR // UNSUPPORTED_URL';
    }
    if (lower.contains('timed out') ||
        lower.contains('network') ||
        lower.contains('connection') ||
        lower.contains('unable to download webpage')) {
      return 'ERR // NETWORK_IO';
    }
    if (lower.contains('ffmpeg') || lower.contains('postprocessing')) {
      return 'ERR // FFMPEG_MUX';
    }
    return 'ERR // EXTRACTOR';
  }

  static String cleanErrorMessage(String? rawError) {
    if (rawError == null || rawError.trim().isEmpty) {
      return 'An unexpected media extraction error occurred.';
    }
    var text = rawError
        .replaceAll(RegExp(r'^Exception:\s*', caseSensitive: false), '')
        .replaceAll(
          RegExp(r'^PlatformException\([^)]*\):\s*', caseSensitive: false),
          '',
        )
        .trim();

    final errorMatch = RegExp(
      r'ERROR:\s*(?:\[[^\]]+\]\s*[^:]*:\s*)?(.+)',
      caseSensitive: false,
    ).firstMatch(text);
    if (errorMatch != null && errorMatch.group(1) != null) {
      text = errorMatch.group(1)!.trim();
    }

    final lower = text.toLowerCase();
    if (lower.contains('empty media response') ||
        lower.contains('login required') ||
        lower.contains('sign in to confirm')) {
      return 'Authentication required by host. Import a Netscape cookies.txt file or sync WebView cookies in Settings.';
    }
    if (lower.contains('http error 403') || lower.contains('403: forbidden')) {
      return 'Access denied (HTTP 403 Forbidden). Try syncing WebView cookies or enabling IPv4 in Settings.';
    }
    if (lower.contains('private video')) {
      return 'This media is private. Authenticate with valid account cookies in Settings to access it.';
    }
    if (lower.contains('live event will begin') ||
        lower.contains('premieres in')) {
      return 'Broadcast has not started yet. Enable Wait for Broadcast in Live Stream Settings to poll automatically.';
    }
    if (lower.contains('not available in your country')) {
      return 'Media is geo-restricted in your region. Enable Geo-Bypass or configure a proxy in Settings.';
    }
    if (lower.contains('unsupported url')) {
      return 'URL is not supported by yt-dlp or does not contain extractable media.';
    }

    text = text.split('\n').firstWhere(
      (l) => l.trim().isNotEmpty && !l.trim().startsWith('WARNING:'),
      orElse: () => text,
    );
    if (text.length > 180) {
      return '${text.substring(0, 177)}...';
    }
    return text;
  }
}
