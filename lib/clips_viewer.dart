import 'dart:convert';

import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:sentryviewer/sentry_event.dart';
import 'package:sentryviewer/sentry_event_metadata.dart';
import 'package:shared_storage/shared_storage.dart';
import 'package:video_player/video_player.dart';

import 'main.dart';

class ClipsViewer extends StatefulWidget {
  final DocumentFile directory;

  const ClipsViewer({required this.directory, super.key});

  @override
  State<ClipsViewer> createState() => _ClipsViewerState();
}

class _ClipsViewerState extends State<ClipsViewer> {
  VideoPlayerController? _frontController;
  VideoPlayerController? _backController;
  VideoPlayerController? _leftController;
  VideoPlayerController? _rightController;
  late Duration videoDuration;
  SentryEventMetadata? _metadata;
  int selectedEvent = 0;

  final List<DocumentFile?> _files = [];
  final List<SentryEvent> _events = [];

  Future<void> _initializeVideoPlayerFuture() async {
    for (var i = 0; i < _files.length; i++) {
      DocumentFile? f = _files[i];
      if (f == null) {
        continue;
      }
      if (f.name == 'thumb.png') {
        continue;
      }
      if (f.name!.endsWith('.mp4')) {
        String? prefix = f.name?.substring(0, f.name?.lastIndexOf('-'));
        print('subevent found: $prefix');
        if (prefix != null) {
          int front = _files.indexWhere((element) => element?.name == '$prefix-front.mp4');
          int back = _files.indexWhere((element) => element?.name == '$prefix-back.mp4');
          int left = _files.indexWhere((element) => element?.name == '$prefix-left_repeater.mp4');
          int right = _files.indexWhere((element) => element?.name == '$prefix-right_repeater.mp4');
          String timeString = prefix;
          List<String> split = timeString.split('_');
          split[1] = split[1].replaceAll('-', ':');
          timeString = split.join(' ');
          _events.add(SentryEvent(
              frontVideoUri: _files[front]!.uri,
              backVideoUri: _files[back]!.uri,
              leftVideoUri: _files[left]!.uri,
              rightVideoUri: _files[right]!.uri,
              time: DateTime.parse(timeString)));
          _files[front] = null;
          _files[back] = null;
          _files[left] = null;
          _files[right] = null;
        }
      }
      if (f.name == 'event.json') {
        String? content = await f.getContentAsString();
        if (content != null) {
          // load json
          final parsed = jsonDecode(content);
          setState(() {
            _metadata = SentryEventMetadata.fromJson(parsed);
            print(_metadata.toString());
          });
        }
        continue;
      }
    }

    List<VideoPlayerController> controllers = [
      VideoPlayerController.contentUri(_events[selectedEvent].frontVideoUri,
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true)),
      VideoPlayerController.contentUri(_events[selectedEvent].backVideoUri,
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true)),
      VideoPlayerController.contentUri(_events[selectedEvent].leftVideoUri,
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true)),
      VideoPlayerController.contentUri(_events[selectedEvent].rightVideoUri,
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true))
    ];

    await Future.wait(controllers.map((controller) => controller.initialize()));
    videoDuration = controllers[0].value.duration;
    setState(() {
      _frontController = controllers[0];
      _backController = controllers[1];
      _leftController = controllers[2];
      _rightController = controllers[3];
    });
  }

  _updateControllers() async {
    _frontController?.dispose();
    _backController?.dispose();
    _leftController?.dispose();
    _rightController?.dispose();

    List<VideoPlayerController> controllers = [
      VideoPlayerController.contentUri(_events[selectedEvent].frontVideoUri,
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true)),
      VideoPlayerController.contentUri(_events[selectedEvent].backVideoUri,
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true)),
      VideoPlayerController.contentUri(_events[selectedEvent].leftVideoUri,
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true)),
      VideoPlayerController.contentUri(_events[selectedEvent].rightVideoUri,
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true))
    ];

    await Future.wait(controllers.map((controller) => controller.initialize()));
    videoDuration = controllers[0].value.duration;
    setState(() {
      _frontController = controllers[0];
      _backController = controllers[1];
      _leftController = controllers[2];
      _rightController = controllers[3];
    });
  }

  @override
  void initState() {
    super.initState();
    final Stream<DocumentFile> onFileLoaded = listFiles(widget.directory.uri, columns: columns);
    onFileLoaded.listen((file) => setState(() => _files.add(file)), onDone: _initializeVideoPlayerFuture);
  }

  void _togglePlayback() {
    setState(() {
      if (_frontController!.value.isPlaying) {
        _frontController?.pause();
        _backController?.pause();
        _leftController?.pause();
        _rightController?.pause();
        _doSync();
      } else {
        _doSync();
        _frontController?.play();
        _backController?.play();
        _leftController?.play();
        _rightController?.play();
      }
    });
  }

  void _setPlayback(bool playing) {
    setState(() {
      if (playing) {
        _frontController?.play();
        _backController?.play();
        _leftController?.play();
        _rightController?.play();
      } else {
        _frontController?.pause();
        _backController?.pause();
        _leftController?.pause();
        _rightController?.pause();
        _doSync();
      }
    });
  }

  void _doSync() {
    _backController?.seekTo(_frontController!.value.position);
    _leftController?.seekTo(_frontController!.value.position);
    _rightController?.seekTo(_frontController!.value.position);
  }

  void _doSeek(Duration duration) {
    _frontController?.seekTo(duration);
    _backController?.seekTo(duration);
    _leftController?.seekTo(duration);
    _rightController?.seekTo(duration);
    _setPlayback(true);
  }

  Stream<Duration> positionStream(VideoPlayerController controller) async* {
    while (controller.value.isPlaying) {
      yield controller.value.position;
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_frontController == null) {
      return Scaffold(
          appBar: AppBar(title: const Text('Loading...')),
          body: const Center(
            child: CircularProgressIndicator(),
          ));
    }

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Clip Viewer'),
      ),
      body: Center(
        child: _frontController!.value.isInitialized
            ? GridView.count(
                crossAxisCount: 2,
                children: [
                  AspectRatio(
                    aspectRatio: _frontController!.value.aspectRatio,
                    child: VideoPlayer(_frontController!),
                  ),
                  AspectRatio(
                    aspectRatio: _backController!.value.aspectRatio,
                    child: VideoPlayer(_backController!),
                  ),
                  AspectRatio(
                    aspectRatio: _leftController!.value.aspectRatio,
                    child: VideoPlayer(_leftController!),
                  ),
                  AspectRatio(
                    aspectRatio: _rightController!.value.aspectRatio,
                    child: VideoPlayer(_rightController!),
                  ),
                ],
              )
            : const CircularProgressIndicator(),
      ),
      bottomNavigationBar: Column(mainAxisSize: MainAxisSize.min, children: [
        DropdownButton<String>(
            value: _events[0].time.toString(),
            icon: const Icon(Icons.arrow_downward),
            onChanged: (a) {
              setState(() {
                selectedEvent = _events.indexWhere((element) => element.time.toString() == a);
                _updateControllers();
              });
            },
            items: _events
                .map((e) => DropdownMenuItem<String>(value: e.time.toString(), child: Text(e.time.toString())))
                .toList()),
        StreamBuilder<Duration>(
            stream: positionStream(_frontController!),
            builder: (context, snapshot) {
              return ProgressBar(
                  progress: snapshot.data ?? Duration.zero,
                  total: videoDuration,
                  onSeek: _doSeek,
                  onDragStart: (a) => _setPlayback(false));
            }),
        FilledButton(
            onPressed: _togglePlayback,
            child: Icon(
              _frontController!.value.isPlaying ? Icons.pause : Icons.play_arrow,
            ))
      ]),
    );
  }

  @override
  void dispose() {
    _frontController?.dispose();
    _backController?.dispose();
    _leftController?.dispose();
    _rightController?.dispose();
    super.dispose();
  }
}
