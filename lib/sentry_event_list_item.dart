import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sentryviewer/video_cache.dart';
import 'package:shared_storage/shared_storage.dart';
import 'package:intl/intl.dart';

import 'clips_viewer.dart';
import 'main.dart';

class SentryEventListItem extends StatefulWidget {
  final DocumentFile directory;
  late DateTime parsedTime;

  SentryEventListItem({required this.directory, super.key}) {
    String timeString = directory.name ?? '';
    List<String> split = timeString.split('_');
    split[1] = split[1].replaceAll('-', ':');
    timeString = split.join(' ');
    parsedTime = DateTime.parse(timeString);
  }

  @override
  State<SentryEventListItem> createState() => _SentryEventListItemState();
}

class _SentryEventListItemState extends State<SentryEventListItem> {
  Image _thumb = Image.asset('assets/placeholder.png');
  bool thumbLoaded = false;

  @override
  void initState() {
    Uri uri = Uri(
      scheme: widget.directory.uri.scheme,
      host: widget.directory.uri.host,
      path: '${widget.directory.uri.path}%2Fthumb.png',
    );
    try {
      uri.toDocumentFile().then((file) async {
        if (file != null) {
          if(await file.exists() ?? false) {
            Uint8List? content = await file.getContent();
            setState(() {
              _thumb = Image.memory(content!);
              thumbLoaded = true;
            });
          } else {
            setState(() {
              thumbLoaded = true;
            });
          }
        } else {

          setState(() {
            thumbLoaded = true;
          });
        }
      });
    } catch (e){
        print('failed to load thumb');
        setState(() {
          thumbLoaded = true;
        });
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        height: 64,
        child: ListTile(
            onTap: () {
              Navigator.push(
                  context, MaterialPageRoute(builder: (context) => ClipsViewer(directory: widget.directory)));
            },
            leading: thumbLoaded ? _thumb : const CircularProgressIndicator(),
            title: Text(DateFormat('E MMM dd yyyy hh:mm a').format(widget.parsedTime))));
  }
}
