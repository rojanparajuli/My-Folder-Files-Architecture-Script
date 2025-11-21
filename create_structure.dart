import 'dart:io';

void main() async {
  print(" Starting Dart BLoC Project Structure Setup...\n");

  final Directory libDir = Directory("lib");
  if (!libDir.existsSync()) {
    print(" lib folder not found. Script terminated.");
    exit(1);
  }

  try {
    createFolder("lib/core/cache");
    createFile("lib/core/cache/store_cache.dart");
    createFolder("lib/core/common/app");
    createFile("lib/core/common/app/cache_helper.dart");
    createFolder("lib/core/common/entity");
    createFolder("lib/core/common/singleton");
    createFile("lib/core/common/singleton/cache.dart");
    createFolder("lib/core/common/widget");
    createWidgetFiles();
    createFolder("lib/core/error");
    createFile("lib/core/error/exception.dart");
    createFile("lib/core/error/failure.dart");
    createFolder("lib/core/extensions");
    createFile("lib/core/extensions/context_extensions.dart");
    createFile("lib/core/extensions/string_extensions.dart");
    createFile("lib/core/extensions/text_extensions.dart");
    createFile("lib/core/extensions/theme_extensions.dart");
    createFile("lib/core/extensions/widget_extensions.dart");
    createFolder("lib/core/network");
    createFile("lib/core/network/network_client.dart");
    createFolder("lib/core/res/styles");
    createFile("lib/core/res/media.dart");
    createFile("lib/core/res/styles/colors.dart");
    createFile("lib/core/res/styles/text.dart");
    createFolder("lib/core/service");
    createFile("lib/core/service/codec.dart");
    createFile("lib/core/service/injection_container.dart");
    createFile("lib/core/service/injection_container.main.dart");
    createFile("lib/core/service/navigation_helper.dart");
    createFile("lib/core/service/router.dart");
    createFile("lib/core/service/router.main.dart");
    createFolder("lib/core/usecase");
    createFile("lib/core/usecase/usecase.dart");
    createFolder("lib/core/utils");
    createFile("lib/core/utils/core_utils.dart");
    createFile("lib/core/utils/date_time_formatter.dart");
    createFile("lib/core/utils/error_response.dart");
    createFile("lib/core/utils/go_router_refresh_stream.dart");
    createFile("lib/core/utils/hero_key_generator.dart");
    createFile("lib/core/utils/image_preloader.dart");
    createFile("lib/core/utils/lifecycle_event_handler.dart");
    createFile("lib/core/utils/responsive.dart");
    createFile("lib/core/utils/typedefs.dart");
    createFolder("lib/core/utils/constants");
    createFile("lib/core/utils/constants/endpoint.dart");
    createFile("lib/core/utils/constants/network_constants.dart");
    createFolder("lib/core/widgets");
    createFile("lib/core/widgets/verified_badged.dart");
    createFolder("lib/src/my_app");
    createFile("lib/src/my_app/my_app.dart");
    createFolder("assets/images");
    createFolder("assets/icons");
    createFolder("assets/fonts");
    createFolder("assets/lottie");
    createFolder("assets/videos");
    createFolder("assets/audio");
    createFolder("assets/animations");
    createFile(
      "dependency_requirement.txt",
      content: "flutter_bloc\nequatable\ngo_router\ndartz\nget_it",
    );
    migrateMyAppClassToMyAppFolder();
    setupWidgetTest();

    print(" All folders & files were created successfully!\n");
  } catch (e) {
    print(" Something went wrong: $e");
  }
}

void createFolder(String path) {
  final dir = Directory(path);
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
    print("Created folder: $path");
  } else {
    print(" Folder already exists, skipping: $path");
  }
}

void createFile(String path, {String content = ""}) {
  final file = File(path);
  if (!file.existsSync()) {
    file.createSync(recursive: true);
    file.writeAsStringSync(content);
    print("Created file: $path");
  } else {
    print("File already exists, skipping: $path");
  }
}

void createWidgetFiles() {
  final files = [
    "adaptive_icons.dart",
    "adaptive_loading_widget.dart",
    "adaptive_custom_shimmer.dart",
    "custom_text_button.dart",
    "dynamic_appbar.dart",
    "dynamic_loading_widget.dart",
    "ecomly.dart",
    "primary_button.dart",
    "custom_textfields.dart",
  ];

  for (var file in files) {
    createFile("lib/common/widget/$file");
  }
}

void migrateMyAppClassToMyAppFolder() {
  final mainFile = File("lib/main.dart");

  if (!mainFile.existsSync()) {
    print("ERROR: main.dart not found in lib/. Cannot configure MyApp.\n");
    return;
  }

  final myAppFile = File("lib/src/my_app/my_app.dart");
  myAppFile.writeAsStringSync("""
import 'package:flutter/material.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('My App'),
        ),
        body: const Center(
          child: Text('Hello, world!'),
        ),
      ),
    );
  }
}
""");

  print(" MyApp template created in lib/src/my_app/my_app.dart");

  final projectName = Directory.current.path.split("/").last;

  mainFile.writeAsStringSync("""
import 'package:flutter/material.dart';
import 'package:$projectName/src/my_app/my_app.dart';

void main() {
  runApp(const MyApp());
}
""");

  print(" main.dart updated to use clean MyApp\n");
}

void setupWidgetTest() {
  final testFolder = Directory("test");
  if (!testFolder.existsSync()) {
    testFolder.createSync(recursive: true);
    print("Created test folder: test/");
  }

  final widgetTestFile = File("test/widget_test.dart");
  final projectName = Directory.current.path.split("/").last;

  if (!widgetTestFile.existsSync()) {
    widgetTestFile.writeAsStringSync("""
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:${projectName}/src/my_app/my_app.dart';

void main() {
  testWidgets('MyApp widget test', (WidgetTester tester) async {
    // Build MyApp
    await tester.pumpWidget(const MyApp());

    // Verify if AppBar title is present
    expect(find.text('My App'), findsOneWidget);

    // Verify if 'Hello, world!' text is present
    expect(find.text('Hello, world!'), findsOneWidget);
  });
}
""");
    print("Created test/widget_test.dart with MyApp import");
  } else {
    print("test/widget_test.dart already exists, skipping.");
  }
}
