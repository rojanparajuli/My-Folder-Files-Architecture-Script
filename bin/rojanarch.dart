import 'dart:io';


const _states = <String, _StateOption>{
  '1': _StateOption('bloc', 'BLoC', 'create_structure_bloc.dart'),
  '2': _StateOption('provider', 'Provider', 'create_structure_provider.dart'),
  '3': _StateOption('riverpod', 'Riverpod', 'create_structure_riverpod.dart'),
  '4': _StateOption('getx', 'GetX', 'create_structure_getx.dart'),
  '5': _StateOption('signals', 'Signals', 'create_structure_signals.dart'),
};

class _StateOption {
  final String key;
  final String label;
  final String scriptFile;
  const _StateOption(this.key, this.label, this.scriptFile);
}

Future<void> main(List<String> rawArgs) async {
  final args = [...rawArgs];

  if (_flag(args, '--help') || _flag(args, '-h')) {
    _printHelp();
    return;
  }

  _banner();

  if (!await _commandExists('flutter')) {
    _err(
      "Flutter doesn't seem to be on your PATH. Install it from "
      "https://docs.flutter.dev/get-started/install and re-run `rojanarch`.",
    );
    exit(1);
  }

  final alreadyInProject = File('pubspec.yaml').existsSync();
  Directory? createdDir;

  if (!alreadyInProject) {
    final name = _takeOption(args, '--name') ?? _askProjectName();
    _info("\n📦 Creating Flutter project '$name'...\n");

    final create = await Process.start(
      'flutter',
      ['create', name],
      mode: ProcessStartMode.inheritStdio,
    );
    final createCode = await create.exitCode;
    if (createCode != 0) {
      _err("flutter create failed (exit code $createCode). Aborting.");
      exit(createCode);
    }

    createdDir = Directory(name);
    Directory.current = createdDir.path;
  } else {
    _info("\n📁 Existing Flutter project detected in this folder — reusing it.\n");
  }

  final stateKey = _takeOption(args, '--state');
  final chosen = stateKey != null
      ? _states.values.firstWhere(
          (s) => s.key == stateKey.toLowerCase(),
          orElse: () => throw ArgumentError(
            "Unknown --state '$stateKey'. Valid values: "
            "${_states.values.map((s) => s.key).join(', ')}",
          ),
        )
      : _askStateManagement();

  _info("\n🏗  Applying ${chosen.label} Clean Architecture structure...\n");

  
  final exePath = _resolveCompiledScaffoldPath(chosen.key);
  final Process scaffold;
  if (exePath != null && File(exePath).existsSync()) {
    scaffold = await Process.start(
      exePath,
      args,
      mode: ProcessStartMode.inheritStdio,
    );
  } else {
    final scriptPath = _resolveScaffoldPath(chosen.scriptFile);
    if (!File(scriptPath).existsSync()) {
      _err("Could not find scaffold script at $scriptPath");
      exit(1);
    }
    scaffold = await Process.start(
      'dart',
      ['run', scriptPath, ...args],
      mode: ProcessStartMode.inheritStdio,
    );
  }
  final scaffoldCode = await scaffold.exitCode;

  if (scaffoldCode != 0) {
    _err("Scaffold step failed (exit code $scaffoldCode).");
    exit(scaffoldCode);
  }

  _success(
    "\n✅ Done! '${Directory.current.path.split(Platform.pathSeparator).last}' "
    "is set up with ${chosen.label}.\n"
    "   cd into it and run: flutter run\n",
  );
}


void _banner() => print('\n🧩 rojanarch — interactive Flutter architecture scaffolder\n');

void _info(String m) => print('\x1B[36m$m\x1B[0m');
void _success(String m) => print('\x1B[32m$m\x1B[0m');
void _err(String m) => stderr.writeln('\x1B[31m✗ $m\x1B[0m');

bool _flag(List<String> args, String name) => args.remove(name);


String? _takeOption(List<String> args, String key) {
  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (a.startsWith('$key=')) {
      args.removeAt(i);
      return a.substring(key.length + 1);
    }
    if (a == key && i + 1 < args.length) {
      final value = args[i + 1];
      args.removeRange(i, i + 2);
      return value;
    }
  }
  return null;
}

Future<bool> _commandExists(String cmd) async {
  try {
    final result = await Process.run(
      Platform.isWindows ? 'where' : 'which',
      [cmd],
    );
    return result.exitCode == 0;
  } catch (_) {
    return false;
  }
}

String _askProjectName() {
  final validName = RegExp(r'^[a-z][a-z0-9_]*$');
  while (true) {
    stdout.write('📛 Flutter project name (lowercase_with_underscores): ');
    final input = stdin.readLineSync()?.trim() ?? '';
    if (validName.hasMatch(input)) return input;
    _err("Invalid name. Use lowercase letters, digits, and underscores, starting with a letter.");
  }
}

_StateOption _askStateManagement() {
  print('Pick a state management approach:');
  for (final s in _states.values) {
    print('  ${s.key}. ${s.label}');
  }
  while (true) {
    stdout.write('Enter a number [1-${_states.length}]: ');
    final input = stdin.readLineSync()?.trim() ?? '';
    final match = _states[input];
    if (match != null) return match;
    _err("Please enter one of: ${_states.keys.join(', ')}");
  }
}


String _resolveScaffoldPath(String fileName) {
  final scriptFile = File(Platform.script.toFilePath());
  final packageRoot = scriptFile.parent.parent; // bin/.. -> package root
  return '${packageRoot.path}${Platform.pathSeparator}scaffolds'
      '${Platform.pathSeparator}$fileName';
}


String? _resolveCompiledScaffoldPath(String stateKey) {
  final selfDir = File(Platform.resolvedExecutable).parent;
  final name = Platform.isWindows
      ? 'rojanarch_$stateKey.exe'
      : 'rojanarch_$stateKey';
  final candidate = '${selfDir.path}${Platform.pathSeparator}$name';
  return File(candidate).existsSync() ? candidate : null;
}

void _printHelp() {
  print("""
rojanarch — interactive Flutter architecture scaffolder

Usage:
  rojanarch [options] [-- <flags forwarded to the scaffold script>]

Options:
  --name=<name>     Project name to pass to `flutter create` (skips the prompt).
                     Skipped entirely if run inside an existing Flutter project
                     (a pubspec.yaml is already present in the current folder).
  --state=<key>     One of: ${_states.values.map((s) => s.key).join(', ')} (skips the prompt).
  -h, --help        Show this help message.

Any other flags (--verbose, --overwrite, --ci, --no-sample, --dry-run,
--rollback, --no-color, ...) are forwarded unchanged to the chosen
create_structure_<state>.dart scaffold script.

Examples:
  rojanarch
  rojanarch --name=my_shop_app --state=bloc
  rojanarch --state=signals --ci --verbose
""");
}
