import 'dart:io';

void main() async {
  print("Starting Dart BLoC Project Structure Setup...");
  final Directory libDir = Directory("lib");
  if (!libDir.existsSync()) {
    print("lib folder not found. Script terminated.");
    exit(1);
  }

  try {
    createFolder("lib/core/cache");
    createFile("lib/core/cache/store_cache.dart");
    createFolder("lib/common/app");
    createFile("lib/common/app/cache_helper.dart");
    createFolder("lib/common/entity");
    createFolder("lib/common/singleton");
    createFile("lib/common/singleton/cache.dart");
    createFolder("lib/common/widget");
    createWidgetFiles();
    createFolder("lib/error");
    createFile("lib/error/exception.dart");
    createFile("lib/error/failure.dart");
    createFolder("lib/extensions");
    createFile("lib/extensions/context_extensions.dart");
    createFile("lib/extensions/string_extensions.dart");
    createFile("lib/extensions/text_extensions.dart");
    createFile("lib/extensions/theme_extensions.dart");
    createFile("lib/extensions/widget_extensions.dart");
    createFolder("lib/network");
    createFile("lib/network/network_client.dart");
    createFolder("lib/res/styles");
    createFile("lib/res/media.dart");
    createFile("lib/res/styles/colors.dart");
    createFile("lib/res/styles/text.dart");
    createFolder("lib/service");
    createFile("lib/service/codec.dart");
    createFile("lib/service/injection_container.dart");
    createFile("lib/service/injection_container.main.dart");
    createFile("lib/service/navigation_helper.dart");
    createFile("lib/service/router.dart");
    createFile("lib/service/router.main.dart");
    createFolder("lib/usecase");
    createFile("lib/usecase/usecase.dart");
    createFolder("lib/utils");
    createFile("lib/utils/core_utils.dart");
    createFile("lib/utils/date_time_formatter.dart");
    createFile("lib/utils/error_response.dart");
    createFile("lib/utils/go_router_refresh_stream.dart");
    createFile("lib/utils/hero_key_generator.dart");
    createFile("lib/utils/image_preloader.dart");
    createFile("lib/utils/lifecycle_event_handler.dart");
    createFile("lib/utils/responsive.dart");
    createFile("lib/utils/typedefs.dart");
    createFolder("lib/utils/constants");
    createFile("lib/utils/constants/endpoint.dart");
    createFile("lib/utils/constants/network_constants.dart");
    createFolder("lib/widgets");
    createFile("lib/widgets/verified_badged.dart");
    createFolder("lib/src/my_app");
    createFile("lib/src/my_app/my_app.dart");
    createFile(
      "dependency_requirement.txt",
      content: "flutter_bloc\nequatable\ngo_router\ndartz\nget_it",
    );

    print("All folders & files were created successfully!");
  } catch (e) {
    print("Something went wrong: $e");
  }
}

void createFolder(String path) {
  final dir = Directory(path);
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
    print("Created folder: $path");
  } else {
    print("Folder already exists, skipping: $path");
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
