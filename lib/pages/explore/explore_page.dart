import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/explorer_topic.dart';
import '../../widgets/common/eyebrow.dart';
import '../../widgets/common/note_card.dart';
import '../../widgets/common/section_heading.dart';
import '../../widgets/mangrove_scene/mangrove_scene.dart';

class ExplorePage extends StatelessWidget {
  const ExplorePage({
    super.key,
    required this.exploredTopics,
    required this.onTopicExplored,
  });

  final Set<String> exploredTopics;
  final ValueChanged<String> onTopicExplored;

  void _showTopic(BuildContext context, ExplorerTopic topic) {
    onTopicExplored(topic.id);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: <Widget>[
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceGreenTint,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(topic.icon, size: 28, color: AppColors.forest),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          topic.title,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 22),
                        ),
                        const SizedBox(height: 3),
                        Text(topic.tagline,
                            style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                      ],
                    ),
                  ),
                  const Icon(Icons.check_circle_rounded, color: AppColors.leaf),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                topic.description,
                style: const TextStyle(fontSize: 14, height: 1.55, color: AppColors.ink),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCardGreen,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Icon(Icons.lightbulb_outline_rounded,
                        color: AppColors.forest, size: 21),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        topic.fact,
                        style: const TextStyle(
                          color: AppColors.forestDeep,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Lanjut menjelajah'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final count = exploredTopics.length;
    return CustomScrollView(
      slivers: <Widget>[
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 26),
          sliver: SliverList.list(
            children: <Widget>[
              const Eyebrow(label: 'JELAJAH EKOSISTEM'),
              const SizedBox(height: 9),
              Text('Dengar alam\nbercerita.', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 9),
              const Text(
                'Pilih bagian lanskap untuk mengenali fungsi mangrove dan kehidupan yang bergantung padanya.',
                style: TextStyle(color: AppColors.muted, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppColors.paper,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.line),
                ),
                child: Column(
                  children: <Widget>[
                    MangroveScene(
                      height: 315,
                      showHotspots: true,
                      compact: false,
                      onTopicTap: (topic) => _showTopic(context, topic),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(9, 0, 9, 8),
                      child: Row(
                        children: <Widget>[
                          const Icon(Icons.touch_app_rounded, size: 19, color: AppColors.forest),
                          const SizedBox(width: 7),
                          const Expanded(
                            child: Text(
                              'Ketuk titik yang berdenyut',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                          Text(
                            '$count/${explorerTopics.length} ditemukan',
                            style: const TextStyle(
                              color: AppColors.forest,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const SectionHeading(
                title: 'Temukan di ekosistem',
                subtitle: 'Objek yang pernah dibuka tetap bisa dipelajari.',
              ),
              const SizedBox(height: 12),
              ...explorerTopics.map((topic) {
                final found = exploredTopics.contains(topic.id);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TopicTile(
                    topic: topic,
                    explored: found,
                    onTap: () => _showTopic(context, topic),
                  ),
                );
              }),
              const SizedBox(height: 8),
              const NoteCard(
                text:
                    'Setelah menjelajah, lanjutkan dengan simulasi agar kamu dapat mencoba mengambil keputusan untuk rehabilitasi mangrove.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class TopicTile extends StatelessWidget {
  const TopicTile({
    super.key,
    required this.topic,
    required this.explored,
    required this.onTap,
  });

  final ExplorerTopic topic;
  final bool explored;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.paper,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.surfaceCardAlt,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(topic.icon, color: AppColors.forest, size: 23),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(topic.title,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 3),
                    Text(topic.tagline,
                        style: const TextStyle(color: AppColors.muted, fontSize: 11)),
                  ],
                ),
              ),
              Icon(
                explored ? Icons.check_circle_rounded : Icons.arrow_forward_ios_rounded,
                size: explored ? 20 : 15,
                color: explored ? AppColors.leaf : AppColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
