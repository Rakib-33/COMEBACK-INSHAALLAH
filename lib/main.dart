import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app_theme.dart';
import 'controllers/app_controller.dart';
import 'routes/app_pages.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TargetFinalApp());
}

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(AppController(), permanent: true);
  }
}

class TargetFinalApp extends StatelessWidget {
  const TargetFinalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Target Final',
      debugShowCheckedModeBanner: false,
      initialBinding: InitialBinding(),
      theme: AppTheme.dark(),
      initialRoute: AppRoutes.sync,
      getPages: AppPages.routes,
    );
  }
}
