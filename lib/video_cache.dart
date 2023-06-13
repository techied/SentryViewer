import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:ffmpeg_kit_flutter/log.dart';
import 'package:ffmpeg_kit_flutter/session.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:image/image.dart' as img;

class VideoCache {
  final String contentUri;

  VideoCache({required this.contentUri});

  Future<MemoryImage> loadThumbnail() async {
    final tempDir = await getTemporaryDirectory();
    final thumbnailPath = '${tempDir.path}/thumbnail_${contentUri.hashCode}.jpg';

    final thumbnailFile = File(thumbnailPath);
    if (thumbnailFile.existsSync()) {
      Uint8List bytes = await thumbnailFile.readAsBytes();
      return MemoryImage(bytes);
    } else {
      return await createThumbnail(thumbnailPath);
    }
  }

  Future<MemoryImage> createThumbnail(String thumbnailPath) async {
    final arguments = '-y -i $contentUri -ss 00:00:01.000 -vframes 1 -vf scale=300:-1 $thumbnailPath';

    await FFmpegKit.executeAsync(arguments, (Session session) async {
      print('FFmpeg command completed with return code: ${session.getReturnCode()}');
    }, (Log log) {
      print(log.getMessage());
    });
    if(File(thumbnailPath).existsSync()){
        final thumbnailFile = File(thumbnailPath);
        Uint8List bytes = await thumbnailFile.readAsBytes();
        return MemoryImage(bytes);
    }
    throw Exception("Failed to create thumbnail");
  }
}
