import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fairelescourses/l10n/app_localizations.dart';
import 'package:fairelescourses/l10n/easter_messages.dart';

class EasterEggScreen extends StatefulWidget {
  const EasterEggScreen({super.key});

  @override
  State<EasterEggScreen> createState() => _EasterEggScreenState();
}

class _EasterEggScreenState extends State<EasterEggScreen> {
  bool _started = false;
  late List<String> _shuffled;
  int _index = 0;

  void _initMessages() {
    final msgs = easterMessages(context);
    _shuffled = List.of(msgs)..shuffle(Random());
  }

  String get _currentMessage => _shuffled[_index];

  void _onButtonPressed() => setState(() {
        _initMessages();
        _started = true;
      });

  void _onYes() => Navigator.of(context).pop();

  void _onNo() {
    setState(() {
      _index++;
      if (_index >= _shuffled.length) {
        // Reshuffle for the next round, avoiding the same message twice in a row
        final last = _shuffled.last;
        final msgs = easterMessages(context);
        _shuffled = List.of(msgs)..shuffle(Random());
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
    final l = AppLocalizations.of(context)!;
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
          child: Text(l.easterButton),
        ),
      ],
    );
  }

  Widget _buildQuestion(ThemeData theme) {
    final l = AppLocalizations.of(context)!;
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
          l.easterQuestion,
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
              child: Text(l.no),
            ),
            const SizedBox(width: 16),
            FilledButton(
              onPressed: _onYes,
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              ),
              child: Text(l.easterYes),
            ),
          ],
        ),
      ],
    );
  }
}
