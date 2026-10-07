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

    test('Identifies generic media, search queries, and invalid inputs', () {
      expect(
        UrlValidator.categorize('https://vimeo.com/12345678'),
        UrlType.genericMedia,
      );
      expect(
        UrlValidator.categorize('ytsearch10:lofi beats'),
        UrlType.searchQuery,
      );
      expect(
        UrlValidator.categorize('coldplay viva la vida'),
        UrlType.searchQuery,
      );
      expect(UrlValidator.categorize('   '), UrlType.invalid);
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

    test('Synthesizes video-only format with audio pairing', () {
      final template = CommandTemplate(
        id: 'test',
        name: 'Test',
        description: 'Test template',
        flags: [],
      );

      final format = FormatItem(
        formatId: '137',
        ext: 'mp4',
        resolution: '1080p',
        isVideoOnly: true,
      );

      final args = engine.buildDownloadArgs(
        template: template,
        selectedFormat: format,
        isAudioOnly: false,
      );

      expect(args.contains('-f'), isTrue);
      expect(args.contains('137+bestaudio/best'), isTrue);
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

  group('Format Table Parser Tests', () {
    test('Parses yt-dlp -F table output correctly', () {
      const sampleTable = '''
[youtube] Extracting URL: https://www.youtube.com/watch?v=dQw4w9WgXcQ
[info] Available formats for dQw4w9WgXcQ:
ID  EXT   RESOLUTION FPS CH |   FILESIZE    TBR PROTO | VCODEC           VBR ACODEC      ABR ASR MORE INFO
-----------------------------------------------------------------------------------------------------------------------
sb3 mhtml 48x27        0    |                   mhtml | images                                   storyboard
139 m4a   audio only      2 |    1.24MiB    49k https | audio only           mp4a.40.5   49k 22k [en] low, m4a_dash
140 m4a   audio only      2 |    3.29MiB   130k https | audio only           mp4a.40.2  130k 44k [en] medium, m4a_dash
249 webm  audio only      2 |    1.17MiB    46k https | audio only           opus        46k 48k [en] low, webm_dash
160 mp4   256x144     25    |    1.96MiB    77k https | avc1.4d400c      77k video only          144p, mp4_dash
137 mp4   1920x1080   25    |   77.16MiB  3038k https | avc1.640028    3038k video only          1080p, mp4_dash
''';

      final res = MediaResource.parseOutput(
        sampleTable,
        'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      );

      expect(res.id, 'dQw4w9WgXcQ');
      expect(res.formats.length, 5); // sb3 ignored

      final f140 = res.formats.firstWhere((f) => f.formatId == '140');
      expect(f140.isAudioOnly, isTrue);
      expect(f140.ext, 'm4a');
      expect(f140.tbr, 130.0);
      expect(f140.filesize, isNotNull);

      final f137 = res.formats.firstWhere((f) => f.formatId == '137');
      expect(f137.isVideoOnly, isTrue);
      expect(f137.height, 1080);
      expect(f137.resolution, '1080p');
      expect(f137.fps, 25);
      expect(f137.filesize, isNotNull);
    });
  });
}

