import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/theme_controller.dart';
import 'features/auth/presentation/auth_controller.dart';
import 'features/discovery/presentation/discovery_controller.dart';
import 'features/groups/presentation/group_controller.dart';
import 'features/user/presentation/user_controller.dart';

List<ChangeNotifierProvider> providers = [
  ChangeNotifierProvider<AuthController>(
    create: (_) => AuthController(),
  ),
  ChangeNotifierProvider<UserController>(
    create: (_) => UserController(),
  ),
  ChangeNotifierProvider<DiscoveryController>(
    create: (_) => DiscoveryController(),
  ),
  ChangeNotifierProvider<GroupController>(
    create: (_) => GroupController(),
  ),
  ChangeNotifierProvider(create: (_)=>ThemeController()),

];
