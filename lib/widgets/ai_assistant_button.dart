import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/app_colors.dart';
import '../screens/ai_assistant_screen.dart';

class AIAssistantButton extends ConsumerStatefulWidget {
  const AIAssistantButton({super.key});

  @override
  ConsumerState<AIAssistantButton> createState() => _AIAssistantButtonState();
}

class _AIAssistantButtonState extends ConsumerState<AIAssistantButton> {
  void _openChat(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AIAssistantScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.auto_awesome, color: AppColors.accentPurple).animate(onPlay: (controller) => controller.repeat(reverse: true)).shimmer(duration: 2.seconds),
      onPressed: () => _openChat(context),
    );
  }
}

