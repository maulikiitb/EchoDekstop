import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';

part 'settings_system_state.dart';

class SettingsSystemCubit extends Cubit<SettingsSystemState> {
  SettingsSystemCubit() : super(const SettingsSystemInitial());

  Future<void> load() async {
    // Battery optimisation is an Android-only concept; nothing to check on desktop.
    emit(const SettingsSystemLoaded(isBatteryOptimizationDisabled: null));
  }

  Future<void> requestBatteryOptimizationIgnore() async {}
}
