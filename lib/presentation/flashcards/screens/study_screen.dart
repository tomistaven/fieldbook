import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/repositories/flashcard_repository.dart';
import '../../../injection_container.dart';
import '../cubit/study_cubit.dart';
import '../cubit/study_state.dart';
import '../widgets/flip_card.dart';

class StudyScreen extends StatelessWidget {
  const StudyScreen({super.key, required this.deckId, required this.deckName});

  final int deckId;
  final String deckName;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // Screen-scoped: BlocProvider closes it when the screen is popped.
      create: (_) => StudyCubit(sl<FlashcardRepository>(), deckId),
      child: Scaffold(
        appBar: AppBar(title: Text(deckName)),
        body: BlocBuilder<StudyCubit, StudyState>(
          builder: (context, state) {
            if (state.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.finished) return _Summary(state: state);
            return _Session(state: state);
          },
        ),
      ),
    );
  }
}

class _Session extends StatelessWidget {
  const _Session({required this.state});

  final StudyState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<StudyCubit>();
    final card = state.current!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            LinearProgressIndicator(
              value: state.position / state.queue.length,
              minHeight: 4,
              borderRadius: BorderRadius.circular(2),
            ),
            const SizedBox(height: 8),
            Text(
              '${state.position + 1} / ${state.queue.length}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: FlipCard(
                    // Position in the key: the same card can reappear.
                    key: ValueKey('${card.id}-${state.position}'),
                    front: card.front,
                    back: card.back,
                    revealed: state.revealed,
                    onTap: state.revealed ? null : cubit.reveal,
                  ),
                ),
              ),
            ),
            if (!state.revealed)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: cubit.reveal,
                  child: const Text('Show answer'),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(color: AppColors.danger),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => cubit.answer(knew: false),
                      icon: const Icon(Icons.replay),
                      label: const Text('Again'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => cubit.answer(knew: true),
                      icon: const Icon(Icons.check),
                      label: const Text('Got it'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.state});

  final StudyState state;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events_outlined,
                size: 64, color: AppColors.accent),
            const SizedBox(height: 16),
            Text('Session complete',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              '${state.correctFirstTry} of ${state.total} right on the first try',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: context.read<StudyCubit>().start,
                  child: const Text('Study again'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
