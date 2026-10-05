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
}
