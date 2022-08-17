import 'package:creator/creator.dart';
import 'package:example_starter/logic/auth_logic.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'url.dart';
import 'widget/home_screen.dart';
import 'widget/login_screen.dart';
import 'widget/splash_screen.dart';

/// Notifier bridges creator with go_router.
class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this._ref) {
    /// RouterNotifier will not rebuild since _listener always generate a void.
    _ref.watch(_listener);
  }

  final Ref _ref;

  /// _listener will rebuild when login user changes and notifier go_router.
  late final _listener = Creator((ref) {
    ref.watch(userCreator);
    notifyListeners();
  }, name: 'routerNotifier');
}

/// go_router creator.
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
