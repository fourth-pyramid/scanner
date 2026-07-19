import 'package:get_it/get_it.dart';
import 'package:qrscanner/core/dioHelper/dio_helper.dart';
import 'package:qrscanner/core/network/network_info.dart';
import 'package:qrscanner/core/ocr/card_scan_ocr_service.dart';
// Card Scanner Feature
import 'package:qrscanner/features/card_scanner/data/datasources/card_scanner_remote_datasource.dart';
import 'package:qrscanner/features/card_scanner/data/repositories/card_scanner_repository_impl.dart';
import 'package:qrscanner/features/card_scanner/domain/repositories/card_scanner_repository.dart';
import 'package:qrscanner/features/card_scanner/domain/usecases/clear_data_usecase.dart';
import 'package:qrscanner/features/card_scanner/presentation/bloc/card_scanner_bloc.dart';
// Card Type Feature
import 'package:qrscanner/features/card_type/data/datasources/card_type_remote_datasource.dart';
import 'package:qrscanner/features/card_type/data/repositories/card_type_repository_impl.dart';
import 'package:qrscanner/features/card_type/domain/repositories/card_type_repository.dart';
import 'package:qrscanner/features/card_type/domain/usecases/get_categories_usecase.dart';
// ponytail: removed ClearDataUseCase import
import 'package:qrscanner/features/card_type/presentation/bloc/card_type_bloc.dart';
// Extract Image Feature
import 'package:qrscanner/features/extract_image/data/datasources/extract_image_remote_datasource.dart';
import 'package:qrscanner/features/extract_image/data/repositories/extract_image_repository_impl.dart';
import 'package:qrscanner/features/extract_image/domain/repositories/extract_image_repository.dart';
import 'package:qrscanner/features/extract_image/domain/usecases/get_history_count_usecase.dart';
import 'package:qrscanner/features/extract_image/domain/usecases/process_image_usecase.dart';
import 'package:qrscanner/features/extract_image/domain/usecases/submit_scan_usecase.dart';
import 'package:qrscanner/features/extract_image/presentation/bloc/extract_image_bloc.dart';
// Login Feature
import 'package:qrscanner/features/login/data/datasources/login_remote_datasource.dart';
import 'package:qrscanner/features/login/data/repositories/login_repository_impl.dart';
import 'package:qrscanner/features/login/domain/repositories/login_repository.dart';
import 'package:qrscanner/features/login/domain/usecases/login_usecase.dart';
import 'package:qrscanner/features/login/presentation/bloc/login_bloc.dart';
// Saved Data Feature
import 'package:qrscanner/features/saved_data/data/datasources/saved_data_remote_datasource.dart';
import 'package:qrscanner/features/saved_data/data/repositories/saved_data_repository_impl.dart';
import 'package:qrscanner/features/saved_data/domain/repositories/saved_data_repository.dart';
import 'package:qrscanner/features/saved_data/domain/usecases/get_saved_scans_usecase.dart';
import 'package:qrscanner/features/saved_data/presentation/bloc/saved_data_bloc.dart';
// Settings Feature
import 'package:qrscanner/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:qrscanner/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:qrscanner/features/settings/domain/repositories/settings_repository.dart';
import 'package:qrscanner/features/settings/domain/usecases/get_settings_usecase.dart';
import 'package:qrscanner/features/settings/domain/usecases/save_settings_usecase.dart';
// ponytail: removed GetWifiIpUseCase import
import 'package:qrscanner/features/settings/presentation/bloc/settings_bloc.dart';

/// Global service locator instance
final getIt = GetIt.instance;

/// Initializes all dependencies
/// Call this in main.dart before runApp
Future<void> initDependencies() async {
  // Initialize core dependencies
  _initCore();

  // Initialize feature dependencies
  _initCardScannerFeature();
  _initExtractImageFeature();
  _initLoginFeature();
  _initCardTypeFeature();
  _initSavedDataFeature();
  _initSettingsFeature();
}

/// Initialize core layer dependencies
void _initCore() {
  // External
  getIt
    ..registerLazySingleton(() => DioHelper)
    ..registerLazySingleton<NetworkInfo>(NetworkInfoImpl.new);
}

/// Initialize extract_image feature dependencies
void _initExtractImageFeature() {
  getIt
    ..registerLazySingleton(
      () => CardScanOcrService(pinOcrEngine: OcrEngineFactory.createPinEngine()),
    )
    ..registerLazySingleton<ExtractImageRemoteDataSource>(ExtractImageRemoteDataSourceImpl.new)
    ..registerLazySingleton<ExtractImageRepository>(
      () => ExtractImageRepositoryImpl(remoteDataSource: getIt(), cardScanOcrService: getIt(), networkInfo: getIt()),
    )
    // Use Cases
    ..registerLazySingleton(() => ProcessImageUseCase(repository: getIt()))
    ..registerLazySingleton(() => SubmitScanUseCase(repository: getIt()))
    ..registerLazySingleton(() => GetHistoryCountUseCase(repository: getIt()))
    // Bloc - Factory because each screen needs its own instance
    ..registerFactory(
      () => ExtractImageBloc(processImageUseCase: getIt(), submitScanUseCase: getIt(), getHistoryCountUseCase: getIt()),
    );
}

/// Initialize login feature dependencies
void _initLoginFeature() {
  // Data Sources
  getIt
    ..registerLazySingleton<LoginRemoteDataSource>(LoginRemoteDataSourceImpl.new)
    // Repositories
    ..registerLazySingleton<LoginRepository>(() => LoginRepositoryImpl(remoteDataSource: getIt(), networkInfo: getIt()))
    // Use Cases
    ..registerLazySingleton(() => LoginUseCase(repository: getIt()))
    // Bloc - Factory because each screen needs its own instance
    ..registerFactory(() => LoginBloc(loginUseCase: getIt()));
}

/// Initialize card_type feature dependencies
void _initCardTypeFeature() {
  // Data Sources
  getIt
    ..registerLazySingleton<CardTypeRemoteDataSource>(CardTypeRemoteDataSourceImpl.new)
    // Repositories
    ..registerLazySingleton<CardTypeRepository>(
      () => CardTypeRepositoryImpl(remoteDataSource: getIt(), networkInfo: getIt()),
    )
    // Use Cases
    ..registerLazySingleton(() => GetCategoriesUseCase(repository: getIt()))
    // Bloc - Factory because each screen needs its own instance
    ..registerFactory(() => CardTypeBloc(getCategoriesUseCase: getIt()));
}

/// Initialize saved_data feature dependencies
void _initSavedDataFeature() {
  // Data Sources
  getIt
    ..registerLazySingleton<SavedDataRemoteDataSource>(SavedDataRemoteDataSourceImpl.new)
    // Repositories
    ..registerLazySingleton<SavedDataRepository>(
      () => SavedDataRepositoryImpl(remoteDataSource: getIt(), networkInfo: getIt()),
    )
    // Use Cases
    ..registerLazySingleton(() => GetSavedScansUseCase(repository: getIt()))
    // Bloc - Factory because each screen needs its own instance
    ..registerFactory(() => SavedDataBloc(getSavedScansUseCase: getIt()));
}

/// Initialize settings feature dependencies
void _initSettingsFeature() {
  // Data Sources
  getIt
    ..registerLazySingleton<SettingsLocalDataSource>(SettingsLocalDataSourceImpl.new)
    // Repositories
    ..registerLazySingleton<SettingsRepository>(() => SettingsRepositoryImpl(localDataSource: getIt()))
    // Use Cases
    ..registerLazySingleton(() => GetSettingsUseCase(repository: getIt()))
    ..registerLazySingleton(() => SaveSettingsUseCase(repository: getIt()))
    // Bloc - Factory because each screen needs its own instance
    ..registerFactory(() => SettingsBloc(getSettingsUseCase: getIt(), saveSettingsUseCase: getIt()));
}

/// Initialize card_scanner feature dependencies
void _initCardScannerFeature() {
  getIt
    ..registerLazySingleton<CardScannerRemoteDataSource>(CardScannerRemoteDataSourceImpl.new)
    ..registerLazySingleton<CardScannerRepository>(
      () => CardScannerRepositoryImpl(remoteDataSource: getIt(), networkInfo: getIt()),
    )
    ..registerLazySingleton(() => ClearDataUseCase(repository: getIt()))
    ..registerFactory(() => CardScannerBloc(clearDataUseCase: getIt()));
}
