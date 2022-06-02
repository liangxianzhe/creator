import 'package:flutter/material.dart';
import 'package:creator/creator.dart';

// Simple news app with infinite list of news. It shows combining creators
// for loading indicator and fetching data with pagination.

// repo.dart

// Pretend calling a backend service to get news.

const count = 10; // Item count per page.

Future<List<String>> fetchNews(int page) async {
  await Future.delayed(const Duration(seconds: 1));
  return List.generate(count, (index) {
    final date = DateTime.now().subtract(Duration(days: page * count + index));
    return '${date.toIso8601String().substring(0, 10)} is a peaceful day';
  });
}

// logic.dart

// Hide _page in file level private variable and expose fetchMore API.
final _page = Creator.value(0);
void fetchMore(Ref ref) => ref.update<int>(_page, (n) => n + 1);

// Loading indicator.
final loading = Creator.value(true);

// News fetches next page when _page changes.
final news = Emitter<List<String>>((ref, emit) async {
  ref.set(loading, true);
  final next = await fetchNews(ref.watch(_page));
  final current = ref.readSelf<List<String>>() ?? [];
  emit([...current, ...next]);
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
      ((context, ref, _) {
        final data = ref.watch(news.asyncData).data ?? [];
        return ListView.builder(
          itemCount: data.length + 1,
          itemBuilder: ((context, index) {
            if (index == data.length) {
              // Using another Watcher here is an optional optimization, to
              // avoid rebuild the whole list when loading indicator changes.
              return Watcher(((context, ref, _) {
                return TextButton(
                  onPressed: ref.watch(loading) ? null : () => fetchMore(ref),
                  child: Text(ref.watch(loading) ? 'Loading' : 'Load more'),
                );
              }));
            } else {
              return Center(child: Text(data[index]));
            }
          }),
        );
      }),
    );
  }
}
