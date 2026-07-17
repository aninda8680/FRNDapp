import 'package:flutter/material.dart';
import '../../widgets/sketchy_button.dart';
import '../../widgets/sketchy_container.dart';

class ReportBlockScreen extends StatelessWidget {
  const ReportBlockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('REPORT PLAYER')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('REASON', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              SketchyContainer(
                child: TextField(
                  maxLines: 4,
                  decoration: const InputDecoration(border: InputBorder.none, hintText: 'Please describe...'),
                ),
              ),
              const Spacer(),
              SketchyButton(
                text: 'SUBMIT REPORT',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
