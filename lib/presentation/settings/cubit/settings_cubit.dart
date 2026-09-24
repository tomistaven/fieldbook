import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'settings_state.dart';

/// App-wide preferences, persisted in [SharedPreferences].
class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(this._prefs) : super(SettingsState.initial()) {
    _loadAll();
  }

  final SharedPreferences _prefs;

  static const _themeKey = 'theme_mode';
  static const _addButtonsOnLeftKey = 'add_buttons_on_left';

  void _loadAll() {
    final mode = switch (_prefs.getString(_themeKey)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    emit(state.copyWith(
      themeMode: mode,
      addButtonsOnLeft: _prefs.getBool(_addButtonsOnLeftKey) ?? false,
    ));
  }

  void setAddButtonsOnLeft(bool value) {
    _prefs.setBool(_addButtonsOnLeftKey, value);
    emit(state.copyWith(addButtonsOnLeft: value));
  }

  void setTheme(ThemeMode mode) {
    _prefs.setString(_themeKey, mode.name);
    emit(state.copyWith(themeMode: mode));
  }
}