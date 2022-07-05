# FAQ for riverpod user

## Why do you create another library instead of improving riverpod?

We tried to fix issues
([1](https://github.com/rrousselGit/riverpod/issues/1292),
[2](https://github.com/rrousselGit/riverpod/issues/1310)) we had with riverpod,
but soon realized that riverpod's implementation is too complex for us. Remi did
a great job maintaining riverpod, but the complexity makes it hard for others to
make large contribution. 

We wanted something simpler both in concept and in implementation. Creator has a
fundamental different implementation, which I hope could influence riverpod and
make it simpler.

I had a nice chat with Remi. He likes the idea of using `Future.value` in
`Emitter`, and might adopt it in riverpod too.

So, I believe Creator could benefit Flutter community overall.

## Why I should use creator rather than riverpod?

1. Creator is easier to learn.

   You only need to know two things: `Emitter` for anything with `async` and
   `Creator` for the rest.

2. Creator behaves more like Stream.

   With a Stream of `[loading, data1, data2, data3, ...]`, riverpod's StreamProvider
   generates `[loading, data1, loading, data2, loading, data3, ...]`, which is
   counterintuitive in my mind.

3. Creator has a nicer async API.

   Using `Emitter`, you can `emit` zero or multiple times. You can combine
   `emit` and `set` to express complex logic concisely
   ([example](https://dartpad.dev/?id=a6d82a6bb955fa4f42ff50b6c6d90d34)).
   
4. Creator has extension methods.

   Creator has methods like `map`, `where`, and `reduce`, which are quite handy
   in practice. Thanks to the simple data model, all these methods return normal
   `Creator/Emitter`. In riverpod, `select` returns an internal data type, and there is
   no equivalent to `where` method.

5. Creator's source code is easy to understand.
   
   This matters when you hope to contribute or alter the library in the way you
   want. Read this
   [article](https://medium.com/@terryl1900/create-a-flutter-state-management-library-with-100-lines-of-code-e80bd865f4bd)
   then read the [source
   code](https://github.com/terryl1900/creator#read-source-code).

## How does riverpod providers map to creators?

Just use Emitter for anything with `async` and use Creator for the rest. Or follow this:

| Riverpod  | Creator |
| ------------- | ------------- |
| Provider  | Creator  |
| StateProvider | Creator |
| FutureProvider | Emitter |
| StreamProvider | Emitter.stream  |
| StateNotifierProvider  | Creator with a file-level private variable ([example](https://dartpad.dev/?id=1a4c338fdf8ef7c4af8f80ddff88f4ec)) or a class-level private variable |
| ChangeNotifierProvider | Not supported. Note ChangeNotifierProvider is not encouraged in riverpod  |

## Can I use both riverpod and creator in one project?

Yes. You can safely wrap `ProviderScope` inside `CreatorGraph` or vice versa.

The names creator/emitter/watcher are different from providers, so there are
minimum name conflicts. However, the name `Ref` is the same in both packages.
That means if you use both provider and creator in the same file, you will
likely need to hide `Ref` or rename one of the packages in import statements.