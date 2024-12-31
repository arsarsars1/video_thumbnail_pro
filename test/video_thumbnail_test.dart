import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_thumbnail_pro/src/image_format.dart';
import 'package:video_thumbnail_pro/video_thumbnail_pro.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('video_thumbnail_pro');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      final m = methodCall.method;
      final a = Map<String, dynamic>.from(methodCall.arguments as Map);

      return '$m=${a["video"]}:${a["path"]}:${a["format"]}:${a["maxh"]}:${a["quality"]}';
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('thumbnailData', () async {
    final XFile result = await VideoThumbnailPro.thumbnailFile(
      video: 'video',
      thumbnailPath: 'path',
      imageFormat: ImageFormat.JPEG,
      maxWidth: 123,
      maxHeight: 123,
      quality: 45,
    );

    expect(result.path, 'file=video:path:0:123:45');
  });
}
