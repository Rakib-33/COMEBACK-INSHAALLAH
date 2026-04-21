import 'package:get/get.dart';

import '../views/course_target_screen.dart';
import '../views/dashboard_screen.dart';
import '../views/sync_screen.dart';

class AppRoutes {
  static const sync = '/';
  static const dashboard = '/dashboard';
  static const course = '/course';
}

class AppPages {
  AppPages._();

  static final routes = <GetPage<dynamic>>[
    GetPage(name: AppRoutes.sync, page: () => const SyncScreen()),
    GetPage(name: AppRoutes.dashboard, page: () => const DashboardScreen()),
    GetPage(
      name: '${AppRoutes.course}/:id',
      page: () {
        final id = Get.parameters['id'] ?? '';
        return CourseTargetScreen(courseId: id);
      },
    ),
  ];
}
