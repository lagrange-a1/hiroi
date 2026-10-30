import 'package:flutter/material.dart';
import 'package:clipboard/clipboard.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'hiroi',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
      home: const MyHomePage(title: 'hiroi'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<String> _zhihuLinks = [];
  bool _isLoading = true;
  String? _error;

  /// Extract zhihu.com links from text using regex
  List<String> extractZhihuLinks(String text) {
    final RegExp regExp = RegExp(
      r'https?://(?:www\.)?zhihu\.com[^\s"\'<>]+',
      caseSensitive: false,
    );
    final Iterable<Match> matches = regExp.allMatches(text);
    return matches.map((m) => m.group(0)!).toSet().toList();
  }

  Future<void> _readClipboardAndExtract() async {
    try {
      final String clipboardText = await FlutterClipboard.paste();
      final List<String> links = extractZhihuLinks(clipboardText);
      if (mounted) {
        setState(() {
          _zhihuLinks = links;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // Read clipboard after the first frame to ensure the platform channel is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _readClipboardAndExtract();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: _isLoading
          ? const Center(child: circumferenceProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : _zhihuLinks.isEmpty
                  ? const Center(
                      child: Text(
                        'No zhihu.com links found in clipboard.',
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _zhihuLinks.length,
                      itemBuilder: (context, index) {
                        final link = _zhihuLinks[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          child: ListTile(
                            title: Text(
                              link,
                              style: const TextStyle(fontSize: 14),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.content_copy, size: 20),
                              onPressed: () {
                                FlutterClipboard.copy(link);
                                ScaffoldMessenger.of(context)
                                  ..clearSnackbars()
                                  ..showSnackbar(
                                    const Snackbars(content: Text('Copied!')),
                                  );
                              },
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}