import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sentryviewer/main.dart';
import 'package:sentryviewer/sentry_event_list_item.dart';
import 'package:shared_storage/shared_storage.dart';

class ClipsList extends StatefulWidget {
  final DocumentFile directory;

  const ClipsList({required this.directory, super.key});

  @override
  State<ClipsList> createState() => _ClipsListState();
}

class _ClipsListState extends State<ClipsList> {
  List<DocumentFile> files = [];

  @override
  void initState() {
    final Stream<DocumentFile> onFileLoaded = listFiles(widget.directory.uri, columns: columns);
    onFileLoaded.listen((file) =>  files.add(file), onDone: () {
      // sort files
        files.sort((b, a ) => a.name!.compareTo(b.name!));
        setState(() {});

    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
        restorationId: 'list_demo_list_view',
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [for (DocumentFile f in files) SentryEventListItem(directory: f)]);
  }
}
