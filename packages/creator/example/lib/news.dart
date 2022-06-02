import 'package:flutter/material.dart';
import 'package:creator/creator.dart';

// Simple news app with infinite list of news. It shows combining creators
// for loading indicator and fetching data with pagination.

// repo.dart

// Pretend calling a backend service to get news.
Future<List<String>> fetchNews(int startIndex, int count) async {
  await Future.delayed(const Duration(seconds: 1));
  return List.generate(count, (index) {
    final date = DateTime.now().subtract(Duration(days: startIndex + index));
    return '${date.toIso8601String().substring(0, 10)} is a peaceful day';
  });
}

// logic.dart

final news = Creator<List<String>>.value([]);
final loading = Creator.value(true); // default to true to fetch first page
final _nextIndex = Creator.value(0); // private state

// fetcher does the work, but has no state itself.
final fetcher = Emitter<void>((ref, emit) async {
  // Keep news and _nextIndex alive in case we return early. This also ensure
  // they are disposed when fetcher is disposed, in case UI doesn't watch news.
  ref.watch(news);
  ref.watch(_nextIndex);
  if (!ref.watch(loading)) {
    return; // Only fetch if loading is set by user.
  }

  final fetched = await fetchNews(ref.watch(_nextIndex), 10);
  ref.update<int>(_nextIndex, (n) => n + 10);
  ref.update<List<String>>(news, (current) => [...current, ...fetched]);
  ref.set(loading, false);
});

// main.dart

void main() {
  runApp(CreatorGraph(child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('News example')),
        body: const NewsList(),
      ),
    );
  }
}

class NewsList extends StatelessWidget {
  const NewsList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Watcher(
      ((context, ref, child) {
        return ListView.builder(
            itemCount: ref.watch(news).length + 1,
            itemBuilder: ((context, index) {
              if (index == ref.watch(news).length) {
                return TextButton(
                    onPressed: () => ref.set(loading, true),
                    child: Text(ref.watch(loading) ? 'Loading' : 'Load more'));
              } else {
                return Center(child: Text(ref.watch(news)[index]));
              }
            }));
      }),
      listener: (ref) => ref.watch(fetcher), // Let fetcher do the work.
    );
  }
}
