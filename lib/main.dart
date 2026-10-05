import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_styles.dart';
import 'core/di/injection.dart';
import 'controllers/download_controller.dart';
import 'controllers/search_format_controller.dart';
import 'controllers/settings_controller.dart';
import 'controllers/template_controller.dart';
import 'views/root_navigation_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure Android system navigation and status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.surface,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize Hive storage, native bridge, and dependency injection
  await setupDependencyInjection();

  runApp(const RamenApp());
}

class RamenApp extends StatelessWidget {
  const RamenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SearchFormatController()),
        ChangeNotifierProvider(create: (_) => DownloadController()),
        ChangeNotifierProvider(create: (_) => TemplateController()),
        ChangeNotifierProvider(create: (_) => SettingsController()),
      ],
      child: MaterialApp(
        title: 'Ramen',
        debugShowCheckedModeBanner: false,
        theme: AppStyles.darkTheme,
        home: const RootNavigationView(),
      ),
    );
  }
}
