import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class SettingsState extends Equatable {
  const SettingsState({
    required this.themeMode,
    required this.addButtonsOnLeft,
  });

  final ThemeMode themeMode;

  /// Places the add button on each list screen on the left instead of the
  /// right, for one-handed use.
  final bool addButtonsOnLeft;

  static SettingsState initial() => const SettingsState(
    themeMode: ThemeMode.system,
    addButtonsOnLeft: false,
  );

  SettingsState copyWith({ThemeMode? themeMode, bool? addButtonsOnLeft}) =>
      SettingsState(
        themeMode: themeMode ?? this.themeMode,
        addButtonsOnLeft: addButtonsOnLeft ?? this.addButtonsOnLeft,
      );

  @override
  List<Object> get props => [themeMode, addButtonsOnLeft];
}