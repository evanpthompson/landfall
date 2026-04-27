import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:landfall_shared/landfall_shared.dart';

import 'license_state.dart';

export 'license_state.dart';

class LicenseCubit extends Cubit<LicenseState> {
  LicenseCubit(this._repository) : super(const LicenseLoading());

  final LicenseRepository _repository;

  Future<void> loadStatus() async {
    emit(const LicenseLoading());
    try {
      final status = await _repository.getLicenseStatus();
      emit(LicenseLoaded(status));
    } catch (e) {
      emit(LicenseError(e.toString()));
    }
  }

  Future<void> activateLicense(String key) async {
    emit(const LicenseActivating());
    try {
      final status = await _repository.activateLicense(key);
      emit(LicenseLoaded(status));
    } catch (e) {
      emit(LicenseError(e.toString()));
    }
  }
}
