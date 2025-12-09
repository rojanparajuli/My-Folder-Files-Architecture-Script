import 'dart:io';

void main(List<String> args) async {
  print("🚀 Starting Enhanced Dart BLoC Project Structure Setup...\n");

  final config = ProjectConfig.fromArgs(args);

  final Directory libDir = Directory("lib");
  if (!libDir.existsSync()) {
    print("❌ lib folder not found. Script terminated.");
    exit(1);
  }

  try {
    final setupManager = ProjectSetupManager(config);
    await setupManager.setup();

    print("\n✅ Project setup completed successfully!");
    print("📝 Next steps:");
    print("   1. Run: flutter pub get");
    print(
      "   2. Run: dart run build_runner build --delete-conflicting-outputs",
    );
    print("   3. Check README.md for project structure details");
  } catch (e, stackTrace) {
    print("❌ Setup failed: $e");
    if (config.verbose) {
      print("Stack trace: $stackTrace");
    }
  }
}

class ProjectConfig {
  final bool verbose;
  final bool skipExisting;
  final bool createSampleFeature;
  final bool setupCI;
  final bool setupAnalysis;

  ProjectConfig({
    this.verbose = false,
    this.skipExisting = true,
    this.createSampleFeature = true,
    this.setupCI = false,
    this.setupAnalysis = true,
  });

  factory ProjectConfig.fromArgs(List<String> args) {
    return ProjectConfig(
      verbose: args.contains('--verbose') || args.contains('-v'),
      skipExisting: !args.contains('--overwrite'),
      createSampleFeature: !args.contains('--no-sample'),
      setupCI: args.contains('--ci'),
      setupAnalysis: args.contains('--analysis'),
    );
  }
}

class ProjectSetupManager {
  final ProjectConfig config;
  final String projectName;
  int foldersCreated = 0;
  int filesCreated = 0;
  int skipped = 0;

  ProjectSetupManager(this.config)
    : projectName = Directory.current.path.split(Platform.pathSeparator).last;

  Future<void> setup() async {
    // Core structure
    await _setupCoreStructure();

    // Features structure
    await _setupFeaturesStructure();

    // Assets
    await _setupAssets();

    // Configuration files
    await _setupConfigFiles();

    // Sample feature (optional)
    if (config.createSampleFeature) {
      await _createSampleFeature();
    }

    // CI/CD (optional)
    if (config.setupCI) {
      await _setupCI();
    }

    // Analysis options
    if (config.setupAnalysis) {
      await _setupAnalysisOptions();
    }

    // Generate documentation
    await _generateDocumentation();
    await runpubupgrade();
    // Print summary
    _printSummary();
  }

  Future<void> _setupCoreStructure() async {
    print("\n📦 Setting up core structure...");

    final coreStructure = {
      "lib/core/cache": ["store_cache.dart", "cache_manager.dart"],
      "lib/core/common/app": ["cache_helper.dart", "providers.dart"],
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
      "lib/core/service": [
        "codec.dart",
        "injection_container.dart",
        "injection_container.main.dart",
        "navigation_helper.dart",
        "router.dart",
        "router.main.dart",
      ],
      "lib/core/usecase": ["usecase.dart"],
      "lib/core/utils": [
        "core_utils.dart",
        "date_time_formatter.dart",
        "error_response.dart",
        "go_router_refresh_stream.dart",
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

    for (var entry in coreStructure.entries) {
      _createFolder(entry.key);
      for (var file in entry.value) {
        await _createFile(
          "${entry.key}/$file",
          content: _generateFileContent(file),
        );
      }
    }
  }

  Future<void> _setupFeaturesStructure() async {
    print("\n🎯 Setting up features structure...");

    _createFolder("lib/src/features");
    await _createFile(
      "lib/src/features/README.md",
      content: _featureReadmeContent(),
    );
  }

  Future<void> _setupAssets() async {
    print("\n🎨 Setting up assets...");

    final assetFolders = [
      "assets/images",
      "assets/icons",
      "assets/fonts",
      "assets/lottie",
      "assets/videos",
      "assets/audio",
      "assets/animations",
    ];

    for (var folder in assetFolders) {
      _createFolder(folder);
      await _createFile(
        "$folder/.gitkeep",
        content: "# Keep this folder in version control",
      );
    }
  }

  Future<void> _setupConfigFiles() async {
    print("\n⚙️  Setting up configuration files...");

    // pubspec.yaml dependencies
    await _createFile(
      "dependency_requirements.txt",
      content: _dependenciesContent(),
    );

    // Environment config
    await _createFile(
      "lib/core/config/env_config.dart",
      content: _envConfigContent(),
    );

    // .env.example
    await _createFile(".env.example", content: _envExampleContent());

    // .gitignore additions
    await _appendToGitignore();

    // MyApp setup
    await _setupMyApp();

    // Widget test
    await _setupWidgetTest();
  }

  Future<void> _createSampleFeature() async {
    print("\n🌟 Creating sample feature (auth)...");

    final featurePath = "lib/src/features/auth";
    final featureStructure = {
      "$featurePath/data/datasources": [
        "auth_remote_datasource.dart",
        "auth_local_datasource.dart",
      ],
      "$featurePath/data/models": ["user_model.dart"],
      "$featurePath/data/repositories": ["auth_repository_impl.dart"],
      "$featurePath/domain/entities": ["user.dart"],
      "$featurePath/domain/repositories": ["auth_repository.dart"],
      "$featurePath/domain/usecases": ["login_user.dart", "logout_user.dart"],
      "$featurePath/presentation/bloc": [
        "auth_bloc.dart",
        "auth_event.dart",
        "auth_state.dart",
      ],
      "$featurePath/presentation/views": ["login_screen.dart"],
      "$featurePath/presentation/widgets": ["login_form.dart"],
    };

    for (var entry in featureStructure.entries) {
      _createFolder(entry.key);
      for (var file in entry.value) {
        await _createFile(
          "${entry.key}/$file",
          content: _generateFeatureFileContent(file),
        );
      }
    }
  }

  Future<void> _setupCI() async {
    print("\n🔄 Setting up CI/CD...");

    _createFolder(".github/workflows");
    await _createFile(
      ".github/workflows/flutter_ci.yml",
      content: _githubActionsContent(),
    );
  }

  Future<void> _setupAnalysisOptions() async {
    print("\n🔍 Setting up analysis options...");

    await _createFile(
      "analysis_options.yaml",
      content: _analysisOptionsContent(),
    );
  }

  Future<void> _generateDocumentation() async {
    print("\n📚 Generating documentation...");

    await _createFile("README.md", content: _readmeContent());

    await _createFile("ARCHITECTURE.md", content: _architectureContent());
  }

  void _createFolder(String path) {
    final dir = Directory(path);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
      foldersCreated++;
      if (config.verbose) print("  ✓ Created folder: $path");
    } else {
      skipped++;
      if (config.verbose) print("  ⊘ Folder exists: $path");
    }
  }

  Future<void> _createFile(String path, {String content = ""}) async {
    final file = File(path);
    if (!file.existsSync() || !config.skipExisting) {
      file.createSync(recursive: true);
      await file.writeAsString(content);
      filesCreated++;
      if (config.verbose) print("  ✓ Created file: $path");
    } else {
      skipped++;
      if (config.verbose) print("  ⊘ File exists: $path");
    }
  }

  String _generateFileContent(String fileName) {
    // Generate basic boilerplate for common files
    if (fileName.contains("extensions.dart")) {
      return "// TODO: Add ${fileName.split('_')[0]} extensions here\n";
    }
    if (fileName == "typedefs.dart") {
      return """typedef DataMap = Map<String, dynamic>;
typedef ResultFuture<T> = Future<Either<Failure, T>>;
typedef ResultStream<T> = Stream<Either<Failure, T>>;
""";
    }
    if (fileName == "usecase.dart") {
      return """import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../error/failure.dart';

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

typedef ResultFuture<T> = Future<Either<Failure, T>>;
typedef ResultStream<T> = Stream<Either<Failure, T>>;
""";
    }
    return "// TODO: Implement $fileName\n";
  }

  String _generateFeatureFileContent(String fileName) {
    if (fileName == "auth_bloc.dart") {
      return """import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    on<AuthEvent>((event, emit) {
      // TODO: implement event handler
    });
  }
}
""";
    }
    if (fileName == "auth_event.dart") {
      return """part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class LoginRequested extends AuthEvent {
  const LoginRequested({required this.email, required this.password});
  
  final String email;
  final String password;

  @override
  List<Object> get props => [email, password];
}
""";
    }
    if (fileName == "auth_state.dart") {
      return """part of 'auth_bloc.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  
  @override
  List<Object> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {}

class AuthError extends AuthState {
  const AuthError(this.message);
  final String message;

  @override
  List<Object> get props => [message];
}
""";
    }
    return "// TODO: Implement $fileName\n";
  }

  String _dependenciesContent() {
    return """# Core Dependencies
flutter_bloc: ^8.1.3
equatable: ^2.0.5
dartz: ^0.10.1
get_it: ^7.6.4

# Navigation
go_router: ^13.0.0

# Network
dio: ^5.4.0
connectivity_plus: ^5.0.2

# Local Storage
hive: ^2.2.3
hive_flutter: ^1.1.0
shared_preferences: ^2.2.2

# Code Generation
freezed_annotation: ^2.4.1
json_annotation: ^4.8.1

# Dev Dependencies (add to dev_dependencies)
build_runner: ^2.4.7
freezed: ^2.4.6
json_serializable: ^6.7.1
flutter_lints: ^3.0.1
mocktail: ^1.0.1

# UI/UX
cached_network_image: ^3.3.1
shimmer: ^3.0.0
flutter_svg: ^2.0.9

# Utilities
intl: ^0.19.0
logger: ^2.0.2
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

This directory contains all feature modules. Each feature should follow clean architecture:

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
    ├── bloc/
    ├── views/
    └── widgets/
```

## Creating a New Feature

1. Create a new folder with your feature name
2. Follow the structure above
3. Implement clean architecture principles
4. Write tests for each layer
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
    - uses: actions/checkout@v3
    
    - uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.19.0'
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
    - "**/*.freezed.dart"
  errors:
    invalid_annotation_target: ignore
""";
  }

  String _readmeContent() {
    return """# $projectName

A Flutter project with clean architecture and BLoC pattern.

## Project Structure

- **lib/core**: Core functionality, utilities, and shared resources
- **lib/src/features**: Feature modules following clean architecture
- **test**: Unit and widget tests

## Setup

1. Install dependencies:
   ```bash
   flutter pub get
   ```

2. Run build runner:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

3. Run the app:
   ```bash
   flutter run
   ```

## Architecture

This project follows Clean Architecture principles with BLoC for state management.
See [ARCHITECTURE.md](ARCHITECTURE.md) for details.

## Code Generation

Run this command when you modify models or add new generated files:
```bash
dart run build_runner watch --delete-conflicting-outputs
```
""";
  }

  String _architectureContent() {
    return """# Architecture

## Clean Architecture Layers

### 1. Presentation Layer
- **BLoC**: Business Logic Components
- **Views**: UI screens
- **Widgets**: Reusable UI components

### 2. Domain Layer
- **Entities**: Business objects
- **Repositories**: Abstract contracts
- **Use Cases**: Business logic operations

### 3. Data Layer
- **Models**: Data transfer objects
- **Repositories**: Implementation of domain contracts
- **Data Sources**: Remote and local data sources

## Dependency Flow

```
Presentation → Domain ← Data
```

- Presentation depends on Domain
- Data depends on Domain
- Domain depends on nothing (pure Dart)

## State Management

Using BLoC pattern:
- Events trigger state changes
- BLoC processes events and emits states
- UI rebuilds based on state changes
""";
  }

  Future<void> _setupMyApp() async {
    _createFolder("lib/src/my_app");
    await _createFile(
      "lib/src/my_app/my_app.dart",
      content:
          """import 'package:flutter/material.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '$projectName',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text('Welcome to $projectName'),
        ),
      ),
    );
  }
}
""",
    );

    final mainFile = File("lib/main.dart");
    if (mainFile.existsSync()) {
      await mainFile.writeAsString("""import 'package:flutter/material.dart';
import 'package:$projectName/src/my_app/my_app.dart';

void main() {
  runApp(const MyApp());
}
""");
    }
  }

  Future<void> _setupWidgetTest() async {
    _createFolder("test");
    await _createFile(
      "test/widget_test.dart",
      content:
          """import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:$projectName/src/my_app/my_app.dart';

void main() {
  testWidgets('MyApp widget test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Welcome to $projectName'), findsOneWidget);
  });
}
""",
    );
  }

  Future<void> _appendToGitignore() async {
    final gitignore = File(".gitignore");
    if (gitignore.existsSync()) {
      final content = await gitignore.readAsString();
      if (!content.contains(".env")) {
        await gitignore.writeAsString(
          "$content\n# Environment files\n.env\n*.env\n",
          mode: FileMode.append,
        );
      }
    }
  }

  Future<void> runpubupgrade() async {
    final result = await Process.run('flutter', ['pub', 'upgrade']);
    if (result.exitCode == 0) {
      print("✅ Dependencies upgraded successfully.");
    } else {
      print("❌ Failed to upgrade dependencies: ${result.stderr}");
    }
  }

  void _printSummary() {
    print("\n" + "=" * 50);
    print("📊 Setup Summary");
    print("=" * 50);
    print("  Folders created: $foldersCreated");
    print("  Files created: $filesCreated");
    print("  Items skipped: $skipped");
    print("=" * 50);
  }
}
