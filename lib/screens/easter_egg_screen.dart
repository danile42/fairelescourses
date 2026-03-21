import 'package:flutter/material.dart';

const _positiveMessages = [
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
];

class EasterEggScreen extends StatefulWidget {
  const EasterEggScreen({super.key});

  @override
  State<EasterEggScreen> createState() => _EasterEggScreenState();
}

class _EasterEggScreenState extends State<EasterEggScreen> {
  // null  → show the initial button
  // false → show message + question
  // true  → answered yes, closing
  bool? _answeredYes;
  int _messageIndex = 0;

  void _onButtonPressed() {
    setState(() => _answeredYes = false);
  }

  void _onYes() {
    Navigator.of(context).pop();
  }

  void _onNo() {
    setState(() {
      _messageIndex = (_messageIndex + 1) % _positiveMessages.length;
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
              child: _answeredYes == null
                  ? _buildEntry(theme)
                  : _buildQuestion(theme),
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
        Text('✨', style: const TextStyle(fontSize: 64)),
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
      key: ValueKey('question-$_messageIndex'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('💛', style: const TextStyle(fontSize: 48)),
        const SizedBox(height: 24),
        Text(
          _positiveMessages[_messageIndex],
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
