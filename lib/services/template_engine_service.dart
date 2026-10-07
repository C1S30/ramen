import '../models/command_template.dart';
import '../models/media_resource.dart';

class TemplateEngineService {
  /// Builds final arguments list to pass to yt-dlp execution
  List<String> buildDownloadArgs({
    required CommandTemplate template,
    required FormatItem selectedFormat,
    required bool isAudioOnly,
    String? preferredAudioFormat, // e.g. flac, mp3, m4a
    String? preferredVideoContainer, // e.g. mp4, mkv
    List<String> userCustomFlags = const [],
  }) {
    final List<String> args = [];

    // 1. Add template base flags
    args.addAll(template.flags);

    // 2. Format selector flags if not overridden by user
    if (!args.contains('-f') && !args.contains('--format')) {
      if (isAudioOnly) {
        args.addAll(['-f', 'bestaudio/best']);
        args.add('-x');
        if (preferredAudioFormat != null && preferredAudioFormat.isNotEmpty) {
          args.addAll(['--audio-format', preferredAudioFormat]);
        }
      } else {
        if (selectedFormat.formatId.isNotEmpty &&
            selectedFormat.formatId != 'best') {
          if (selectedFormat.isVideoOnly) {
            args.addAll(['-f', '${selectedFormat.formatId}+bestaudio/best']);
          } else {
            args.addAll(['-f', selectedFormat.formatId]);
          }
        } else {
          args.addAll(['-f', 'bestvideo+bestaudio/best']);
        }

        if (preferredVideoContainer != null &&
            preferredVideoContainer.isNotEmpty &&
            !args.contains('--merge-output-format')) {
          args.addAll(['--merge-output-format', preferredVideoContainer]);
        }
      }
    }

    // 3. User ad-hoc custom flags
    for (final flag in userCustomFlags) {
      if (flag.trim().isNotEmpty && !args.contains(flag.trim())) {
        args.add(flag.trim());
      }
    }

    return args;
  }

  /// Tokenizes a raw shell string into an arguments list
  List<String> parseFlagsFromString(String rawInput) {
    if (rawInput.trim().isEmpty) return [];

    final List<String> result = [];
    final StringBuffer currentToken = StringBuffer();
    bool insideQuotes = false;
    String quoteChar = '';

    for (int i = 0; i < rawInput.length; i++) {
      final char = rawInput[i];

      if ((char == '"' || char == "'") && (!insideQuotes || char == quoteChar)) {
        insideQuotes = !insideQuotes;
        quoteChar = insideQuotes ? char : '';
        continue;
      }

      if (char == ' ' && !insideQuotes) {
        if (currentToken.isNotEmpty) {
          result.add(currentToken.toString());
          currentToken.clear();
        }
      } else {
        currentToken.write(char);
      }
    }

    if (currentToken.isNotEmpty) {
      result.add(currentToken.toString());
    }

    return result;
  }

  /// Formats flags list into a single clean CLI display command
  String formatCommandLine(String url, List<String> args) {
    final buffer = StringBuffer('yt-dlp ');
    for (final arg in args) {
      if (arg.contains(' ')) {
        buffer.write('"$arg" ');
      } else {
        buffer.write('$arg ');
      }
    }
    buffer.write('"$url"');
    return buffer.toString().trim();
  }
}
