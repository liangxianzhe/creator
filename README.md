<p align="center"> <img height="80" src="https://github.com/terryl1900/creator/blob/master/resource/logo.png?raw=true"> </p>

<p align="center">
<a href="https://pub.dev/packages/creator"><img src="https://img.shields.io/pub/v/creator.svg" alt="Pub"></a>
<a href="https://github.com/terryl1900/creator/actions"><img src="https://github.com/terryl1900/creator/workflows/Build/badge.svg" alt="build"></a>
</p>

Creator is a state management library that enables **concise, fluid, readable, and testable** business logic code.

Read and update state with compile time safety:

```dart
// Creator creates a stream of data.
final counter = Creator.value(0);
```

```dart
Widget build(BuildContext context) {
  return Column(
    children: [
      // Watcher will rebuild whenever counter changes.
      Watcher((context, ref, _) => Text('${ref.watch(counter)}')),
      TextButton(
        // Update state is easy.
        onPressed: () => context.ref.update<int>(counter, (count) => count + 1),
        child: const Text('+1'),
      ),
    ],
  );
}
```

Write clean and testable business logic:

```dart
// repo.dart

// Pretend calling a backend service to get fahrenheit temperature.
Future<int> getFahrenheit(String city) async {
  await Future.delayed(const Duration(milliseconds: 100));
  return 60 + city.hashCode % 20;
}
```

```dart
// logic.dart

// Simple creators bind to UI.
final cityCreator = Creator.value('London');
final unitCreator = Creator.value('Fahrenheit');

// Write fluid code with methods like map, where, etc.
final fahrenheitCreator = cityCreator.asyncMap(getFahrenheit);

// Combine creators for business logic. 
final temperatureCreator = Emitter<String>((ref, emit) async {
  final f = await ref.watch(fahrenheitCreator);
  final unit = ref.watch(unitCreator);
  emit(unit == 'Fahrenheit' ? '$f F' : '${f2c(f)} C');
});

// Fahrenheit to celsius converter.
int f2c(int f) => ((f - 32) * 5 / 9).round();
```

```dart
// main.dart

Widget build(BuildContext context) {
  return Watcher((context, ref, _) => 
      Text(ref.watch(temperatureCreator.asyncData).data ?? 'loading'));
}
... context.ref.set(cityCreator, 'Pairs');  // triggers backend call
... context.ref.set(unitCreator, 'Celsius');  // doesn't trigger backend call
```

Getting started:
```
dart pub add creator
```

Table of content:
- [Why Creator?](#why-creator)
- [Concept](#concept)
- [Usage](#usage)
  - [Creator](#creator)
  - [Emitter](#emitter)
  - [CreatorGraph](#creatorgraph)
  - [Watcher](#watcher)
  - [Listen to change](#listen-to-change)
  - [Name](#name)
  - [Keep alive](#keep-alive)
  - [Creator group](#creator-group)
  - [Extension method](#extension-method)
  - [Creator equality](#creator-equality)
  - [Service locator](#service-locator)
  - [Error handling](#error-handling)
  - [Testing](#testing)
- [Example](#example)
  - [Counter](#counter)
  - [Decremental counter](#decremental-counter)
  - [Weather](#weather)
  - [News](#news)
  - [Graph](#graph)
- [Best practice](#best-practice)
- [Read source code](#read-source-code)
- [FAQ](#faq)
  - [Is it production ready?](#is-it-production-ready)
  - [Is it bad to define creator as global variable?](#is-it-bad-to-define-creator-as-global-variable)
  - [How to watch a property while still accessing the whole object?](#how-to-watch-a-property-while-still-accessing-the-whole-object)
  - [How does creator's life cycle work?](#how-does-creators-life-cycle-work)
  - [What's the difference between `context.ref` vs `ref` in `Creator((ref) => ...)`?](#whats-the-difference-between-contextref-vs-ref-in-creatorref--)
  - [What's the difference between `Creator<Future<T>>` vs `Emitter<T>`?](#whats-the-difference-between-creatorfuturet-vs-emittert)
- [That's it](#thats-it)

# Why Creator?

When we built our Flutter app, we started with
[flutter_bloc](https://github.com/felangel/bloc). Later we switched to
[riverpod](https://github.com/rrousselGit/riverpod). However, we encountered
several issues related to its async providers and realized we wanted a different
mechanism.

So we built Creator. It is heavily inspired by `riverpod`, but with a simpler
data model, better async support, and a much simpler implementation.

The benefit of using Creator:

* Enables concise, fluid, readable, and testable code.
* Expressive for both sync and async behavior.
* Simple concept. Simple implementation. Lightweight.

# Concept

Creator's concept is extremely simple. There are only two types of creators: 
* `Creator` which creates a stream of `T`.
* `Emitter` which creates a stream of `Future<T>`.

Here stream is in its logical term, not the Stream class.

Both `Creator` and `Emitter`:

* Can depend on other creators, and update its state when others' state changes.
* Are loaded lazily and disposed automatically.

Dependencies form a graph, and it is managed internally by the framework. This is
the graph for the weather example above:

![weather](https://github.com/terryl1900/creator/blob/master/resource/weather.png?raw=true)

# Usage

## Creator

`Creator` takes a function you write to create a state. The function takes a `Ref`, which
provides API to interact with the internal graph.

```dart
final number = Creator.value(42);  // Same as Creator((ref) => 42)
final double = Creator((ref) => ref.watch(number) * 2);
```

Calling watch adds an edge `number` -> `double` to the graph, so `double`'s create
function will rerun whenever `number`'s state changes.

The nice part is that creator comes with methods like `map`, `where`, `reduce`, etc. They
are similar to those methods in Iterable or Stream. So `double` can
simply be:

```dart
final double = number.map((n) => n * 2);
```

To update the creator's state, use either `set` or `update`:

```dart
... ref.set(number, 42);  // No-op if value is the same
... ref.update<int>(number, (n) => n + 10);
```

You can also `read` a creator when `watch` doesn't make sense, for example, inside
a touch event handler.

```dart
TextButton(
  onPressed: () => print(context.ref.read(number)),
  child: const Text('Print'));
```

Creator's dependency can be dynamic:

```dart
final C = Creator((ref) {
  final value = ref.watch(A);
  return value >= 0 ? value : ref.watch(B);
});
```

In this example, `A` -> `C` always exists, `B` -> `C` may or may not exist. The
framework will update the graph properly as dependency changes.

## Emitter

`Emitter` works very similar to `Creator`, but it creates `Future<T>` instead
of `<T>`. The main difference is `Creator` has valid data to begin with, while
`Emitter` might need to wait for some async work before it yields the first
data.

In practice, `Emitter` is very useful to deal with data from backend
services, which is async by nature.

```dart
final stockCreator = Creator.value('TSLA');
final priceCreator = Emitter<int>((ref, emit) async {
  final stock = ref.watch(stockCreator);
  final price = await fetchStockPrice(stock);
  emit(price);
});
```

`Emitter` takes a `FutureOr<void> Function(Ref ref, void Function(T) emit)`,
where `ref` allows getting data from the graph, and `emit` allows pushing data
back to the graph. You can `emit` multiple times.

Existing `Stream` can be converted to Emitter easily with `Emitter.stream`. It
works both sync or async:

```dart
final authCreator = Emitter.stream(
    (ref) => FirebaseAuth.instance.authStateChanges());

final userCreator = Emitter.stream((ref) async {
  final authId = await ref.watch(
      authCreator.where((auth) => auth != null).map((auth) => auth!.uid));
  return FirebaseFirestore.instance.collection('users').doc(authId).snapshots();
});
```

This example also shows the extension method `where` and `map`. With them,
userCreator will only recreate when auth id changes, and ignore changes on other
auth properties.

In some sense, you can think `Emitter` as a different version of
`Stream`, which makes combining streams super easy.

`Emitter` generates `Future<T>`, so it can be hooked to Flutter's
`FutureBuilder` for UI. Or you can use `Emitter.asyncData`, which is a creator
of `AsyncData<T>`. AsyncData is similar to AsyncSnapshot for future/stream:

```dart
enum AsyncDataStatus { waiting, active }

class AsyncData<T> {
  const AsyncData._(this.status, this.data);
  const AsyncData.waiting() : this._(AsyncDataStatus.waiting, null);
  const AsyncData.withData(T data) : this._(AsyncDataStatus.active, data);

  final AsyncDataStatus status;
  final T? data;
}
```

With it building widget with `Emitter` is easy:

```dart
Watcher((context, ref, _) {
  final user = ref.watch(userCreator.asyncData).data;
  return user != null ? Text(user!.name) : const CircularProgressIndicator();
});
```

## CreatorGraph

To make creators work, wrap your app in a `CreatorGraph`: 

```dart
void main() {
  runApp(CreatorGraph(child: const MyApp()));
}
```

CreatorGraph is a InheritedWidget. It holds a `Ref` object (which holds the
graph) and exposes it through `context.ref`.

CreatorGraph uses `DefaultCreatorObserver` by default, which prints logs when
creator state changes. It can be replaced with your own log collection observer.

## Watcher

Watcher is a StatefulWidget. It takes builder function `Widget
Function(BuildContext context, Ref ref, Widget child)`. You can use `ref` to
watch creators to populate the widget. `child` can be used optionally if the
subtree should not rebuild when dependency changes:

```dart
Watcher((context, ref, child) {
  final color = ref.watch(userFavoriteColor);
  return Container(color: color, child: child);
}, child: ExpensiveAnimation());  // this child is passed into the builder above
```

## Listen to change

Watching a creator will get its latest state. What if you also want previous
state? Simply call `watch(someCreator.change)` to get a `Change<T>`, which is
an object with two properties `T? before` and `T after`.

For your convenience, `Watcher` can also take a listener:

```dart
// If builder is null, child widget is directly returned. You can set both
// builder and listener. They are independent of each other.
Watcher(null, listener: (ref) {
  final change = ref.watch(number.change);
  print('Number changed from ${change.before} to ${change.after}');
}, child: SomeChildWidget());
```

## Name

Creators can have names for logging purpose. Setting name is recommended for any serious app.

```dart
final numberCreator = Creator.value(0, name: 'number');
final doubleCreator = numberCreator.map((n) => n * 2, name: 'double');
```

## Keep alive

By default, creators are disposed when losing all its watchers. This can be
overridden with `keepAlive` parameter. It is useful if the creator maintains a
connection to backend (e.g. listen to firestore realtime updates).

```dart
final userCreator = Emitter.stream((ref) {
  return FirebaseFirestore.instance.collection('users').doc('123').snapshots();
}, keepAlive: true);
```

## Creator group

Creator group can generate creators with external parameter. For example,
in Instagram app, there might be multiple profile pages on navigation stack,
thus we need multiple instance of `profileCreator`.

```dart
// Instagram has four tabs: instagram, reels, video, tagged
final tabCreator = Creator.arg1<Tab, String>((ref, userId) => 'instagram');
final profileCreator = Emitter.arg1<Profile, String>((ref, userId, emit) async {
  final tab = ref.watch(tabCreator(userId));
  emit(await fetchProfileData(userId, tab));  // Call backend
});

// Now switching tab in user A's profile page will not affect user B.
... ref.watch(profileCreator('userA'));
... ref.set(tabCreator('userA'), 'reels');
```

Creators comes with factory methods `arg1` `arg2` `arg3` which take in 1-3 arguments.

## Extension method

Our favorite part of the framework is that you can use methods like `map`,
`where`, `reduce` on creators (full list [here](https://github.com/terryl1900/creator/blob/master/packages/creator_core/lib/src/extension.dart)). They are similar to those methods in
Iterable or Stream.

```dart
final numberCreator = Creator.value(0);
final oddCreator = numberCreator.where((n) => n.isOdd);
```

Note that `Creator` needs to have valid state at the beginning, while `where((n)
=> n.isOdd)` cannot guarantee that. This is why `where` returns an `Emitter`
rather than a `Creator`. Here is the implementation of the `where` method. It
is quite simple and you can write similar extensions if you want:

```dart
extension CreatorExtension<T> on Creator<T> {
  Emitter<T> where(bool Function(T) test) {
    return Emitter((ref, emit) {
      final value = ref.watch(this);
      if (test(value)) {
        emit(value);
      }
    });
  }
}
```

You can use extension methods in two ways:
```dart
// Define oddCreator explicitly as a stable variable.
final oddCreator = numberCreator.where((n) => n.isOdd);
final someCreator = Creator((ref) {
  return 'this is odd: ${ref.watch(oddCreator)}');
})
```

```dart
// Create "oddCreator" anonymously on the fly.
final someCreator = Creator((ref) {
  return 'this is odd: ${ref.watch(numberCreator.where((n) => n.isOdd))}');
})
```

If you use the "on the fly" approach, please read next section about creator equality.

## Creator equality

The graph checks whether two creators are equal using `==`. This
means creator should be defined in global variables, static variables or any
other ways which can keep variable stable during its life cycle.

What happens if creators are defined in local variables on the fly?

```dart
final text = Creator((ref) {
  final double = Creator((ref) => ref.watch(number) * 2);
  return 'double: ${ref.watch(double)}';
})
```

Here `double` is a local variable, it has different instances whenever `text` is
recreated. The internal graph could change from `number -> double_A -> text` to
`number -> double_B -> text` as the number changes. `text` still generates 
correct data, but there is an extra cost to swap the node in the graph. Because the
change is localized to only one node, the cost can be ignored as long as the
create function is simple.

If needed, an optional `List<Object?> args` can be set to ask the framework to
find an existing creator with the same `args` in the graph. Now when number
changes, the graph won't change:

```dart
final text = Creator((ref) {
  // args need to be globally unique. ['text', 'double'] is likely unique.
  final double = Creator((ref) => ref.watch(number) * 2, args: ['text', 'double']);
  return 'double: ${ref.watch(double)}';
})
```

The same applies to using extension methods on the fly:

```dart
final text = Creator((ref) {
  return 'double: ${ref.watch(number.map((n) => n * 2, args: ['text', 'double']))}';
})
```

Internally, args powers these features:
* Creator group. `profileCreator('userA')` is a creator with args `[profileCreator, 'userA']`.
* Async data. `userCreator.asyncData` is a creator with args `[userCreator, 'asyncData']`.
* Change. `number.change` is a creator with args `[number, 'change']`.

## Service locator

State management libraries are commonly used as service locators:

```dart
class UserRepo {
  void changeName(User user, String name) {...}
}
final userRepo = Creator.value(UserRepo());

... context.ref.read(userRepo).changeName(user, name);
```

If needed, `ref` can be passed to UserRepo  `Creator((ref) => UserRepo(ref))`. 
This allows UserRepo `read` or `set` other creators. Do not `watch` though,
because it will make UserRepo rebuild.

## Error handling

The framework will:
* For `Creator`, store exception happened during create and throw it when watch.
* For `Emitter`, naturally use Future.error, so error is returned when watch. 
* In either case, error is treated as a state change.

This means that errors  can be handled in the most natural way, at the place
makes the most sense. Use the weather app above as an example:

```dart
// Here we don't handle error, meaning it returns Future.error if network error
// occurs. Alternately we can catch network error and return some default value,
// add retry logic, convert network error to our own error class, etc.
final fahrenheitCreator = cityCreator.mapAsync(getFahrenheit);

// Here we choose to handle the error in widget.
Widget build(BuildContext context) {
  return Watcher((context, ref, _) {
    try {
      return Text(ref.watch(temperatureCreator.asyncData).data ?? 'loading');
    } catch (error) {
      return TextButton('Something went wrong, click to retry', 
          onPressed: () => ref.recreate(fahrenheitCreator));
    }
  };
}
```

## Testing

Testing creator is quite easy by combining `watch`, `read`, `set`. Use the weather app above as an example:

```dart
test('temperature creator change unit', () async {
  final ref = Ref();
  expect(await ref.watch(temperatureCreator), "60 F");
  ref.set(unitCreator, 'Celsius');
  await Future.delayed(const Duration()); // allow emitter to propagate
  expect(await ref.watch(temperatureCreator), "16 C");
});

test('temperature creator change fahrenheit value', () async {
  final ref = Ref();
  expect(await ref.watch(temperatureCreator), "60 F");
  ref.set(fahrenheitCreator, Future.value(90));
  await Future.delayed(const Duration()); // allow emitter to propagate
  expect(await ref.watch(temperatureCreator), "90 F");
});
```

# Example

Source code [here](https://github.com/terryl1900/creator/blob/master/packages/creator/example/lib).

## Counter

[DartPad](https://dartpad.dev/?id=911a1919b2b7125cc1f8c69e3c07caf9)

A counter app shows basic Creator/Watcher usage.

## Decremental counter

[DartPad](https://dartpad.dev/?id=1a4c338fdf8ef7c4af8f80ddff88f4ec)

A counter app shows how to hide state and expose state mutate APIs.

## Weather

[DartPad](https://dartpad.dev/?id=344ee052cab2700bd084a78ac6362897)

Simple weather app shows splitting backend/logic/ui code and writing logic
with Creator and Emitter.

## News

[DartPad](https://dartpad.dev/?id=a6d82a6bb955fa4f42ff50b6c6d90d34)

Simple news app with infinite list of news. It shows combining creators
for loading indicator and fetching data with pagination.

## Graph

[DartPad](https://dartpad.dev/?id=77a60e33349a20c6623d163146378c5d)

Simple app shows how the creator framework builds the internal graph dynamically.

# Best practice

Creator is quite flexible and doesn't force a particular style. Best practices
also depend on the project and personal preference. Here we just list a few
things we follow:

* Split code into repo files (backend service call), logic files (creator), and UI files (widget).
* Define creator in global variables.
* Keep creator small for testability. Put derived state in derived creators (using `map`, `where`, etc).


# Read source code

Creator's implementation is surprisingly simple. In fact, the **core logic**
is less than 500 lines of code.

Read creator_core library in this order:

* **[graph.dart](https://github.com/terryl1900/creator/blob/master/packages/creator_core/lib/src/graph.dart)**: a simple implementation of a bi-directed graph using adjacency
list. It can automatically delete nodes which become zero out-degree. 
* **[creator.dart](https://github.com/terryl1900/creator/blob/master/packages/creator_core/lib/src/creator.dart)**: the CreatorBase class and its two sub classes, Creator and Emitter. 
Their main job is to recreate state when asked.
* **[ref.dart](https://github.com/terryl1900/creator/blob/master/packages/creator_core/lib/src/ref.dart)**: manages the graph and provides `watch`, `read`, `set` methods to user. 
* [extension.dart](https://github.com/terryl1900/creator/blob/master/packages/creator_core/lib/src/extension.dart): implement extension methods `map`, `where`, etc.

Read creator library in this order:

* [creator_graph.dart](https://github.com/terryl1900/creator/blob/master/packages/creator/lib/src/creator_graph.dart): A simple InheritedWidget which expose `Ref` through context.
* [watcher.dart](https://github.com/terryl1900/creator/blob/master/packages/creator/lib/src/watcher.dart): A stateful widget which holds a `Creator<Widget>` internally.

# FAQ

## Is it production ready?

Well, we have been using it in production for our own app
([Chooly](https://chooly.app)). However, since it is new to the
community, the API might change as we take feedback. So the suggestion for now:
read the source code and make your own call.

## Is it bad to define creator as global variable?

It's not. Creator itself doesn't hold states. States are held in Ref (in
CreatorGraph). Defining a creator is more like defining a function or a class.

## How to watch a property while still accessing the whole object?

```dart
final someCreator = Creator((ref) {
  ref.watch(userCreator.map((user) => user.email));
  final user = ref.read(userCreator);
  return '${user.name}\'s email is changed';
});
```

## How does creator's life cycle work?

* It is added to the graph when firstly being watched.
* It can be removed from the graph manually by `Ref.dispose`.
* If it has watchers, it is automatically removed from the graph when losing all its
watchers, unless keepAlive property is set.

## What's the difference between `context.ref` vs `ref` in `Creator((ref) => ...)`?

They both point to the same internal graph, the only difference is that the
first ref's `_owner` field is null, while the second ref's `_owner` field is the
creator itself. This means:
* It is the same to `read`, `set` or `update` any creators with either ref. The operation is
passed to the internal graph.
* If `ref._owner` is null, `ref.watch(foo)` will simply add `foo` to the graph. 
* If `ref._owner` is not null, `ref.watch(foo)` will also add an edge `foo -> ref._owner` to the graph.

## What's the difference between `Creator<Future<T>>` vs `Emitter<T>`?

They are both extended from `CreatorBase<Future<T>>`, whose state is 
`Future<T>`. However, there are two important differences, which make
`Emitter<T>` better for async tasks:
* `Emitter<T>` stores `T` in addition to `Future<T>`, so that we can log change
of `T` or populate `AsyncData<T>` properly. 
* `Emitter<T>` notify its watcher when `T` is emitted, so its watchers can start 
their work immediately. `Creator<Future<T>>` notify its watchers when the future 
is started, so its watchers are still blocked until the future is finished. 

# That's it
Hope you enjoyed reading this doc and will enjoy using Creator. Feedback and
contribution are welcome!

If you use Creator in your app, let us know your experience (positive or negative).
Create a Github issue or email terry@chooly.app .
