import 'package:flutter/material.dart';

/// One dot per focus session in the current cycle toward a long break.
class CycleDots extends StatelessWidget {
  const CycleDots({
    super.key,
    required this.done,
    required this.total,
    required this.color,
  });

  final int done;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final outline = Theme.of(context).colorScheme.outline;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < total; i++)
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < done ? color : Colors.transparent,
              border: Border.all(color: i < done ? color : outline, width: 1.5),
            ),
          ),
      ],
    );
  }
}
