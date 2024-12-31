import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:video_thumbnail_pro/src/image_format.dart';
import 'package:video_thumbnail_pro/src/video_thumbnail_method_channel.dart';

abstract class VideoThumbnailProPlatform extends PlatformInterface {
  /// Constructs a VideoThumbnailProPlatform.
  VideoThumbnailProPlatform() : super(token: _token);

  static final Object _token = Object();

  static VideoThumbnailProPlatform _instance = MethodChannelVideoThumbnail();

  /// The default instance of [VideoThumbnailProPlatform] to use.
  ///
  /// Defaults to [MethodChannelVideoThumbnail].
  static VideoThumbnailProPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [VideoThumbnailProPlatform] when
  /// they register themselves.
  static set instance(VideoThumbnailProPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<XFile> thumbnailFile({
    required String video,
    required Map<String, String>? headers,
    required String? thumbnailPath,
    required ImageFormat imageFormat,
    required int maxHeight,
    required int maxWidth,
    required int timeMs,
    required int quality,
  }) {
    throw UnimplementedError('thumbnailFile() has not been implemented.');
  }

  Future<Uint8List> thumbnailData({
    required String video,
    required Map<String, String>? headers,
    required ImageFormat imageFormat,
    required int maxHeight,
    required int maxWidth,
    required int timeMs,
    required int quality,
  }) {
    throw UnimplementedError('thumbnailData() has not been implemented.');
  }
}
