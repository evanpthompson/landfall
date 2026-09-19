import 'dart:io';

/// What the server should do about the permissions on `config/passwords.yaml`.
enum PasswordsFileVerdict {
  /// Permissions are fine.
  ok,

  /// World-readable, but this is a single-user dev box — say so and continue.
  warn,

  /// World-readable somewhere real — refuse to start.
  refuse,
}

/// Run modes where a world-readable secrets file is only a warning.
///
/// Everything else — including an unrecognised mode — is treated as real, so a
/// typo in `-m` cannot quietly downgrade the check.
const _forgivingRunModes = {'development', 'test'};

/// The run mode the server will use, resolved from the sources Serverpod reads
/// in the same order: `-m`/`--mode`, then `SERVERPOD_RUN_MODE`, then
/// `development`.
///
/// Duplicated here rather than read off `Serverpod` because the permission
/// check has to happen *before* the server is constructed — by the time
/// Serverpod exists it has already loaded the very file being checked.
String resolveRunMode(List<String> args, {Map<String, String>? environment}) {
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg == '--mode' || arg == '-m') {
      if (i + 1 < args.length) return args[i + 1];
    } else if (arg.startsWith('--mode=')) {
      return arg.substring('--mode='.length);
    }
  }

  final env = environment ?? Platform.environment;
  return env['SERVERPOD_RUN_MODE'] ?? 'development';
}

/// Decides what to do about a `config/passwords.yaml` whose stat [mode] says it
/// is readable by anyone on the box.
///
/// Warning and carrying on was the old behaviour in every mode. On a Pi that
/// anyone on the LAN can reach, a warning nobody is watching is not a control:
/// the OAuth client secrets, the HMAC key and the Stripe secret all live in
/// that file. Development keeps the warning so a 644 checkout can still be
/// fixed from a running server.
PasswordsFileVerdict passwordsFileVerdict({
  required int mode,
  required String runMode,
}) {
  // Bit 2 of the lowest octet = world-read permission.
  final worldReadable = mode & 0x4 != 0;
  if (!worldReadable) return PasswordsFileVerdict.ok;

  return _forgivingRunModes.contains(runMode)
      ? PasswordsFileVerdict.warn
      : PasswordsFileVerdict.refuse;
}
