
set -e
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' 

VERBOSE=false
OVERWRITE=false
CREATE_SAMPLE=true
SETUP_CI=false
SKIP_ANALYSIS=false
SKIP_TESTS=false

while [[ $# -gt 0 ]]; do
  case $1 in
    -v|--verbose)
      VERBOSE=true
      shift
      ;;
    --overwrite)
      OVERWRITE=true
      shift
      ;;
    --no-sample)
      CREATE_SAMPLE=false
      shift
      ;;
    --ci)
      SETUP_CI=true
      shift
      ;;
    --no-analysis)
      SKIP_ANALYSIS=true
      shift
      ;;
    --no-tests)
      SKIP_TESTS=true
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [options]"
      echo "Options:"
      echo "  -v, --verbose      Enable verbose output"
      echo "  --overwrite        Overwrite existing files"
      echo "  --no-sample        Skip creating sample auth feature"
      echo "  --ci               Setup CI/CD workflows"
      echo "  --no-analysis      Skip analysis options setup"
      echo "  --no-tests         Skip test structure setup"
      echo "  -h, --help         Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

log_info() {
  echo -e "${BLUE}$1${NC}"
}

log_success() {
  echo -e "${GREEN}✓ $1${NC}"
}

log_warning() {
  echo -e "${YELLOW}⚠  $1${NC}"
}

log_error() {
  echo -e "${RED}✗ $1${NC}"
}

log_verbose() {
  if [ "$VERBOSE" = true ]; then
    echo -e "  ${GREEN}✓${NC} $1"
  fi
}

create_folder() {
  local path=$1
  if [ ! -d "$path" ]; then
    mkdir -p "$path"
    log_verbose "Created folder: $path"
  fi
}

create_file() {
  local filepath=$1
  local content=$2
  
  if [ -f "$filepath" ] && [ "$OVERWRITE" = false ]; then
    log_verbose "Skipped existing: $filepath"
    return
  fi
  
  local dir=$(dirname "$filepath")
  mkdir -p "$dir"
  echo "$content" > "$filepath"
  log_verbose "Created file: $filepath"
}

validate_project() {
  log_info " Validating project structure..."
  
  if [ ! -f "pubspec.yaml" ]; then
    log_error "pubspec.yaml not found. Run this script from Flutter project root."
    exit 1
  fi
  
  if [ ! -d "lib" ]; then
    log_error "lib directory not found."
    exit 1
  fi
  
  if [ ! -d ".flutter-plugins" ] && [ ! -f ".flutter-plugins" ]; then
    log_warning "Not a Flutter project? Continuing anyway..."
  fi
  
  log_success "Project validation passed"
}

PROJECT_NAME=$(grep "^name:" pubspec.yaml | sed 's/name: //' | tr -d ' ')

setup_core_structure() {
  log_info "\n Setting up core structure..."
  
  create_folder "lib/core/base"
  create_folder "lib/core/constants"
  create_folder "lib/core/di"
  create_folder "lib/core/error"
  create_folder "lib/core/extensions"
  create_folder "lib/core/network/interceptors"
  create_folder "lib/core/network/models"
  create_folder "lib/core/resources"
  create_folder "lib/core/routing"
  create_folder "lib/core/services"
  create_folder "lib/core/utils"
  create_folder "lib/core/widgets/buttons"
  create_folder "lib/core/widgets/dialogs"
  create_folder "lib/core/widgets/loaders"
  create_folder "lib/core/widgets/inputs"
  
  create_file "lib/core/base/base_bloc.dart" "import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'base_event.dart';
import 'base_state.dart';

abstract class BaseBloc<E extends BaseEvent, S extends BaseState>
    extends Bloc<E, S> {
  BaseBloc(S initialState) : super(initialState);
  
  @override
  void onEvent(E event) {
    super.onEvent(event);
    // Log events in debug mode
  }
  
  @override
  void onChange(Change<S> change) {
    super.onChange(change);
    // Log state changes in debug mode
  }
}"

  create_file "lib/core/base/base_state.dart" "import 'package:equatable/equatable.dart';

abstract class BaseState extends Equatable {
  const BaseState();
  
  @override
  List<Object?> get props => [];
}"

  create_file "lib/core/base/base_event.dart" "import 'package:equatable/equatable.dart';

abstract class BaseEvent extends Equatable {
  const BaseEvent();
  
  @override
  List<Object?> get props => [];
}"

  create_file "lib/core/di/service_locator.dart" "import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'service_locator.config.dart';

final GetIt getIt = GetIt.instance;

@injectableInit
void configureDependencies() => getIt.init();"

  create_file "lib/core/di/injector.dart" "// Dependency injection configuration
// TODO: Configure injectable dependencies"

  create_file "lib/core/error/exceptions.dart" "class ServerException implements Exception {
  final String message;
  const ServerException([this.message = 'Server error occurred']);
}

class NetworkException implements Exception {
  final String message;
  const NetworkException([this.message = 'No internet connection']);
}

class CacheException implements Exception {
  final String message;
  const CacheException([this.message = 'Cache error occurred']);
}"

  create_file "lib/core/error/failures.dart" "import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);
  
  @override
  List<Object> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure([String message = 'Server error']) : super(message);
}

class NetworkFailure extends Failure {
  const NetworkFailure([String message = 'Network error']) : super(message);
}

class CacheFailure extends Failure {
  const CacheFailure([String message = 'Cache error']) : super(message);
}

class InvalidCredentialsFailure extends Failure {
  const InvalidCredentialsFailure([String message = 'Invalid credentials']) : super(message);
}"

  create_file "lib/core/network/dio_client.dart" "import 'package:dio/dio.dart';

class DioClient {
  static Dio createDio() {
    final options = BaseOptions(
      baseUrl: const String.fromEnvironment('BASE_URL', defaultValue: 'https://api.example.com'),
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
    );
    
    final dio = Dio(options);
    
    // Add interceptors
    dio.interceptors.add(LogInterceptor(
      request: true,
      requestBody: true,
      responseBody: true,
      error: true,
    ));
    
    return dio;
  }
}"

  create_file "lib/core/utils/logger.dart" "import 'package:logger/logger.dart';

final logger = Logger(
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 8,
    lineLength: 120,
    colors: true,
    printEmojis: true,
    printTime: false,
  ),
);"

  create_file "lib/core/utils/validators.dart" "class Validators {
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}\$').hasMatch(email);
  }
  
  static bool isValidPassword(String password) {
    return password.length >= 8;
  }
  
  static bool isValidPhone(String phone) {
    return RegExp(r'^\+?[1-9]\d{1,14}\$').hasMatch(phone);
  }
}"

  create_file "lib/core/constants/app_constants.dart" "// Application constants
class AppConstants {
  static const String appName = '$PROJECT_NAME';
  static const String appVersion = '1.0.0';
}"

  create_file "lib/core/constants/api_constants.dart" "// API constants
class ApiConstants {
  static const String baseUrl = String.fromEnvironment('BASE_URL', defaultValue: 'https://api.example.com');
  static const Duration timeout = Duration(seconds: 30);
}"

  create_file "lib/core/resources/colors.dart" "import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF2196F3);
  static const Color secondary = Color(0xFF03DAC6);
  static const Color error = Color(0xFFB00020);
  static const Color background = Color(0xFFFFFFFF);
}"

  create_file "lib/core/resources/themes.dart" "import 'package:flutter/material.dart';
import 'colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        error: AppColors.error,
      ),
    );
  }
}"

  create_file "lib/core/routing/app_router.dart" "import 'package:go_router/go_router.dart';
import 'route_names.dart';

class AppRouter {
  static GoRouter router = GoRouter(
    routes: [
      // Define routes here
    ],
  );
}"

  create_file "lib/core/init.dart" "export 'constants/app_constants.dart';
export 'constants/api_constants.dart';
export 'di/service_locator.dart';
export 'di/injector.dart';
export 'error/exceptions.dart';
export 'error/failures.dart';
export 'network/dio_client.dart';
export 'resources/colors.dart';
export 'resources/themes.dart';
export 'routing/app_router.dart';
export 'utils/validators.dart';
export 'utils/logger.dart';
export 'base/base_bloc.dart';
export 'base/base_state.dart';
export 'base/base_event.dart';"
}

setup_feature_template() {
  log_info "\n Setting up feature template..."
  
  create_folder "lib/features/_template/data/datasources/remote"
  create_folder "lib/features/_template/data/datasources/local"
  create_folder "lib/features/_template/data/models/request"
  create_folder "lib/features/_template/data/models/response"
  create_folder "lib/features/_template/data/repositories"
  create_folder "lib/features/_template/domain/entities"
  create_folder "lib/features/_template/domain/repositories"
  create_folder "lib/features/_template/domain/usecases"
  create_folder "lib/features/_template/presentation/bloc"
  create_folder "lib/features/_template/presentation/views"
  create_folder "lib/features/_template/presentation/widgets"
  
  create_file "lib/features/_template/README.md" "# Feature Template

Copy this folder and rename it to create a new feature.

## Structure
\`\`\`
feature_name/
├── data/
│   ├── datasources/     # Remote & local data sources
│   ├── models/         # Request/Response models
│   └── repositories/   # Repository implementations
├── domain/
│   ├── entities/       # Business entities
│   ├── repositories/   # Repository interfaces
│   └── usecases/      # Business logic
└── presentation/
    ├── bloc/          # BLoC files
    ├── views/         # Screens
    └── widgets/       # Reusable widgets
\`\`\`

## Steps
1. Copy \`_template\` folder
2. Rename to your feature name
3. Replace \`{{feature_name}}\` and \`{{FeatureName}}\` in files
4. Implement the layers"

  create_file "lib/features/README.md" "# Features

Each feature follows Clean Architecture and BLoC pattern.

## Adding a New Feature
1. Copy the \`_template\` folder
2. Rename it to your feature name
3. Implement each layer from data to presentation
4. Add exports in \`feature_name/feature_name.dart\`
5. Register dependencies in DI

## Best Practices
- Keep features independent
- Use dependency injection
- Write tests for each layer
- Follow single responsibility principle"
}

setup_assets() {
  log_info "\n🎨 Setting up assets..."
  
  create_folder "assets/fonts"
  create_folder "assets/icons"
  create_folder "assets/images"
  create_folder "assets/animations"
  create_folder "assets/translations"
  create_folder "assets/sounds"
  
  touch "assets/fonts/.gitkeep"
  touch "assets/icons/.gitkeep"
  touch "assets/images/.gitkeep"
  touch "assets/animations/.gitkeep"
  touch "assets/translations/.gitkeep"
  touch "assets/sounds/.gitkeep"
  
  create_file "assets/README.md" "# Assets

## Structure
- \`fonts/\` - Font files (.ttf, .otf)
- \`icons/\` - SVG icons and icon fonts
- \`images/\` - PNG, JPG, WebP images
- \`animations/\` - Lottie JSON files
- \`translations/\` - JSON localization files
- \`sounds/\` - Audio files (.mp3, .wav)

## Naming Convention
Use snake_case for all asset files:
- \`icon_home.svg\`
- \`image_background.png\`
- \`animation_loading.json\`"
}

setup_config_files() {
  log_info "\n Setting up configuration files..."
  
  create_file ".env" "BASE_URL=https://api.example.com
API_KEY=your_api_key_here
ENV=development"

  create_file ".env.example" "BASE_URL=
API_KEY=
ENV="

  create_file "lib/config/environment.dart" "class Environment {
  static const baseUrl = String.fromEnvironment('BASE_URL');
  static const apiKey = String.fromEnvironment('API_KEY');
  static const env = String.fromEnvironment('ENV');
  
  static bool get isProduction => env == 'production';
  static bool get isDevelopment => env == 'development';
}"

  if [ -f ".gitignore" ]; then
    if ! grep -q ".env" .gitignore; then
      cat >> .gitignore << 'EOF'

# Environment
.env
.env.local
.env.*.local

# Build
build/
.flutter-plugins
.flutter-plugins-dependencies
.packages
.fvm/

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db

# Coverage
coverage/
lcov.info

# Dependency directories
.dart_tool/
.pub-cache/
EOF
    fi
  else
    cat > .gitignore << 'EOF'
# Environment
.env
.env.local
.env.*.local

# Build
build/
.flutter-plugins
.flutter-plugins-dependencies
.packages
.fvm/

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db

# Coverage
coverage/
lcov.info

# Dependency directories
.dart_tool/
.pub-cache/
EOF
  fi
}

create_sample_auth() {
  log_info "\nCreating sample authentication feature..."
  
  create_folder "lib/features/auth/data/datasources/remote"
  create_folder "lib/features/auth/data/datasources/local"
  create_folder "lib/features/auth/data/models/request"
  create_folder "lib/features/auth/data/models/response"
  create_folder "lib/features/auth/data/repositories"
  create_folder "lib/features/auth/domain/entities"
  create_folder "lib/features/auth/domain/repositories"
  create_folder "lib/features/auth/domain/usecases"
  create_folder "lib/features/auth/presentation/bloc"
  create_folder "lib/features/auth/presentation/views"
  create_folder "lib/features/auth/presentation/widgets"
  
  create_file "lib/features/auth/presentation/bloc/auth_bloc.dart" "import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
  }
  
  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      // TODO: Implement login logic
      await Future.delayed(const Duration(seconds: 1));
      emit(const AuthAuthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
  
  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthUnauthenticated());
  }
}"

  create_file "lib/features/auth/presentation/bloc/auth_event.dart" "import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  
  @override
  List<Object?> get props => [];
}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;
  
  const LoginRequested({required this.email, required this.password});
  
  @override
  List<Object?> get props => [email, password];
}

class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}"

  create_file "lib/features/auth/presentation/bloc/auth_state.dart" "import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated();
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  
  @override
  List<Object?> get props => [message];
}"

  create_file "lib/features/auth/presentation/views/login_screen.dart" "import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is AuthLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          return Center(
            child: ElevatedButton(
              onPressed: () {
                context.read<AuthBloc>().add(
                  const LoginRequested(email: 'test@example.com', password: 'password'),
                );
              },
              child: const Text('Login'),
            ),
          );
        },
      ),
    );
  }
}"

  create_file "lib/features/auth/auth.dart" "export 'presentation/bloc/auth_bloc.dart';
export 'presentation/bloc/auth_event.dart';
export 'presentation/bloc/auth_state.dart';
export 'presentation/views/login_screen.dart';"
}

setup_ci() {
  log_info "\n Setting up CI/CD..."
  
  create_folder ".github/workflows"
  
  create_file ".github/workflows/flutter-ci.yml" "name: Flutter CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  analyze:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'
      - run: flutter pub get
      - run: flutter analyze
      - run: dart format --output=none --set-exit-if-changed .

  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'
      - run: flutter pub get
      - run: flutter test --coverage
      - uses: codecov/codecov-action@v3
        with:
          files: ./coverage/lcov.info"
}

setup_analysis() {
  log_info "\n🔍 Setting up analysis options..."
  
  create_file "analysis_options.yaml" "include: package:flutter_lints/flutter.yaml

analyzer:
  exclude:
    - '**/*.g.dart'
    - '**/*.freezed.dart'
    - '**/*.gr.dart'
    - '**/generated/'
  strong-mode:
    implicit-casts: false
    implicit-dynamic: false

linter:
  rules:
    - always_declare_return_types
    - avoid_print
    - avoid_returning_null_for_void
    - avoid_unnecessary_containers
    - camel_case_types
    - prefer_const_constructors
    - prefer_final_fields
    - use_key_in_widget_constructors"
}

setup_tests() {
  log_info "\n Setting up test structure..."
  
  create_folder "test/core/utils"
  create_folder "test/core/mocks"
  create_folder "test/features/auth"
  create_folder "test/widgets"
  
  create_file "test/test_helper.dart" "import 'package:flutter_test/flutter_test.dart';

class TestHelper {
  static void setUpAll() {
    // Global test setup
  }
  
  static void tearDownAll() {
    // Global test teardown
  }
}"
}

# Documentation
generate_documentation() {
  log_info "\n Generating documentation..."
  
  create_file "README.md" "# $PROJECT_NAME

Flutter application built with Clean Architecture and BLoC pattern.

##  Getting Started

### Prerequisites
- Flutter 3.x
- Dart 3.x

### Installation
\`\`\`bash
# Clone repository
git clone <repository-url>
cd $PROJECT_NAME

# Install dependencies
flutter pub get

# Generate code
dart run build_runner build --delete-conflicting-outputs

# Run application
flutter run
\`\`\`

##  Project Structure

\`\`\`
lib/
├── core/              # Core functionality
│   ├── base/         # Base classes
│   ├── constants/    # Constants
│   ├── di/           # Dependency injection
│   ├── error/        # Error handling
│   ├── network/      # Network layer
│   ├── resources/    # Themes, colors
│   ├── routing/      # Navigation
│   ├── services/     # Services
│   ├── utils/        # Utilities
│   └── widgets/      # Shared widgets
├── features/         # Features
│   └── _template/    # Feature template
└── config/           # Configuration

test/                 # Tests
assets/              # Assets
\`\`\`

## Architecture

This project follows Clean Architecture with three layers:

1. **Presentation Layer** (UI + BLoC)
2. **Domain Layer** (Business Logic)
3. **Data Layer** (Repositories + Data Sources)

## Development

### Adding a New Feature
1. Copy \`lib/features/_template\`
2. Rename to your feature name
3. Implement each layer

### Running Tests
\`\`\`bash
flutter test
\`\`\`

### Code Generation
\`\`\`bash
dart run build_runner build --delete-conflicting-outputs
\`\`\`

## Dependencies

- flutter_bloc: State management
- get_it: Dependency injection
- dio: HTTP client
- go_router: Navigation
- equatable: Value equality

## License

[Your License]"

  create_file "ARCHITECTURE.md" "# Architecture

This project follows Clean Architecture principles with BLoC pattern.

## Layers

### Presentation Layer
- **Views**: UI screens
- **Widgets**: Reusable components
- **BLoC**: Business Logic Components

### Domain Layer
- **Entities**: Business objects
- **Use Cases**: Business rules
- **Repository Interfaces**: Abstract data contracts

### Data Layer
- **Models**: Data transfer objects
- **Repositories**: Repository implementations
- **Data Sources**: Remote and local data sources

## Data Flow

1. User interacts with View
2. View dispatches Event to BLoC
3. BLoC calls Use Case
4. Use Case calls Repository
5. Repository fetches from Data Source
6. Data flows back to View through States

## Best Practices

- Keep features independent
- Use dependency injection
- Write tests for each layer
- Follow SOLID principles"
}

update_pubspec() {
  log_info "\n📦 Updating pubspec.yaml..."
  
  if [ -f "pubspec_backup.yaml" ]; then
    log_warning "Backup already exists, skipping pubspec update"
    return
  fi
  
  cp pubspec.yaml pubspec_backup.yaml
  
  cat >> pubspec.yaml << 'EOF'

  # BLoC Architecture Dependencies
  flutter_bloc: ^8.1.3
  equatable: ^2.0.5
  dartz: ^0.10.1
  
  # Dependency Injection
  get_it: ^7.6.4
  injectable: ^2.3.0
  
  # Navigation
  go_router: ^13.0.0
  
  # Network
  dio: ^5.4.0
  
  # Utilities
  logger: ^2.0.2
  shared_preferences: ^2.2.2
  intl: ^0.19.0

dev_dependencies:
  build_runner: ^2.4.7
  injectable_generator: ^2.4.0
  mocktail: ^1.0.1
  flutter_lints: ^3.0.1

flutter:
  assets:
    - assets/fonts/
    - assets/icons/
    - assets/images/
    - assets/animations/
    - assets/translations/
EOF
  
  log_success "pubspec.yaml updated (backup saved as pubspec_backup.yaml)"
}

log_info "\n📦 Upgrading dependencies..."
if flutter pub upgrade; then
    log_success "Dependencies upgraded successfully"
    main
else
    log_error "Failed to upgrade dependencies"
    exit 1
fi

main() {
  echo -e "${BLUE}🚀 Starting Enhanced Dart BLoC Project Structure Setup...${NC}\n"
  
  validate_project
  
  setup_core_structure
  setup_feature_template
  setup_assets
  setup_config_files
  
  if [ "$CREATE_SAMPLE" = true ]; then
    create_sample_auth
  fi
  
  if [ "$SETUP_CI" = true ]; then
    setup_ci
  fi
  
  if [ "$SKIP_ANALYSIS" = false ]; then
    setup_analysis
  fi
  
  if [ "$SKIP_TESTS" = false ]; then
    setup_tests
  fi
  
  generate_documentation
  update_pubspec
  
  echo -e "\n${GREEN} Project setup completed successfully!${NC}"
  echo -e "\n${BLUE} Next steps:${NC}"
  echo "   1. Run: flutter pub get"
  echo "   2. Run: dart run build_runner build --delete-conflicting-outputs"
  echo "   3. Check README.md for project structure details"
  echo -e "\n${YELLOW}Note: pubspec.yaml has been updated. Review the changes before running pub get.${NC}"
}
main