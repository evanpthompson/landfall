import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:landfall_shared/landfall_shared.dart';

import 'package:display/src/data/discovery/mdns_server_discovery.dart';
import 'package:display/src/data/server/server_health_checker.dart';
import 'setup_wizard_state.dart';

export 'setup_wizard_state.dart';

class SetupWizardCubit extends Cubit<SetupWizardState> {
  SetupWizardCubit({
    required DisplaySettingsRepository settingsRepository,
    required ServerHealthChecker healthChecker,
    MdnsServerDiscovery? discovery,
    bool autoPickSingle = false,
  })  : _settings = settingsRepository,
        _health = healthChecker,
        _discovery = discovery,
        _autoPickSingle = autoPickSingle,
        super(const SetupWizardAt(SetupWizardStep.discover));

  final DisplaySettingsRepository _settings;
  final ServerHealthChecker _health;
  final MdnsServerDiscovery? _discovery;
  final bool _autoPickSingle;

  String _serverUrl = '';
  StreamSubscription<List<DiscoveredServer>>? _discoverySub;

  /// Called on startup to resume at the correct step if a previous run
  /// partially completed. When no URL is stored, starts at the discover step.
  Future<void> init() async {
    final s = await _settings.getSettings();
    _serverUrl = s.serverUrl;

    if (s.serverUrl.isEmpty) {
      emit(const SetupWizardAt(SetupWizardStep.discover));
    } else if (s.locationName.isEmpty) {
      emit(SetupWizardAt(SetupWizardStep.location, serverUrl: s.serverUrl));
    } else {
      emit(SetupWizardAt(SetupWizardStep.linkAccount, serverUrl: s.serverUrl));
    }
  }

  /// Starts mDNS discovery. Call this when the discover step is shown.
  ///
  /// Idempotent — calling multiple times starts discovery at most once.
  void startDiscovery() {
    if (_discoverySub != null || _discovery == null) return;
    _discovery.start();
    _discoverySub = _discovery.servers.listen(_onDiscoveryUpdate);
  }

  void _onDiscoveryUpdate(List<DiscoveredServer> servers) {
    if (isClosed) return;

    if (_autoPickSingle && servers.length == 1) {
      selectDiscoveredServer(servers.first.serverUrl);
      return;
    }

    final current = state;
    if (current is SetupWizardAt && current.step == SetupWizardStep.discover) {
      emit(SetupWizardAt(SetupWizardStep.discover, discoveredServers: servers));
    }
  }

  /// Selects a server found via discovery. Validates reachability and advances
  /// to the location step on success, same as [submitServerUrl].
  Future<void> selectDiscoveredServer(String serverUrl) async {
    _stopDiscovery();
    await submitServerUrl(serverUrl);
  }

  /// Skips discovery and advances to the manual URL entry step.
  void skipDiscovery() {
    _stopDiscovery();
    emit(const SetupWizardAt(SetupWizardStep.serverUrl));
  }

  /// Validates [raw] as a reachable server URL, then advances to step 2.
  Future<void> submitServerUrl(String raw) async {
    emit(const SetupWizardValidating());

    final trimmed = raw.trim();
    final url = trimmed.endsWith('/') ? trimmed : '$trimmed/';

    final reachable = await _health.ping(url);
    if (!reachable) {
      emit(const SetupWizardStepError(
        'Could not reach the server. Check the URL and try again.',
        SetupWizardStep.serverUrl,
      ));
      return;
    }

    _serverUrl = url;
    final current = await _settings.getSettings();
    await _settings.saveSettings(current.copyWith(serverUrl: url));
    emit(SetupWizardAt(SetupWizardStep.location, serverUrl: _serverUrl));
  }

  /// Saves [locationName] (may be empty if skipped) and advances to step 3.
  Future<void> submitLocation(String locationName) async {
    final current = await _settings.getSettings();
    await _settings.saveSettings(
      current.copyWith(locationName: locationName.trim()),
    );
    emit(SetupWizardAt(SetupWizardStep.linkAccount, serverUrl: _serverUrl));
  }

  /// Advances from the link-account step to the done step.
  void advanceToDone() {
    emit(SetupWizardAt(SetupWizardStep.done, serverUrl: _serverUrl));
  }

  /// Marks the wizard as complete and emits [SetupWizardComplete].
  Future<void> complete() async {
    final current = await _settings.getSettings();
    await _settings.saveSettings(current.copyWith(wizardComplete: true));
    emit(SetupWizardComplete(serverUrl: _serverUrl));
  }

  void _stopDiscovery() {
    _discoverySub?.cancel();
    _discoverySub = null;
    _discovery?.stop();
  }

  @override
  Future<void> close() {
    _stopDiscovery();
    return super.close();
  }
}
