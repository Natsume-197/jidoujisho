import 'dart:io';

import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:path_provider/path_provider.dart';
import 'package:subtitle/subtitle.dart';
import 'package:path/path.dart' as path;

/// Differentiates different types of [SubtitleItem].
enum SubtitleItemType {
  /// Subtitles from a file.
  externalSubtitle,

  /// Subtitle from a video.
  embeddedSubtitle,

  /// Represents an item that contains no subtitles.
  noneSubtitle,

  /// Subtitle from a separate web document.
  webSubtitle,
}

/// Represents subtitles that can be used in the player.
class SubtitleItem {
  /// Initialise an item.
  SubtitleItem({
    required this.controller,
    required this.type,
    this.metadata,
    this.index,
  });

  /// The controller that contains the content of the subtitle.
  SubtitleController controller;

  /// The type of the subtitle, embedded, external, etc.
  SubtitleItemType type;

  /// Used to possibly identify the content of a subtitle.
  String? metadata;

  /// Used to possibly identify the order of a subtitle.
  int? index;
}

/// A class for calling subtitle utility functions.
class SubtitleUtils {
  /// Fetches a subtitle from a subtitle file.
  static Future<SubtitleItem> subtitlesFromFile({
    required File file,
    required SubtitleItemType type,
    String? metadata,
    int? index,
  }) async {
    String fileExtension = path.extension(file.path).toLowerCase();

    if (!file.existsSync()) {
      return SubtitleItem(
        controller: SubtitleController(
          provider: SubtitleProvider.fromFile(
            file,
          ),
        ),
        metadata: metadata,
        type: type,
        index: index,
      );
    }

    switch (fileExtension) {
      case '.srt':
        return SubtitleItem(
          controller: SubtitleController(
            provider: SubtitleProvider.fromString(
              data: file.readAsStringSync(),
              type: SubtitleType.srt,
            ),
          ),
          metadata: metadata,
          type: type,
          index: index,
        );
      case '.ass':
      case '.ssa':
        return SubtitleItem(
          controller: SubtitleController(
            provider: SubtitleProvider.fromString(
              data: await convertAssSubtitles(file.path),
              type: SubtitleType.srt,
            ),
          ),
          metadata: metadata,
          type: type,
          index: index,
        );
    }

    return SubtitleItem(
      controller: SubtitleController(
        provider: SubtitleProvider.fromFile(
          file,
        ),
      ),
      metadata: metadata,
      type: type,
      index: index,
    );
  }

  /// Gets a list of subtitles from a video file.
  static Future<List<SubtitleItem>> subtitlesFromVideo(
    File file,
    int embeddedTrackCount,
  ) async {
    List<File> outputFiles = [];

    Directory appDocDir = await getApplicationDocumentsDirectory();
    Directory subsDir = Directory('${appDocDir.path}/subtitles');
    if (!subsDir.existsSync()) {
      subsDir.createSync(recursive: true);
    }

    String inputPath = file.path;

    for (int i = 0; i < embeddedTrackCount - 1; i++) {
      String outputPath = '${subsDir.path}/extractSrt$i.srt';
      String command =
          '-loglevel verbose -i "$inputPath" -map 0:s:$i "$outputPath"';

      File outputFile = File(outputPath);

      if (outputFile.existsSync()) {
        outputFile.deleteSync();
      }

      final FlutterFFmpeg _flutterFFmpeg = FlutterFFmpeg();
      final FlutterFFmpegConfig _flutterFFmpegConfig = FlutterFFmpegConfig();

      await _flutterFFmpeg.execute(command);
      String output = await _flutterFFmpegConfig.getLastCommandOutput();
      if (output.contains("Stream map '0:s:$i' matches no streams.")) {
        break;
      }

      await Future.delayed(const Duration(seconds: 1));

      outputFiles.add(outputFile);
    }

    List<SubtitleItem> items = [];
    for (int i = 0; i < outputFiles.length; i++) {
      File outputFile = outputFiles[i];

      SubtitleItem item = await subtitlesFromFile(
        file: outputFile,
        type: SubtitleItemType.embeddedSubtitle,
        index: i,
      );

      items.add(item);
    }

    return items;
  }

  /// Converts ASS subtitles to SRT and returns the data.
  static Future<String> convertAssSubtitles(String inputPath) async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    Directory subsDir = Directory('${appDocDir.path}/subtitles');
    if (!subsDir.existsSync()) {
      subsDir.createSync(recursive: true);
    }

    String outputPath = '${subsDir.path}/assSubtitles.srt';
    File targetFile = File(outputPath);

    if (targetFile.existsSync()) {
      targetFile.deleteSync();
    }

    String command = '-i "$inputPath" "$outputPath"';

    final FlutterFFmpeg _flutterFFmpeg = FlutterFFmpeg();

    await _flutterFFmpeg.execute(command);

    return targetFile.readAsStringSync();
  }
}
