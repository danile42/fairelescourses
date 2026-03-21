import 'dart:math';

import 'package:flutter/material.dart';

const _positiveMessages = [
  // Warm & uplifting
  'Your friends love you.',
  'You are stronger than you think.',
  'Something wonderful is about to happen.',
  'The world is better with you in it.',
  'You have already survived 100 % of your bad days.',
  'You matter more than you know.',
  'Somewhere, someone is thinking of you with a smile.',
  'You are doing better than you feel right now.',
  'Every expert was once a beginner — keep going.',
  'Your kindness makes a difference, even when you can\'t see it.',
  'Hard times are temporary; your strength is permanent.',
  'You deserve rest, not just productivity.',
  'Small steps still move you forward.',
  'The fact that you care so much shows how good you are.',
  'You are allowed to take up space.',
  'There is only one you, and that is your superpower.',
  'Tea, coffee, or a nap — you deserve whichever you need.',
  'You have faced hard things before, and you rose each time.',
  'Someone out there wishes they had your courage.',
  'Today is not the whole story — the best chapters are ahead.',
  // Grounded & realistic
  'Not every day needs to be great. Today just needs to be okay.',
  'You don\'t have to fix everything today.',
  'Progress isn\'t always visible — but it\'s still happening.',
  'It\'s okay to ask for help. That\'s what people are for.',
  'You are allowed to change your mind.',
  'Feeling overwhelmed just means you care deeply.',
  'Rest is not giving up — it\'s how you keep going.',
  'Some days the win is just getting through it. That counts.',
  'You don\'t have to be cheerful all the time. You just have to keep showing up.',
  'The messy middle is still part of the story.',
];

class EasterEggScreen extends StatefulWidget {
  const EasterEggScreen({super.key});

  @override
  State<EasterEggScreen> createState() => _EasterEggScreenState();
}

class _EasterEggScreenState extends State<EasterEggScreen> {
  bool _started = false;
  late List<String> _shuffled;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _shuffled = List.of(_positiveMessages)..shuffle(Random());
  }

  String get _currentMessage => _shuffled[_index];

  void _onButtonPressed() => setState(() => _started = true);

  void _onYes() => Navigator.of(context).pop();

  void _onNo() {
    setState(() {
      _index++;
      if (_index >= _shuffled.length) {
        // Reshuffle for the next round, avoiding the same message twice in a row
        final last = _shuffled.last;
        _shuffled = List.of(_positiveMessages)..shuffle(Random());
        if (_shuffled.first == last && _shuffled.length > 1) {
          final swap = _shuffled.removeAt(1);
          _shuffled.insert(0, swap);
        }
        _index = 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.primaryContainer,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.08),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: _started ? _buildQuestion(theme) : _buildEntry(theme),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEntry(ThemeData theme) {
    return Column(
      key: const ValueKey('entry'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('✨', style: TextStyle(fontSize: 64)),
        const SizedBox(height: 32),
        FilledButton(
          onPressed: _onButtonPressed,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            textStyle: theme.textTheme.titleLarge,
          ),
          child: const Text('Everything will be fine!'),
        ),
      ],
    );
  }

  Widget _buildQuestion(ThemeData theme) {
    return Column(
      key: ValueKey(_currentMessage),
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('💛', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 24),
        Text(
          _currentMessage,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: theme.colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 40),
        Text(
          'Do you feel better now?',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton(
              onPressed: _onNo,
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.onPrimaryContainer,
                side: BorderSide(color: theme.colorScheme.onPrimaryContainer),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              ),
              child: const Text('No'),
            ),
            const SizedBox(width: 16),
            FilledButton(
              onPressed: _onYes,
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              ),
              child: const Text('Yes  🎉'),
            ),
          ],
        ),
      ],
    );
  }
}
