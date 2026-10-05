import 'package:flutter_test/flutter_test.dart';
import 'package:ramen/core/utils/formatters.dart';
import 'package:ramen/core/utils/url_validator.dart';
import 'package:ramen/models/command_template.dart';
import 'package:ramen/models/media_resource.dart';
import 'package:ramen/services/template_engine_service.dart';

void main() {
  group('UrlValidator Tests', () {
    test('Identifies standard YouTube video URLs', () {
      expect(
        UrlValidator.categorize('https://www.youtube.com/watch?v=dQw4w9WgXcQ'),
        UrlType.youtubeVideo,
      );
      expect(
        UrlValidator.categorize('https://youtu.be/dQw4w9WgXcQ'),
        UrlType.youtubeVideo,
      );
    });

    test('Identifies YouTube playlist URLs', () {
      expect(
        UrlValidator.categorize(
          'https://www.youtube.com/playlist?list=PL_test_12345',
        ),
        UrlType.youtubePlaylist,
      );
    });

    test('Identifies YouTube Shorts URLs', () {
      expect(
        UrlValidator.categorize('https://www.youtube.com/shorts/abcd1234efg'),
        UrlType.youtubeShorts,
      );
    });

    test('Identifies generic media and invalid URLs', () {
      expect(
        UrlValidator.categorize('https://vimeo.com/12345678'),
        UrlType.genericMedia,
      );
      expect(UrlValidator.categorize('not-a-valid-url'), UrlType.invalid);
    });
  });

  group('Formatters Tests', () {
    test('formatBytes properly converts byte sizes', () {
      expect(Formatters.formatBytes(500), '500 B');
      expect(Formatters.formatBytes(1048576), '1.0 MB');
      expect(Formatters.formatBytes(1073741824), '1.0 GB');
      expect(Formatters.formatBytes(null), 'Unknown size');
    });

    test('formatDuration formats seconds properly', () {
      expect(Formatters.formatDuration(45), '00:45');
      expect(Formatters.formatDuration(222), '03:42');
      expect(Formatters.formatDuration(3665), '01:01:05');
      expect(Formatters.formatDuration(null), '--:--');
    });

    test('formatCompactNumber formats view counts', () {
      expect(Formatters.formatCompactNumber(450), '450');
      expect(Formatters.formatCompactNumber(15400), '15.4K');
      expect(Formatters.formatCompactNumber(3200000), '3.2M');
      expect(Formatters.formatCompactNumber(1200000000), '1.2B');
    });
  });

  group('TemplateEngineService Tests', () {
    final engine = TemplateEngineService();

    test('Tokenizes raw shell strings into argument lists', () {
      final tokens = engine.parseFlagsFromString(
        '-N 16 --downloader aria2c --limit-rate "5 MB/s"',
      );
      expect(tokens, ['-N', '16', '--downloader', 'aria2c', '--limit-rate', '5 MB/s']);
    });

    test('Synthesizes download arguments for video muxing', () {
      final template = CommandTemplate(
        id: 'test',
        name: 'Test',
        description: 'Test template',
        flags: ['-N', '8'],
      );

      final format = FormatItem(
        formatId: '137+140',
        ext: 'mp4',
        resolution: '1080p',
      );

      final args = engine.buildDownloadArgs(
        template: template,
        selectedFormat: format,
        isAudioOnly: false,
        preferredVideoContainer: 'mp4',
      );

      expect(args.contains('-N'), isTrue);
      expect(args.contains('137+140'), isTrue);
      expect(args.contains('--merge-output-format'), isTrue);
    });

    test('Synthesizes audio extraction arguments', () {
      final template = CommandTemplate(
        id: 'test',
        name: 'Test',
        description: 'Test template',
        flags: [],
      );

      final format = FormatItem(
        formatId: '140',
        ext: 'm4a',
        isAudioOnly: true,
      );

      final args = engine.buildDownloadArgs(
        template: template,
        selectedFormat: format,
        isAudioOnly: true,
        preferredAudioFormat: 'flac',
      );

      expect(args.contains('-x'), isTrue);
      expect(args.contains('--audio-format'), isTrue);
      expect(args.contains('flac'), isTrue);
    });
  });
}
