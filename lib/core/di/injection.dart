import 'package:get_it/get_it.dart';
import '../../services/native_bridge_service.dart';
import '../../services/storage_service.dart';
import '../../services/task_queue_service.dart';
import '../../services/template_engine_service.dart';

final GetIt getIt = GetIt.instance;

Future<void> setupDependencyInjection() async {
  // 1. Core Storage Service (Hive)
  final storageService = StorageService();
  await storageService.init();
  getIt.registerSingleton<StorageService>(storageService);

  // 2. Native Bridge Service (Platform Channels & Stream)
  final nativeBridgeService = NativeBridgeService();
  await nativeBridgeService.initEngine();
  getIt.registerSingleton<NativeBridgeService>(nativeBridgeService);

  // 3. Template Engine Service (CLI synthesis)
  getIt.registerLazySingleton<TemplateEngineService>(
    () => TemplateEngineService(),
  );

  // 4. Task Queue Service (Download queue & concurrency)
  getIt.registerSingleton<TaskQueueService>(
    TaskQueueService(
      storageService: getIt<StorageService>(),
      nativeBridgeService: getIt<NativeBridgeService>(),
    ),
  );
}
