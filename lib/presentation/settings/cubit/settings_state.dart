import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class SettingsState extends Equatable {
  const SettingsState({required this.themeMode});

  final ThemeMode themeMode;

  static SettingsState initial() =>
      const SettingsState(themeMode: ThemeMode.system);

  SettingsState copyWith({ThemeMode? themeMode}) =>
      SettingsState(themeMode: themeMode ?? this.themeMode);

  @override
  List<Object> get props => [themeMode];
}
