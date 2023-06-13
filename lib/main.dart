import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_storage/shared_storage.dart';

import 'clips_list.dart';

void main() {
  runApp(const MyApp());
}

const List<DocumentFileColumn> columns = <DocumentFileColumn>[
  DocumentFileColumn.displayName,
  DocumentFileColumn.size,
  DocumentFileColumn.lastModified,
  DocumentFileColumn.id,
  DocumentFileColumn.mimeType
];

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 114, 137, 218)),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Sentry Viewer'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin, RestorationMixin {
  List<DocumentFile> files = [];
  TabController? _tabController;
  final RestorableInt tabIndex = RestorableInt(0);
  bool sentryValid = false;

  @override
  String get restorationId => 'tab_scrollable_demo';

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(tabIndex, 'tab_index');
    _tabController!.index = tabIndex.value;
  }

  @override
  void initState() {
    _tabController = TabController(
      initialIndex: 0,
      length: 3,
      vsync: this,
    );
    _tabController!.addListener(() {
      setState(() {
        tabIndex.value = _tabController!.index;
      });
    });
    SharedPreferences.getInstance().then((value) {
      final String? sentryPath = value.getString('sentryPath');
      if (sentryPath != null) {
        final Stream<DocumentFile> onFileLoaded = listFiles(Uri.parse(sentryPath), columns: columns);
        onFileLoaded.listen((file) => setState(() => files.add(file)), onDone: _checkSentryFolders);
      }
    });
    super.initState();
  }

  void _checkSentryFolders() {
    bool recentClips = false;
    bool sentryClips = false;
    bool savedClips = false;
    for (DocumentFile f in files) {
      switch (f.name) {
        case 'RecentClips':
          recentClips = true;
          break;
        case 'SentryClips':
          sentryClips = true;
          break;
        case 'SavedClips':
          savedClips = true;
          break;
      }
    }
    if (recentClips && sentryClips && savedClips) {
      sentryValid = true;
    }
  }

  Future<void> doStorageRequest() async {
    final Uri? grantedUri = await openDocumentTree();
    if (grantedUri != null) {
      final Stream<DocumentFile> onFileLoaded = listFiles(grantedUri, columns: columns);
      SharedPreferences.getInstance().then((value) {
        value.setString('sentryPath', grantedUri.toString());
      });
      onFileLoaded.listen((file) => setState(() => files.add(file)), onDone: _checkSentryFolders);
    } else {
      Fluttertoast.showToast(msg: 'No URI Granted');
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabs = ['SavedClips', 'SentryClips', 'RecentClips'];
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
          // TRY THIS: Try changing the color here to a specific color (to
          // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
          // change color while the other colors stay the same.
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: Text(widget.title),
          bottom:
              sentryValid ? TabBar(controller: _tabController, isScrollable: true, tabs: [for (final tab in tabs) Tab(text: tab)]) : null),
      body: files.isNotEmpty
          ? TabBarView(
              controller: _tabController,
              children: [
                for (final tab in tabs)
                  Center(
                    child: ClipsList(directory: files.firstWhere((element) => element.name == tab)),
                  ),
              ],
            )
          : Center(
              // Center is a layout widget. It takes a single child and positions it
              // in the middle of the parent.
              child: Column(
                // Column is also a layout widget. It takes a list of children and
                // arranges them vertically. By default, it sizes itself to fit its
                // children horizontally, and tries to be as tall as its parent.
                //
                // Column has various properties to control how it sizes itself and
                // how it positions its children. Here we use mainAxisAlignment to
                // center the children vertically; the main axis here is the vertical
                // axis because Columns are vertical (the cross axis would be
                // horizontal).
                //
                // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
                // action in the IDE, or press "p" in the console), to see the
                // wireframe for each widget.
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    files.length.toString(),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  FilledButton(onPressed: doStorageRequest, child: const Text('Choose TeslaCam Folder'))
                ],
              ),
            ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
