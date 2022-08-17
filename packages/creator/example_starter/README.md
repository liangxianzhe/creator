# Starter

A minimum template to structure a flutter project using:
* go_router for routing.
* creator for state management.
* (optional) Firebase Auth for login.

It set up the structure to split your code into:
* Repo layer: data models and API calls.
* Logic layer: controllers or view models.
* View layer: all the widgets.

It is simple:
* No unnecessary logic, so you can just copy and use it for new project.
* Or just browse the code and apply to existing project.

## Getting Started

1. You should create new project using `flutter create` to leverage new Flutter features:
```
flutter create my_fancy_app
```

2. Add dependencies:
```
cd my_fancy_app
flutter pub add go_router
flutter pub add creator
```

3. Delete the default counter app file `lib/main.dart` and `test/widget_test.dart`.

4. Copy all files from this example's `lib` folder to your app's `lib` folder.

5. You are good to go. Run the app and start making your fancy app!

```
flutter run
```

6. [Optional] To use Firebase Auth, follow comments in `lib/logic/auth_logic.dart`.

## What the template does

It is better to just browse the source code. But here is what it does:

1. Defines a few basic urls.
```dart
/// Allowed urls. Enum is safer than strings.
enum Url {
  home('/'),
  login('/login'),
  setting('/setting'),
  splash('/splash'),
  ;

  final String url;
  const Url(this.url);
}
```

2. Manages auth state using creator.
```dart
/// Get user id of the current login user.
final userCreator = Emitter<String?>((ref, emit) async {
  await Future.delayed(const Duration(milliseconds: 100));
  // Depends on how you store user's session, fetch the session data.
  // Here let's assume there is no login user.
  emit(null);
}, name: 'user', keepAlive: true);

/// Login a user using email and password. Change to whatever login method you
/// use.
void login(Ref ref, String email, String password) async {
  await Future.delayed(const Duration(milliseconds: 100));
  ref.emit(userCreator, 'user_$email');
}
```

3. Builds a basic router that uses auth state for redirection.
```dart
final goRouter = Creator((ref) {
  return GoRouter(
    initialLocation: Url.splash.url,
    urlPathStrategy: UrlPathStrategy.path, // Hide '#' from url
    routes: <GoRoute>[
      GoRoute(path: Url.home.url, builder: (_, __) => const HomeScreen()),
      GoRoute(path: Url.login.url, builder: (_, __) => const LoginScreen()),
      GoRoute(path: Url.splash.url, builder: (_, __) => const SplashScreen()),
    ],
    redirect: (state) {
      /// Still checking whether there is a login user.
      if (ref.read(userCreator.asyncData).status == AsyncDataStatus.waiting) {
        return state.location != Url.splash.url ? Url.splash.url : null;
      }

      // There is no login user, let's redirect to login page.
      //
      // Note here we read instead of watch, so we don't rebuild this creator
      // when login user changes. We rely on refreshListenable to do the work.
      if (ref.read(userCreator.asyncData).data == null) {
        return state.location != Url.login.url ? Url.login.url : null;
      }

      return state.location == Url.login.url ? Url.home.url : null;
    },
    // go_counter will re-route whenever this notifier fires.
    refreshListenable: RouterNotifier(ref),
  );
}, name: 'goRouter', keepAlive: true);
```

4. Provides minimum sample of data model, API calls and async rendering. 
```dart
/// An example data model
class Counter {
  const Counter(this.count);
  final int count;
}

/// Fetch the user's counter from server. Fake the logic for now.
Future<Counter> fetchCounter(String userId) async {
  await Future.delayed(const Duration(milliseconds: 500));
  return const Counter(42);
}

class CounterView extends StatelessWidget {
  const CounterView({super.key});

  @override
  Widget build(BuildContext context) {
    return Watcher((context, ref, _) {
      final counter = ref.watch(counterCreator.asyncData).data;
      if (counter == null) {
        return const CircularProgressIndicator();
      }
      return Text('Counter: ${counter.count}');
    });
  }
}
```