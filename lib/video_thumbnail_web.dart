import 'dart:async';
import 'package:web/web.dart';
import 'dart:js_interop';
import 'dart:math' as math;

import 'package:cross_file/cross_file.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:video_thumbnail_pro/src/image_format.dart';
import 'package:video_thumbnail_pro/src/video_thumbnail_platform.dart';

// An error code value to error name Map.
// See: https://developer.mozilla.org/en-US/docs/Web/API/MediaError/code
const Map<int, String> _kErrorValueToErrorName = <int, String>{
  1: 'MEDIA_ERR_ABORTED',
  2: 'MEDIA_ERR_NETWORK',
  3: 'MEDIA_ERR_DECODE',
  4: 'MEDIA_ERR_SRC_NOT_SUPPORTED',
};

// An error code value to description Map.
// See: https://developer.mozilla.org/en-US/docs/Web/API/MediaError/code
const Map<int, String> _kErrorValueToErrorDescription = <int, String>{
  1: 'The user canceled the fetching of the video.',
  2: 'A network error occurred while fetching the video, despite having previously been available.',
  3: 'An error occurred while trying to decode the video, despite having previously been determined to be usable.',
  4: 'The video has been found to be unsuitable (missing or in a format not supported by your browser).',
};

// The default error message, when the error is an empty string
// See: https://developer.mozilla.org/en-US/docs/Web/API/MediaError/message
const String _kDefaultErrorMessage =
    'No further diagnostic information can be determined or provided.';

/// A web implementation of the VideoThumbnailProPlatform of the VideoThumbnailPro plugin.
class VideoThumbnailProWeb extends VideoThumbnailProPlatform {
  /// Constructs a VideoThumbnailProWeb
  VideoThumbnailProWeb();

  static void registerWith(Registrar registrar) {
    VideoThumbnailProPlatform.instance = VideoThumbnailProWeb();
  }

  @override
  Future<XFile> thumbnailFile({
    required String video,
    required Map<String, String>? headers,
    required String? thumbnailPath,
    required ImageFormat imageFormat,
    required int maxHeight,
    required int maxWidth,
    required int timeMs,
    required int quality,
  }) async {
    final blob = await _createThumbnail(
      videoSrc: video,
      headers: headers,
      imageFormat: imageFormat,
      maxHeight: maxHeight,
      maxWidth: maxWidth,
      timeMs: timeMs,
      quality: quality,
    );

    return XFile(URL.createObjectURL(blob), mimeType: blob.type);
  }

  @override
  Future<Uint8List> thumbnailData({
    required String video,
    required Map<String, String>? headers,
    required ImageFormat imageFormat,
    required int maxHeight,
    required int maxWidth,
    required int timeMs,
    required int quality,
  }) async {
    final blob = await _createThumbnail(
      videoSrc: video,
      headers: headers,
      imageFormat: imageFormat,
      maxHeight: maxHeight,
      maxWidth: maxWidth,
      timeMs: timeMs,
      quality: quality,
    );
    final path = URL.createObjectURL(blob);
    final file = XFile(path, mimeType: blob.type);
    final bytes = await file.readAsBytes();
    URL.revokeObjectURL(path);

    return bytes;
  }

  Future<Blob> _createThumbnail({
    required String videoSrc,
    required Map<String, String>? headers,
    required ImageFormat imageFormat,
    required int maxHeight,
    required int maxWidth,
    required int timeMs,
    required int quality,
  }) async {
    final completer = Completer<Blob>();

    final video = document.createElement('video') as HTMLVideoElement;
    final timeSec = math.max(timeMs / 1000, 0);
    final fetchVideo = headers != null && headers.isNotEmpty;

    video.onloadedmetadata = (Event event) {
      video.currentTime = timeSec;

      if (fetchVideo) {
        URL.revokeObjectURL(video.src);
      }
    }.toJS;

    video.onseeked = (Event e) {
      if (!completer.isCompleted) {
        final canvas = document.createElement('canvas') as HTMLCanvasElement;
        final ctx = canvas.getContext('2d')! as CanvasRenderingContext2D;

        if (maxWidth == 0 && maxHeight == 0) {
          canvas
            ..width = video.videoWidth
            ..height = video.videoHeight;
          ctx.drawImage(video, 0, 0);
        } else {
          final aspectRatio = video.videoWidth / video.videoHeight;
          if (maxWidth == 0) {
            maxWidth = (maxHeight * aspectRatio).round();
          } else if (maxHeight == 0) {
            maxHeight = (maxWidth / aspectRatio).round();
          }

          final inputAspectRatio = maxWidth / maxHeight;
          if (aspectRatio > inputAspectRatio) {
            maxHeight = (maxWidth / aspectRatio).round();
          } else {
            maxWidth = (maxHeight * aspectRatio).round();
          }

          canvas
            ..width = maxWidth
            ..height = maxHeight;
          ctx.drawImage(video, 0, 0, maxWidth, maxHeight);
        }

        try {
          canvas.toBlob(
            (Blob? blob) {
              if (blob != null) {
                completer.complete(blob);
              } else {
                completer.completeError(
                  PlatformException(
                    code: 'CANVAS_EXPORT_ERROR',
                    message: 'Blob creation failed',
                  ),
                );
              }
            }.toJS,
            _imageFormatToCanvasFormat(imageFormat),
            (quality / 100).toJS,
          );
        } catch (e, s) {
          completer.completeError(
            PlatformException(
              code: 'CANVAS_EXPORT_ERROR',
              details: e,
              stacktrace: s.toString(),
            ),
            s,
          );
        }
      }
    }.toJS;

    video.onerror = (Event e) {
      if (!completer.isCompleted) {
        final error = video.error!;
        completer.completeError(
          PlatformException(
            code: _kErrorValueToErrorName[error.code]!,
            message:
                error.message != '' ? error.message : _kDefaultErrorMessage,
            details: _kErrorValueToErrorDescription[error.code],
          ),
        );
      }
    }.toJS;

    if (fetchVideo) {
      try {
        _fetchVideoByHeaders(
          videoSrc: videoSrc,
          headers: headers,
        ).then((blob) {
          video.src = URL.createObjectURL(blob);
        }).catchError((e, s) {
          completer.completeError(e, s);
        });
      } catch (e, s) {
        completer.completeError(e, s);
      }
    } else {
      video
        ..crossOrigin = 'Anonymous'
        ..src = videoSrc;
    }

    return completer.future;
  }

  /// Fetching video by [headers].
  ///
  /// To avoid reading the video's bytes into memory, set the
  /// [XMLHttpRequest.responseType] to 'blob'. This allows the blob to be stored in
  /// the browser's disk or memory cache.
  Future<Blob> _fetchVideoByHeaders({
    required String videoSrc,
    required Map<String, String> headers,
  }) async {
    final completer = Completer<Blob>();

    final xhr = XMLHttpRequest()
      ..open('GET', videoSrc, true)
      ..responseType = 'blob';
    headers.forEach((key, value) => xhr.setRequestHeader(key, value));

    xhr.onload = (ProgressEvent value) {
      completer.complete(xhr.response as Blob);
    }.toJS;

    xhr.onerror = (ProgressEvent value) {
      completer.completeError(
        PlatformException(
          code: 'VIDEO_FETCH_ERROR',
          message: 'Status: ${xhr.statusText}',
        ),
      );
    }.toJS;

    xhr.send();

    return completer.future;
  }

  String _imageFormatToCanvasFormat(ImageFormat imageFormat) {
    switch (imageFormat) {
      case ImageFormat.JPEG:
        return 'image/jpeg';
      case ImageFormat.PNG:
        return 'image/png';
      case ImageFormat.WEBP:
        return 'image/webp';
    }
  }
}
