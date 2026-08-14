import 'dart:io';

Future<void> main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    _printHelp();
    return;
  }

  final config = ProjectConfig.fromArgs(args);
  Logger.colorEnabled = config.colorOutput;
  Logger.verboseEnabled = config.verbose;

  final stopwatch = Stopwatch()..start();
  Logger.info(" Starting Enhanced Dart Riverpod Project Structure Setup...\n");

  if (!config.dryRun) {
    if (!Directory("lib").existsSync()) {
      Logger.error(
        " 'lib' folder not found. Run this from your Flutter project root. Script terminated.",
      );
      exit(1);
    }
    if (!File("pubspec.yaml").existsSync()) {
      Logger.error(
        " 'pubspec.yaml' not found. This doesn't look like a Flutter/Dart project root.",
      );
      exit(1);
    }
  } else {
    Logger.warn(
      "🧪 Dry-run mode enabled — no files or folders will actually be written.\n",
    );
  }

  final setupManager = ProjectSetupManager(config);

  try {
    await setupManager.setup();
    stopwatch.stop();
    Logger.success(
      "\n Project setup completed successfully in ${_formatDuration(stopwatch.elapsed)}!",
    );
    Logger.info("\n Next steps:");
    Logger.info("   1. Run: flutter pub get");
    Logger.info(
      "   2. (Optional) If you use Hive models with @HiveType, run:",
    );
    Logger.info(
      "      dart run build_runner build --delete-conflicting-outputs",
    );
    Logger.info(
      "   3. Open lib/core/di/core_providers.dart and add any app-wide providers",
    );
    Logger.info(
      "   4. Open lib/core/router/app_router.dart and add your onGenerateRoute cases",
    );
    Logger.info(
      "   5. Check README.md and ARCHITECTURE.md for full project structure details",
    );
  } catch (e, stackTrace) {
    stopwatch.stop();
    Logger.error(
      "\n Setup failed after ${_formatDuration(stopwatch.elapsed)}: $e",
    );
    if (config.verbose) Logger.error("Stack trace:\n$stackTrace");

    if (config.rollbackOnFailure && !config.dryRun) {
      Logger.warn("\n↩  Rolling back changes made during this run...");
      await setupManager.rollback();
      Logger.warn("Rollback complete.");
    } else if (!config.dryRun) {
      Logger.warn(
        "\nTip: re-run with --rollback to automatically undo partial changes on failure.",
      );
    }
    exit(1);
  }
}

String _formatDuration(Duration d) {
  final seconds = d.inMilliseconds / 1000;
  return "${seconds.toStringAsFixed(2)}s";
}

void _printHelp() {
  print("""
Enhanced Dart Riverpod Project Structure Setup
-------------------------------------------
Scaffolds Clean Architecture + Riverpod (state management + DI).

Usage:
  dart run setup_project_riverpod.dart [options]

Options:
  -v, --verbose        Print detailed logs for every file/folder action
      --overwrite       Overwrite existing files instead of skipping them
      --no-sample       Skip generating the sample "auth" feature
      --ci              Generate a GitHub Actions CI workflow
      --no-analysis     Skip generating analysis_options.yaml
      --dry-run         Show what would be created without writing anything
      --no-pub-upgrade  Skip running flutter pub get / pub upgrade after setup
      --no-update-pubspec  Skip merging required dependencies into pubspec.yaml
      --no-color        Disable ANSI colored console output
      --rollback        Automatically delete created files/folders if setup fails
  -h, --help            Show this help message
""");
}

class Logger {
  static bool colorEnabled = true;
  static bool verboseEnabled = false;

  static const _reset = '\x1B[0m';
  static const _red = '\x1B[31m';
  static const _green = '\x1B[32m';
  static const _yellow = '\x1B[33m';
  static const _cyan = '\x1B[36m';
  static const _gray = '\x1B[90m';

  static void _print(String msg, String color) {
    print(colorEnabled ? "$color$msg$_reset" : msg);
  }

  static void info(String msg) => _print(msg, _cyan);
  static void success(String msg) => _print(msg, _green);
  static void warn(String msg) => _print(msg, _yellow);
  static void error(String msg) => _print(msg, _red);
  static void debug(String msg) {
    if (verboseEnabled) _print("  $msg", _gray);
  }
}

class ProjectConfig {
  final bool verbose;
  final bool skipExisting;
  final bool createSampleFeature;
  final bool setupCI;
  final bool setupAnalysis;
  final bool dryRun;
  final bool updatePubspec;
  final bool runPubCommands;
  final bool colorOutput;
  final bool rollbackOnFailure;

  ProjectConfig({
    this.verbose = false,
    this.skipExisting = true,
    this.createSampleFeature = true,
    this.setupCI = false,
    this.setupAnalysis = true,
    this.dryRun = false,
    this.updatePubspec = true,
    this.runPubCommands = true,
    this.colorOutput = true,
    this.rollbackOnFailure = false,
  });

  factory ProjectConfig.fromArgs(List<String> args) {
    return ProjectConfig(
      verbose: args.contains('--verbose') || args.contains('-v'),
      skipExisting: !args.contains('--overwrite'),
      createSampleFeature: !args.contains('--no-sample'),
      setupCI: args.contains('--ci'),
      setupAnalysis: !args.contains('--no-analysis'),
      dryRun: args.contains('--dry-run'),
      updatePubspec: !args.contains('--no-update-pubspec'),
      runPubCommands: !args.contains('--no-pub-upgrade'),
      colorOutput: !args.contains('--no-color'),
      rollbackOnFailure: args.contains('--rollback'),
    );
  }
}

class ProjectSetupManager {
  final ProjectConfig config;
  final String projectName;

  int foldersCreated = 0;
  int filesCreated = 0;
  int skipped = 0;

  final List<_CreatedEntry> _created = [];

  ProjectSetupManager(this.config)
    : projectName = Directory.current.path.split(Platform.pathSeparator).last;

  Future<void> setup() async {
    await _setupCoreStructure();
    await _setupDiAndRouting();
    await _setupFeaturesStructure();
    await _setupAssets();
    await _setupConfigFiles();

    if (config.createSampleFeature) {
      await _createSampleFeature();
    }

    if (config.setupCI) {
      await _setupCI();
    }

    if (config.setupAnalysis) {
      await _setupAnalysisOptions();
    }

    await _generateDocumentation();

    if (config.updatePubspec) {
      await _mergePubspecDependencies();
    } else {
      Logger.debug(
        "skipping pubspec.yaml dependency merge (--no-update-pubspec)",
      );
    }

    if (config.runPubCommands && !config.dryRun) {
      await _runPubCommands();
    }

    if (!config.dryRun) {
      await _writeSetupSummaryJson();
    }

    _printSummary();
  }

  Future<void> _setupCoreStructure() async {
    Logger.info("\n Setting up core structure...");

    final coreStructure = <String, List<String>>{
      "lib/core/cache": ["store_cache.dart", "cache_manager.dart"],
      "lib/core/common/app": ["cache_helper.dart", "app_state_providers.dart"],
      "lib/core/common/entity": ["base_entity.dart"],
      "lib/core/common/models": ["base_model.dart"],
      "lib/core/common/singleton": ["cache.dart"],
      "lib/core/common/widgets": [
        "adaptive_icons.dart",
        "adaptive_loading_widget.dart",
        "adaptive_custom_shimmer.dart",
        "custom_text_button.dart",
        "dynamic_appbar.dart",
        "dynamic_loading_widget.dart",
        "primary_button.dart",
        "custom_textfields.dart",
        "error_view.dart",
        "empty_state.dart",
      ],
      "lib/core/error": ["exception.dart", "failure.dart"],
      "lib/core/extensions": [
        "context_extensions.dart",
        "string_extensions.dart",
        "text_extensions.dart",
        "theme_extensions.dart",
        "widget_extensions.dart",
        "date_time_extensions.dart",
        "list_extensions.dart",
      ],
      "lib/core/network": [
        "network_client.dart",
        "network_info.dart",
        "api_endpoints.dart",
        "interceptors.dart",
      ],
      "lib/core/res/styles": ["colors.dart", "text.dart", "themes.dart"],
      "lib/core/res": ["media.dart", "strings.dart"],
      "lib/core/service": ["codec.dart", "navigation_helper.dart"],
      "lib/core/usecase": ["usecase.dart"],
      "lib/core/utils": [
        "core_utils.dart",
        "date_time_formatter.dart",
        "error_response.dart",
        "hero_key_generator.dart",
        "image_preloader.dart",
        "lifecycle_event_handler.dart",
        "responsive.dart",
        "typedefs.dart",
        "validators.dart",
        "logger.dart",
      ],
      "lib/core/utils/constants": [
        "endpoint.dart",
        "network_constants.dart",
        "app_constants.dart",
      ],
    };

    for (final entry in coreStructure.entries) {
      await _createFolder(entry.key);
      for (final file in entry.value) {
        await _createFile(
          "${entry.key}/$file",
          content: _generateFileContent(file),
        );
      }
    }
  }

  Future<void> _setupDiAndRouting() async {
    Logger.info(
      "\n Setting up DI (Riverpod providers) and routing (Navigator + onGenerateRoute)...",
    );

    await _createFolder("lib/core/di");
    await _createFile(
      "lib/core/di/core_providers.dart",
      content: _coreProvidersContent(),
    );

    await _createFolder("lib/core/router");
    await _createFile(
      "lib/core/router/app_routes.dart",
      content: _appRoutesContent(),
    );
    await _createFile(
      "lib/core/router/app_router.dart",
      content: _appRouterContent(),
    );

    await _createFolder("lib/core/router/guards");
    await _createFile(
      "lib/core/router/guards/auth_guard.dart",
      content: _authGuardContent(),
    );
    await _createFile(
      "lib/core/router/guards/guest_guard.dart",
      content: _guestGuardContent(),
    );
  }

  Future<void> _setupFeaturesStructure() async {
    Logger.info("\n Setting up features structure...");

    await _createFolder("lib/src/features");
    await _createFile(
      "lib/src/features/README.md",
      content: _featureReadmeContent(),
    );
  }

  Future<void> _setupAssets() async {
    Logger.info("\n Setting up assets...");

    final assetFolders = [
      "assets/images",
      "assets/icons",
      "assets/fonts",
      "assets/lottie",
      "assets/videos",
      "assets/audio",
      "assets/animations",
    ];

    for (final folder in assetFolders) {
      await _createFolder(folder);
      await _createFile(
        "$folder/.gitkeep",
        content: "# Keep this folder in version control\n",
      );
    }
  }

  Future<void> _setupConfigFiles() async {
    Logger.info("\n Setting up configuration files...");

    await _createFile(
      "dependency_requirements.txt",
      content: _dependenciesContent(),
    );
    await _createFolder("lib/core/config");
    await _createFile(
      "lib/core/config/env_config.dart",
      content: _envConfigContent(),
    );
    await _createFile(".env.example", content: _envExampleContent());
    await _appendToGitignore();
    await _setupMyApp();
    await _setupWidgetTest();
  }

  Future<void> _createSampleFeature() async {
    Logger.info("\n Creating sample feature (auth)...");

    const featurePath = "lib/src/features/auth";
    final featureStructure = <String, List<String>>{
      "$featurePath/data/datasources": [
        "auth_remote_datasource.dart",
        "auth_local_datasource.dart",
      ],
      "$featurePath/data/models": ["user_model.dart"],
      "$featurePath/data/repositories": ["auth_repository_impl.dart"],
      "$featurePath/domain/entities": ["user.dart"],
      "$featurePath/domain/repositories": ["auth_repository.dart"],
      "$featurePath/domain/usecases": ["login_user.dart", "logout_user.dart"],
      "$featurePath/presentation/controllers": [
        "auth_state.dart",
        "auth_controller.dart",
      ],
      "$featurePath/presentation/providers": ["auth_providers.dart"],
      "$featurePath/presentation/views": [
        "login_screen.dart",
        "home_screen.dart",
      ],
      "$featurePath/presentation/widgets": ["login_form.dart"],
    };

    for (final entry in featureStructure.entries) {
      await _createFolder(entry.key);
      for (final file in entry.value) {
        await _createFile(
          "${entry.key}/$file",
          content: _generateFeatureFileContent(file),
        );
      }
    }
  }

  Future<void> _setupCI() async {
    Logger.info("\nSetting up CI/CD...");
    await _createFolder(".github/workflows");
    await _createFile(
      ".github/workflows/flutter_ci.yml",
      content: _githubActionsContent(),
    );
  }

  Future<void> _setupAnalysisOptions() async {
    Logger.info("\n Setting up analysis options...");
    await _createFile(
      "analysis_options.yaml",
      content: _analysisOptionsContent(),
    );
  }

  Future<void> _generateDocumentation() async {
    Logger.info("\n Generating documentation...");
    await _createFile("README.md", content: _readmeContent());
    await _createFile("ARCHITECTURE.md", content: _architectureContent());
  }

  Future<void> _createFolder(String path) async {
    final dir = Directory(path);
    if (dir.existsSync()) {
      skipped++;
      Logger.debug("⊘ Folder exists: $path");
      return;
    }

    if (config.dryRun) {
      foldersCreated++;
      Logger.debug("would create folder: $path");
      return;
    }

    dir.createSync(recursive: true);
    foldersCreated++;
    _created.add(_CreatedEntry(path: path, isDirectory: true));
    Logger.debug("✓ Created folder: $path");
  }

  Future<void> _createFile(String path, {String content = ""}) async {
    final file = File(path);
    final exists = file.existsSync();

    if (exists && config.skipExisting) {
      skipped++;
      Logger.debug("⊘ File exists: $path");
      return;
    }

    if (config.dryRun) {
      filesCreated++;
      Logger.debug("would ${exists ? 'overwrite' : 'create'} file: $path");
      return;
    }

    final isNew = !exists;
    file.createSync(recursive: true);
    await file.writeAsString(content);
    filesCreated++;
    if (isNew) _created.add(_CreatedEntry(path: path, isDirectory: false));
    Logger.debug("✓ ${isNew ? 'Created' : 'Overwrote'} file: $path");
  }

  Future<void> rollback() async {
    for (final entry in _created.reversed) {
      try {
        if (entry.isDirectory) {
          final dir = Directory(entry.path);
          if (dir.existsSync() && dir.listSync().isEmpty) {
            dir.deleteSync();
            Logger.debug("removed folder: ${entry.path}");
          }
        } else {
          final file = File(entry.path);
          if (file.existsSync()) {
            file.deleteSync();
            Logger.debug("removed file: ${entry.path}");
          }
        }
      } catch (e) {
        Logger.warn("Could not remove ${entry.path}: $e");
      }
    }
  }

  Future<void> _runPubCommands() async {
    Logger.info("\n Fetching dependencies...");
    try {
      final getResult = await Process.run('flutter', ['pub', 'get']);
      if (getResult.exitCode == 0) {
        Logger.success("✓ flutter pub get completed.");
      } else {
        Logger.warn("⚠ flutter pub get failed: ${getResult.stderr}");
        return;
      }

      final upgradeResult = await Process.run('flutter', ['pub', 'upgrade']);
      if (upgradeResult.exitCode == 0) {
        Logger.success("✓ Dependencies upgraded successfully.");
      } else {
        Logger.warn("⚠ flutter pub upgrade failed: ${upgradeResult.stderr}");
      }
    } on ProcessException catch (e) {
      Logger.warn(
        "⚠ Could not run flutter commands (is Flutter on your PATH?): ${e.message}",
      );
    }
  }

  Future<void> _mergePubspecDependencies() async {
    Logger.info(
      "\n Checking pubspec.yaml and merging required dependencies...",
    );

    final pubspec = File("pubspec.yaml");
    if (!pubspec.existsSync()) {
      Logger.warn("⚠ pubspec.yaml not found, skipping merge.");
      return;
    }

    const deps = <String, String>{
      'flutter_riverpod': '^2.5.1',
      'equatable': '^2.0.5',
      'dartz': '^0.10.1',
      'dio': '^5.4.3',
      'connectivity_plus': '^6.0.3',
      'hive': '^2.2.3',
      'hive_flutter': '^1.1.0',
      'shared_preferences': '^2.2.3',
      'cached_network_image': '^3.3.1',
      'shimmer': '^3.0.0',
      'flutter_svg': '^2.0.10',
      'intl': '^0.19.0',
      'logger': '^2.3.0',
    };

    const devDeps = <String, String>{
      'build_runner': '^2.4.11',
      'hive_generator': '^2.0.1',
      'flutter_lints': '^4.0.0',
      'mocktail': '^1.0.4',
    };

    if (config.dryRun) {
      Logger.debug(
        "would merge ${deps.length} dependencies and ${devDeps.length} dev dependencies into pubspec.yaml",
      );
      return;
    }

    final lines = await pubspec.readAsLines();
    final addedDeps = <String>{};
    final addedDevDeps = <String>{};

    final finalLines = <String>[];
    var sawDependencies = false;
    var sawDevDependencies = false;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      finalLines.add(line);
      final trimmed = line.trimRight();

      if (trimmed == 'dependencies:') {
        sawDependencies = true;
        for (final e in deps.entries) {
          final already = lines.any((l) => l.trim().startsWith('${e.key}:'));
          if (!already) {
            finalLines.add('  ${e.key}: ${e.value}');
            addedDeps.add(e.key);
          }
        }
      } else if (trimmed == 'dev_dependencies:') {
        sawDevDependencies = true;
        for (final e in devDeps.entries) {
          final already = lines.any((l) => l.trim().startsWith('${e.key}:'));
          if (!already) {
            finalLines.add('  ${e.key}: ${e.value}');
            addedDevDeps.add(e.key);
          }
        }
      }
    }

    if (!sawDependencies) {
      finalLines.add('dependencies:');
      for (final e in deps.entries) {
        finalLines.add('  ${e.key}: ${e.value}');
        addedDeps.add(e.key);
      }
    }
    if (!sawDevDependencies) {
      finalLines.add('dev_dependencies:');
      for (final e in devDeps.entries) {
        finalLines.add('  ${e.key}: ${e.value}');
        addedDevDeps.add(e.key);
      }
    }

    if (addedDeps.isEmpty && addedDevDeps.isEmpty) {
      Logger.info(
        "Nothing to merge — all required dependencies already present in pubspec.yaml.",
      );
      return;
    }

    await pubspec.writeAsString(finalLines.join('\n') + '\n');

    if (addedDeps.isNotEmpty) {
      Logger.success(
        "✓ Added ${addedDeps.length} dependencies to pubspec.yaml: ${addedDeps.join(', ')}",
      );
    }
    if (addedDevDeps.isNotEmpty) {
      Logger.success(
        "✓ Added ${addedDevDeps.length} dev dependencies to pubspec.yaml: ${addedDevDeps.join(', ')}",
      );
    }
    Logger.warn(
      "⚠ Please review pubspec.yaml — this was a best-effort text merge, not full YAML parsing.",
    );
  }

  Future<void> _writeSetupSummaryJson() async {
    final buffer = StringBuffer();
    buffer.writeln('{');
    buffer.writeln('  "project": "$projectName",');
    buffer.writeln('  "foldersCreated": $foldersCreated,');
    buffer.writeln('  "filesCreated": $filesCreated,');
    buffer.writeln('  "skipped": $skipped,');
    buffer.writeln('  "sampleFeature": ${config.createSampleFeature},');
    buffer.writeln('  "ci": ${config.setupCI},');
    buffer.writeln('  "stateManagement": "Riverpod (StateNotifier)",');
    buffer.writeln('  "diSetup": "Riverpod providers (no get_it needed)",');
    buffer.writeln('  "routingSetup": "Navigator + onGenerateRoute + guards"');
    buffer.writeln('}');
    await File("setup_summary.json").writeAsString(buffer.toString());
  }

  void _printSummary() {
    final divider = "=" * 50;
    Logger.info("\n$divider");
    Logger.info(" Setup Summary");
    Logger.info(divider);
    Logger.info("  Folders created : $foldersCreated");
    Logger.info("  Files created   : $filesCreated");
    Logger.info("  Items skipped   : $skipped");
    Logger.info("  State mgmt      : Riverpod (StateNotifier)");
    Logger.info("  DI              : Riverpod providers (no get_it)");
    Logger.info("  Routing         : Navigator (+ guards)");
    Logger.info(divider);
  }

  String _generateFileContent(String fileName) {
    if (fileName.contains("extensions.dart")) {
      return "// TODO: Add ${fileName.split('_')[0]} extensions here\n";
    }

    if (fileName == "typedefs.dart") {
      return """typedef DataMap = Map<String, dynamic>;
typedef ResultFuture<T> = Future<Either<Failure, T>>;
typedef ResultStream<T> = Stream<Either<Failure, T>>;
typedef VoidCallback = void Function();
""";
    }

    if (fileName == "usecase.dart") {
      return """import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../error/failure.dart';
import '../utils/typedefs.dart';

abstract class UseCase<Type, Params> {
  const UseCase();
  ResultFuture<Type> call(Params params);
}

abstract class UseCaseWithoutParams<Type> {
  const UseCaseWithoutParams();
  ResultFuture<Type> call();
}

abstract class StreamUseCase<Type, Params> {
  const StreamUseCase();
  ResultStream<Type> call(Params params);
}

class NoParams extends Equatable {
  const NoParams();
  @override
  List<Object?> get props => [];
}
""";
    }

    if (fileName == "app_state_providers.dart") {
      return """import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// App-wide Riverpod providers that don't belong to any single
/// feature (theme mode, locale, connectivity banner, etc). These are
/// visible anywhere under the root `ProviderScope` in `main.dart` —
/// no extra wiring needed, unlike Provider's `MultiProvider` tree.
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

final localeProvider = StateProvider<Locale>((ref) => const Locale('en', 'US'));
""";
    }

    if (fileName == "navigation_helper.dart") {
      return """import 'package:flutter/material.dart';

/// Thin wrapper around a global `navigatorKey` so services/controllers
/// can navigate, show snackbars, or show dialogs without needing a
/// `BuildContext` passed down through every layer.
class NavigationHelper {
  NavigationHelper._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static BuildContext? get context => navigatorKey.currentContext;

  static Future<T?>? pushNamed<T>(String route, {Object? arguments}) =>
      navigatorKey.currentState?.pushNamed<T>(route, arguments: arguments);

  static Future<T?>? pushReplacementNamed<T, TO>(
    String route, {
    Object? arguments,
  }) =>
      navigatorKey.currentState
          ?.pushReplacementNamed<T, TO>(route, arguments: arguments);

  static void pop<T>([T? result]) => navigatorKey.currentState?.pop(result);
}
""";
    }

    if (fileName == "logger.dart") {
      return """import 'package:logger/logger.dart';

/// Thin wrapper around package:logger so the rest of the app doesn't
/// depend on a specific logging package directly.
class AppLogger {
  AppLogger._();

  static final Logger _logger = Logger(
    printer: PrettyPrinter(methodCount: 1, errorMethodCount: 5, colors: true),
  );

  static void debug(String message) => _logger.d(message);
  static void info(String message) => _logger.i(message);
  static void warning(String message) => _logger.w(message);
  static void error(String message, [Object? error, StackTrace? stackTrace]) =>
      _logger.e(message, error: error, stackTrace: stackTrace);
}
""";
    }

    return "// TODO: Implement $fileName\n";
  }

  String _coreProvidersContent() {
    return """import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/network_client.dart';
import '../network/network_info.dart';

/// App-wide Riverpod `Provider`s. Riverpod is the dependency-injection
/// mechanism here — there's no separate `get_it`/service-locator step
/// and no code generation required.
///
/// [sharedPreferencesProvider] needs an async value that must exist
/// before `runApp`, so it's declared with a placeholder and overridden
/// once `main()` resolves it:
///
/// ```dart
/// final sharedPreferences = await SharedPreferences.getInstance();
/// runApp(
///   ProviderScope(
///     overrides: [sharedPreferencesProvider.overrideWithValue(sharedPreferences)],
///     child: const MyApp(),
///   ),
/// );
/// ```
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in main() before runApp.',
  );
});

final dioProvider = Provider<Dio>((ref) => NetworkClient.create());

final networkInfoProvider = Provider<NetworkInfo>((ref) => NetworkInfoImpl());
""";
  }

  String _appRoutesContent() {
    return """/// Route name constants used with `Navigator.pushNamed` and
/// `AppRouter.onGenerateRoute`.
abstract class Routes {
  Routes._();

  static const String login = '/login';
  static const String home = '/home';
}
""";
  }

  String _appRouterContent() {
    return """import 'package:flutter/material.dart';

import '../../src/features/auth/presentation/views/home_screen.dart';
import '../../src/features/auth/presentation/views/login_screen.dart';
import 'app_routes.dart';
import 'guards/auth_guard.dart';
import 'guards/guest_guard.dart';

/// Central route table for the app, used as `MaterialApp.onGenerateRoute`.
/// Add a `case` for every screen, wrapping it with `AuthGuard` or
/// `GuestGuard` where access should be gated.
class AppRouter {
  AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.login:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const GuestGuard(child: LoginScreen()),
        );
      case Routes.home:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const AuthGuard(child: HomeScreen()),
        );
      default:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for \${settings.name}'),
            ),
          ),
        );
    }
  }
}
""";
  }

  String _authGuardContent() {
    return """import 'package:flutter/material.dart';

import '../app_routes.dart';

/// Wraps an authenticated-only screen. Redirects to login if the
/// user isn't authenticated.
///
/// Wire `_checkIsAuthenticated` up to your real auth/session state
/// (e.g. `ref.read(authLocalDataSourceProvider).hasToken()` via a
/// `ConsumerWidget`) instead of the TODO placeholder below.
class AuthGuard extends StatelessWidget {
  const AuthGuard({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = _checkIsAuthenticated();

    if (!isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed(Routes.login);
      });
      return const SizedBox.shrink();
    }

    return child;
  }

  bool _checkIsAuthenticated() {
    // TODO: replace with a real check against your auth state provider.
    return false;
  }
}
""";
  }

  String _guestGuardContent() {
    return """import 'package:flutter/material.dart';

import '../app_routes.dart';

/// Wraps a guest-only screen (login, sign up, etc). Redirects
/// already-authenticated users onward instead of showing it again.
class GuestGuard extends StatelessWidget {
  const GuestGuard({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = _checkIsAuthenticated();

    if (isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed(Routes.home);
      });
      return const SizedBox.shrink();
    }

    return child;
  }

  bool _checkIsAuthenticated() {
    // TODO: replace with a real check, mirroring AuthGuard.
    return false;
  }
}
""";
  }

  String _generateFeatureFileContent(String fileName) {
    switch (fileName) {
      case "auth_state.dart":
        return """import 'package:equatable/equatable.dart';

import '../../domain/entities/user.dart';

/// Immutable state for the auth feature, held by [AuthController]
/// and read via `ref.watch(authControllerProvider)`.
class AuthState extends Equatable {
  const AuthState({
    this.isLoading = false,
    this.user,
    this.errorMessage,
  });

  const AuthState.initial() : this();

  final bool isLoading;
  final User? user;
  final String? errorMessage;

  AuthState copyWith({
    bool? isLoading,
    User? user,
    String? errorMessage,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [isLoading, user, errorMessage];
}
""";
      case "auth_controller.dart":
        return """import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/usecases/login_user.dart';
import '../../domain/usecases/logout_user.dart';
import 'auth_state.dart';

/// `StateNotifier` for the auth feature. Views watch it via
/// `ref.watch(authControllerProvider)` (see `auth_providers.dart`
/// for where it's wired up) and call its methods with
/// `ref.read(authControllerProvider.notifier)`.
class AuthController extends StateNotifier<AuthState> {
  AuthController(this._loginUser, this._logoutUser) : super(const AuthState.initial());

  final LoginUser _loginUser;
  final LogoutUser _logoutUser;

  Future<void> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _loginUser(LoginParams(email: email, password: password));

    state = result.fold(
      (failure) => state.copyWith(isLoading: false, errorMessage: failure.message),
      (user) => state.copyWith(isLoading: false, user: user),
    );
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);

    final result = await _logoutUser();

    state = result.fold(
      (failure) => state.copyWith(isLoading: false, errorMessage: failure.message),
      (_) => const AuthState.initial(),
    );
  }
}
""";
      case "auth_providers.dart":
        return """import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/core_providers.dart';
import '../../data/datasources/auth_local_datasource.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login_user.dart';
import '../../domain/usecases/logout_user.dart';
import '../controllers/auth_controller.dart';
import '../controllers/auth_state.dart';

/// Wires up the auth feature's dependency graph. `.autoDispose` scopes
/// each provider's lifetime to whichever widgets are actually watching
/// it — comparable to a `ChangeNotifierProvider` living only as long
/// as the screen that created it, but declared once here instead of
/// per screen.
final authRemoteDataSourceProvider = Provider.autoDispose<AuthRemoteDataSource>(
  (ref) => AuthRemoteDataSourceImpl(ref.watch(dioProvider)),
);

final authLocalDataSourceProvider = Provider.autoDispose<AuthLocalDataSource>(
  (ref) => AuthLocalDataSourceImpl(ref.watch(sharedPreferencesProvider)),
);

final authRepositoryProvider = Provider.autoDispose<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    ref.watch(authRemoteDataSourceProvider),
    ref.watch(authLocalDataSourceProvider),
  ),
);

final loginUserProvider = Provider.autoDispose<LoginUser>(
  (ref) => LoginUser(ref.watch(authRepositoryProvider)),
);

final logoutUserProvider = Provider.autoDispose<LogoutUser>(
  (ref) => LogoutUser(ref.watch(authRepositoryProvider)),
);

final authControllerProvider =
    StateNotifierProvider.autoDispose<AuthController, AuthState>(
  (ref) => AuthController(ref.watch(loginUserProvider), ref.watch(logoutUserProvider)),
);
""";
      case "auth_remote_datasource.dart":
        return """import 'package:dio/dio.dart';

import '../../../../core/error/exception.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login({required String email, required String password});
  Future<void> logout();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  const AuthRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<UserModel> login({required String email, required String password}) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(message: e.message ?? 'Login failed');
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } on DioException catch (e) {
      throw ServerException(message: e.message ?? 'Logout failed');
    }
  }
}
""";
      case "auth_local_datasource.dart":
        return """import 'package:shared_preferences/shared_preferences.dart';

abstract class AuthLocalDataSource {
  Future<void> cacheToken(String token);
  String? getToken();
  Future<void> clearToken();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  const AuthLocalDataSourceImpl(this._prefs);

  final SharedPreferences _prefs;
  static const _tokenKey = 'AUTH_TOKEN';

  @override
  Future<void> cacheToken(String token) => _prefs.setString(_tokenKey, token);

  @override
  String? getToken() => _prefs.getString(_tokenKey);

  @override
  Future<void> clearToken() => _prefs.remove(_tokenKey);
}
""";
      case "user_model.dart":
        return """import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    required super.name,
    this.token,
  });

  final String? token;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      token: json['token'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        if (token != null) 'token': token,
      };
}
""";
      case "auth_repository_impl.dart":
        return """import 'package:dartz/dartz.dart';

import '../../../../core/error/exception.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/utils/typedefs.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._remoteDataSource, this._localDataSource);

  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;

  @override
  ResultFuture<User> login({required String email, required String password}) async {
    try {
      final UserModel user = await _remoteDataSource.login(email: email, password: password);
      if (user.token != null) await _localDataSource.cacheToken(user.token!);
      return Right(user);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  ResultFuture<void> logout() async {
    try {
      await _remoteDataSource.logout();
      await _localDataSource.clearToken();
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }
}
""";
      case "user.dart":
        return """import 'package:equatable/equatable.dart';

class User extends Equatable {
  const User({required this.id, required this.email, required this.name});

  final String id;
  final String email;
  final String name;

  @override
  List<Object?> get props => [id, email, name];
}
""";
      case "auth_repository.dart":
        return """import '../../../../core/utils/typedefs.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  ResultFuture<User> login({required String email, required String password});
  ResultFuture<void> logout();
}
""";
      case "login_user.dart":
        return """import 'package:equatable/equatable.dart';

import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/typedefs.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class LoginUser extends UseCase<User, LoginParams> {
  const LoginUser(this._repository);

  final AuthRepository _repository;

  @override
  ResultFuture<User> call(LoginParams params) {
    return _repository.login(email: params.email, password: params.password);
  }
}

class LoginParams extends Equatable {
  const LoginParams({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}
""";
      case "logout_user.dart":
        return """import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/typedefs.dart';
import '../repositories/auth_repository.dart';

class LogoutUser extends UseCaseWithoutParams<void> {
  const LogoutUser(this._repository);

  final AuthRepository _repository;

  @override
  ResultFuture<void> call() => _repository.logout();
}
""";
      case "login_screen.dart":
        return """import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/login_form.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: LoginForm(),
        ),
      ),
    );
  }
}
""";
      case "home_screen.dart":
        return """import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: const Center(child: Text('Welcome!')),
    );
  }
}
""";
      case "login_form.dart":
        return """import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/router/app_routes.dart';
import '../providers/auth_providers.dart';

class LoginForm extends ConsumerStatefulWidget {
  const LoginForm({super.key});

  @override
  ConsumerState<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    ref.listen(authControllerProvider, (previous, next) {
      if (next.errorMessage != null && next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!)),
        );
      }
      if (next.user != null && previous?.user == null) {
        Navigator.of(context).pushReplacementNamed(Routes.home);
      }
    });

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email'),
            validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            decoration: const InputDecoration(labelText: 'Password'),
            obscureText: true,
            validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: authState.isLoading ? null : _submit,
            child: authState.isLoading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Sign in'),
          ),
        ],
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      ref.read(authControllerProvider.notifier).login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    }
  }
}
""";
      default:
        return "// TODO: Implement $fileName\n";
    }
  }

  String _dependenciesContent() {
    return """# Core Dependencies
flutter_riverpod: ^2.5.1
equatable: ^2.0.5
dartz: ^0.10.1

# Network
dio: ^5.4.3
connectivity_plus: ^6.0.3

# Local Storage
hive: ^2.2.3
hive_flutter: ^1.1.0
shared_preferences: ^2.2.3

# Code Generation (dev_dependencies, only needed if you add Hive
# TypeAdapters with @HiveType — Riverpod itself needs no codegen
# unless you opt into riverpod_generator/@riverpod, which this
# scaffold does not use)
build_runner: ^2.4.11
hive_generator: ^2.0.1
flutter_lints: ^4.0.0
mocktail: ^1.0.4

# UI/UX
cached_network_image: ^3.3.1
shimmer: ^3.0.0
flutter_svg: ^2.0.10

# Utilities
intl: ^0.19.0
logger: ^2.3.0

# These are merged into pubspec.yaml automatically during setup
# (pass --no-update-pubspec to skip).
""";
  }

  String _envConfigContent() {
    return """class EnvConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.example.com',
  );

  static const String apiKey = String.fromEnvironment('API_KEY');

  static const bool isDevelopment = bool.fromEnvironment(
    'IS_DEVELOPMENT',
    defaultValue: true,
  );
}
""";
  }

  String _envExampleContent() {
    return """# API Configuration
API_BASE_URL=https://api.example.com
API_KEY=your_api_key_here

# Environment
IS_DEVELOPMENT=true
""";
  }

  String _featureReadmeContent() {
    return """# Features

This directory contains all feature modules. Each feature follows Clean Architecture.

## Feature Structure

```
feature_name/
├── data/
│   ├── datasources/
│   ├── models/
│   └── repositories/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
└── presentation/
    ├── controllers/
    ├── providers/
    ├── views/
    └── widgets/
```

## Creating a New Feature

1. Create a new folder with your feature name under `lib/src/features`.
2. Follow the structure above.
3. Give the feature an immutable state class and a `StateNotifier`
   under `presentation/controllers/` (see `auth_state.dart` /
   `auth_controller.dart` for the pattern).
4. Wire up its dependency graph in `presentation/providers/`, using
   `Provider.autoDispose` / `StateNotifierProvider.autoDispose` so the
   graph is created and torn down with whatever's watching it.
5. Add a route + guard in `lib/core/router/app_router.dart`.
6. Write tests for each layer (data / domain / presentation).
""";
  }

  String _githubActionsContent() {
    return """name: Flutter CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v4

    - uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.24.0'
        channel: 'stable'

    - name: Get dependencies
      run: flutter pub get

    - name: Analyze
      run: flutter analyze

    - name: Run tests
      run: flutter test

    - name: Build APK
      run: flutter build apk --release
""";
  }

  String _analysisOptionsContent() {
    return """include: package:flutter_lints/flutter.yaml

linter:
  rules:
    - always_declare_return_types
    - always_put_required_named_parameters_first
    - avoid_print
    - avoid_unnecessary_containers
    - prefer_const_constructors
    - prefer_const_declarations
    - prefer_final_fields
    - prefer_single_quotes
    - sort_child_properties_last
    - use_key_in_widget_constructors

analyzer:
  exclude:
    - "**/*.g.dart"
  errors:
    invalid_annotation_target: ignore
""";
  }

  String _readmeContent() {
    return """# $projectName

A Flutter project with Clean Architecture and Riverpod, used for both
state management and dependency injection — no `get_it`, no
`injectable`, no code generation required for DI or navigation.

## Project Structure

- **lib/core**: Core functionality, DI, routing, and shared resources
- **lib/src/features**: Feature modules following Clean Architecture
- **test**: Unit and widget tests

## Setup

1. Install dependencies:
   ```bash
   flutter pub get
   ```

2. (Optional) If you add Hive models annotated with `@HiveType`, generate
   their adapters:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

3. Run the app:
   ```bash
   flutter run
   ```

## Architecture

This project follows Clean Architecture. Riverpod plays two roles at
once: state management (`StateNotifier` + `StateNotifierProvider`) and
dependency injection (plain `Provider`s composing the dependency
graph). See [ARCHITECTURE.md](ARCHITECTURE.md) for details.

## Routing

Screens are registered in `lib/core/router/app_router.dart`'s
`onGenerateRoute`, with route names centralized in
`lib/core/router/app_routes.dart`. Protect a screen by wrapping it with
`AuthGuard` or `GuestGuard` from `lib/core/router/guards/`.

## Dependency Injection

App-wide dependencies (Dio, SharedPreferences, NetworkInfo) are plain
`Provider`s in `lib/core/di/core_providers.dart`. Because
`SharedPreferences.getInstance()` is async, `sharedPreferencesProvider`
is overridden once in `main()` before `runApp`:

```dart
final sharedPreferences = await SharedPreferences.getInstance();
runApp(
  ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(sharedPreferences)],
    child: const MyApp(),
  ),
);
```

Feature dependencies (repositories, use cases, controllers) are
composed the same way inside that feature's `providers/` file, using
`ref.watch(...)` to pull in whatever they need — see
`auth_providers.dart`.

## State Management

Each feature has an immutable state class (`AuthState`) and a
`StateNotifier` (`AuthController`) that emits new states by assigning
`state = state.copyWith(...)`. Widgets read it with
`ref.watch(authControllerProvider)` (rebuilds on change),
`ref.read(authControllerProvider.notifier)` (call a method without
subscribing), or `ref.listen(...)` for one-off side effects like
navigation or snackbars — see `login_form.dart`.
""";
  }

  String _architectureContent() {
    return """# Architecture

## Clean Architecture Layers

### 1. Presentation Layer
- **Controllers**: `StateNotifier` subclasses emitting immutable state via `copyWith`
- **Providers**: Riverpod `Provider`/`StateNotifierProvider` definitions wiring up a feature's dependency graph
- **Views**: Screens, typically extending `ConsumerWidget`/`ConsumerStatefulWidget`
- **Widgets**: Reusable UI components, reading state via `ref.watch`/`ref.read`/`ref.listen`

### 2. Domain Layer
- **Entities**: Business objects
- **Repositories**: Abstract contracts
- **Use Cases**: Business logic operations, plain Dart classes

### 3. Data Layer
- **Models**: Data transfer objects
- **Repositories**: Concrete implementations of the domain contracts
- **Data Sources**: Remote and local data sources

## Dependency Flow

```
Presentation → Domain ← Data
```

- Presentation depends on Domain
- Data depends on Domain
- Domain depends on nothing (pure Dart)

## Dependency Injection (Riverpod)

- `lib/core/di/core_providers.dart` declares app-wide `Provider`s
  (Dio, SharedPreferences, NetworkInfo). Async dependencies are
  declared with a placeholder and overridden once in `main()`, before
  `runApp`, via `ProviderScope(overrides: [...])`.
- Each feature composes its own dependency graph in a
  `presentation/providers/` file (e.g. `auth_providers.dart`), with
  `Provider.autoDispose`/`StateNotifierProvider.autoDispose` so the
  graph is built lazily and disposed once nothing is watching it
  anymore — comparable to scoping a `ChangeNotifierProvider` to a
  screen, but declared once instead of per entry point.
- No annotations, `get_it`, or `build_runner` step are needed for DI.

## Routing (Navigator + onGenerateRoute)

- `lib/core/router/app_routes.dart` centralizes route name constants.
- `lib/core/router/app_router.dart` maps route names to screens via
  `onGenerateRoute`, passed to `MaterialApp.onGenerateRoute`.
- `lib/core/router/guards/` contains guard widgets (`AuthGuard`,
  `GuestGuard`) that wrap a screen and redirect via
  `Navigator.pushReplacementNamed` when the auth condition isn't met.
- No codegen or third-party routing package is required.

## State Management (Riverpod)

- Each feature has an immutable state class (`AuthState`, built with
  `Equatable` + `copyWith`) and a `StateNotifier` (`AuthController`)
  that reassigns `state` after each mutation.
- Widgets watch state with `ref.watch(authControllerProvider)`
  (rebuilds on every change), read it once with
  `ref.read(authControllerProvider.notifier)` (e.g. inside a button's
  `onPressed`), or react to changes without rebuilding via
  `ref.listen(...)` — used in `login_form.dart` for snackbars and
  post-login navigation.
""";
  }

  Future<void> _setupMyApp() async {
    await _createFolder("lib/src/my_app");
    await _createFile(
      "lib/src/my_app/my_app.dart",
      content:
          """import 'package:flutter/material.dart';

import '../../core/router/app_router.dart';
import '../../core/router/app_routes.dart';
import '../../core/service/navigation_helper.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '$projectName',
      navigatorKey: NavigationHelper.navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      initialRoute: Routes.login,
      onGenerateRoute: AppRouter.onGenerateRoute,
      debugShowCheckedModeBanner: false,
    );
  }
}
""",
    );

    if (!config.dryRun) {
      final mainFile = File("lib/main.dart");
      if (mainFile.existsSync()) {
        await mainFile.writeAsString(
            """import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:$projectName/core/di/core_providers.dart';
import 'package:$projectName/src/my_app/my_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const MyApp(),
    ),
  );
}
""");
        _created.add(_CreatedEntry(path: "lib/main.dart", isDirectory: false));
      }
    }
  }

  Future<void> _setupWidgetTest() async {
    await _createFolder("test");
    await _createFile(
      "test/widget_test.dart",
      content: """import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('smoke test builds a MaterialApp', (WidgetTester tester) async {
    // NOTE: MyApp() relies on providers overridden in main() (e.g.
    // sharedPreferencesProvider), which aren't set up automatically
    // in the test environment. Prefer testing individual screens or
    // StateNotifiers in isolation, wrapped in a ProviderScope with
    // mocked overrides as needed.
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    expect(find.byType(SizedBox), findsOneWidget);
  });
}
""",
    );
  }

  Future<void> _appendToGitignore() async {
    if (config.dryRun) return;

    final gitignore = File(".gitignore");
    if (!gitignore.existsSync()) return;

    final content = await gitignore.readAsString();
    final additions = <String>[];

    if (!content.contains(".env")) additions.addAll(['.env', '*.env']);
    if (!content.contains('*.g.dart')) additions.add('*.g.dart');
    if (!content.contains('setup_summary.json'))
      additions.add('setup_summary.json');

    if (additions.isEmpty) return;

    await gitignore.writeAsString(
      "$content\n# Added by setup_project_riverpod.dart\n${additions.join('\n')}\n",
      mode: FileMode.append,
    );
  }
}

class _CreatedEntry {
  final String path;
  final bool isDirectory;
  const _CreatedEntry({required this.path, required this.isDirectory});
}