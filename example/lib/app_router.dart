import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import 'ui/pages/create_user_page.dart';
import 'ui/pages/home_page.dart';
import 'ui/pages/user_details_page.dart';

part 'app_router.gr.dart';

@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
        // Home route
        AutoRoute(
          page: HomeRoute.page,
          path: '/',
          initial: true,
        ),

        // User details route
        AutoRoute(
          page: UserDetailsRoute.page,
          path: '/user/:userId',
        ),

        // Create user route
        AutoRoute(
          page: CreateUserRoute.page,
          path: '/create-user',
        ),
      ];
}
