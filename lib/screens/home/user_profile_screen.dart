import 'package:flutter/material.dart';
import '../../widgets/sketchy_button.dart';
import '../../widgets/sketchy_container.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PLAYER DETAILS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => Navigator.pushNamed(context, '/report_block'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 300,
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).primaryColor, width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(child: Text('[ User Photo Gallery ]')),
              ),
              const SizedBox(height: 24),
              Text('SAM, lv. 19', style: Theme.of(context).textTheme.displayMedium),
              Text('Art Major', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 24),
              const Divider(color: Colors.black, thickness: 2),
              const SizedBox(height: 24),
              Text('ABOUT ME', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Text('I love drawing and drinking too much coffee.', style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 24),
              Text('INTERESTS', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['Anime', 'Art', 'Coffee'].map((e) => SketchyContainer(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  borderRadius: 999,
                  child: Text(e, style: Theme.of(context).textTheme.labelSmall),
                )).toList(),
              ),
              const SizedBox(height: 48),
              SketchyButton(
                text: 'SEND MESSAGE',
                onPressed: () => Navigator.pushNamed(context, '/chats/individual'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
