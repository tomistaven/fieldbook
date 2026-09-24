import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/settings_cubit.dart';

/// The add-button side chosen in Settings. Use only in `build`: it
/// subscribes the widget to that one setting.
extension AddButtonSide on BuildContext {
  bool get addButtonsOnLeft =>
      select((SettingsCubit c) => c.state.addButtonsOnLeft);

  FloatingActionButtonLocation get addButtonLocation => addButtonsOnLeft
      ? FloatingActionButtonLocation.startFloat
      : FloatingActionButtonLocation.endFloat;
}