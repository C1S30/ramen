import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ramen/models/download_task.dart';
import 'package:ramen/views/downloads/widgets/active_task_card.dart';

void main() {
  testWidgets('ActiveTaskCard renders progress and speed metrics',
      (WidgetTester tester) async {
    final task = DownloadTask(
      id: 'test_123',
      url: 'https://youtube.com/watch?v=123',
      title: 'Cyberpunk Edgerunners OST',
      uploader: 'Studio Trigger',
      selectedFormatId: '137+140',
      extension: 'mp4',
      progress: 68.4,
      speed: '14.8 MB/s',
      eta: '00:12',
      status: DownloadStatus.downloading,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ActiveTaskCard(
            task: task,
            onPause: () {},
            onResume: () {},
            onCancel: () {},
          ),
        ),
      ),
    );

    // Verify Title and Metrics
    expect(find.text('Cyberpunk Edgerunners OST'), findsOneWidget);
    expect(find.text('Studio Trigger'), findsOneWidget);
    expect(find.text('68.4%'), findsOneWidget);
    expect(find.text('14.8 MB/s'), findsOneWidget);
    expect(find.text('ETA: 00:12'), findsOneWidget);
    expect(find.text('Pause'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });
}
