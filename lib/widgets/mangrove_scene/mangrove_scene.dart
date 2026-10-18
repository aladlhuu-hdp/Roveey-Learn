import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/explorer_topic.dart';
import 'mangrove_scene_painter.dart';

class MangroveScene extends StatefulWidget {
  const MangroveScene({
    super.key,
    required this.height,
    required this.showHotspots,
    required this.compact,
    this.onTopicTap,
  });

  final double height;
  final bool showHotspots;
  final bool compact;
  final ValueChanged<ExplorerTopic>? onTopicTap;

  @override
  State<MangroveScene> createState() => _MangroveSceneState();
}

class _MangroveSceneState extends State<MangroveScene> with SingleTickerProviderStateMixin {
  late final AnimationController _animation;

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  void _openTopic(ExplorerTopic topic) {
    widget.onTopicTap?.call(topic);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.compact ? 0 : 21),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;
            return Stack(
              fit: StackFit.expand,
              children: <Widget>[
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, _) => CustomPaint(
                    painter: MangroveScenePainter(
                      phase: _animation.value,
                      compact: widget.compact,
                    ),
                  ),
                ),
                if (widget.showHotspots)
                  ...explorerTopics.map((topic) => Positioned(
                        left: w * topic.x - 24,
                        top: h * topic.y - 24,
                        child: HotspotButton(icon: topic.icon, onTap: () => _openTopic(topic)),
                      )),
                if (widget.showHotspots)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Row(
                        children: <Widget>[
                          Icon(Icons.explore_rounded, color: AppColors.forest, size: 14),
                          SizedBox(width: 5),
                          Text(
                            'TELUK MANGROVE · 01',
                            style: TextStyle(
                              color: AppColors.forest,
                              fontWeight: FontWeight.w600,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (!widget.showHotspots && !widget.compact)
                  const Positioned(left: 15, bottom: 13, child: SceneLabel()),
              ],
            );
          },
        ),
      ),
    );
  }
}

class HotspotButton extends StatefulWidget {
  const HotspotButton({super.key, required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  State<HotspotButton> createState() => _HotspotButtonState();
}

class _HotspotButtonState extends State<HotspotButton> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1650))..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, _) {
          final value = _pulse.value;
          final scale = 0.78 + value * 0.48;
          return Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Container(
                width: 42.0 * scale,
                height: 42.0 * scale,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accentMint.withValues(alpha: (1.0 - value) * 0.23),
                  border: Border.all(
                    color: AppColors.forest.withValues(alpha: (1.0 - value) * 0.38),
                    width: 1.2,
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onTap,
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 39,
                    height: 39,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.paper.withValues(alpha: 0.97),
                      border: Border.all(color: AppColors.accentMint, width: 3),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: AppColors.forestDeep.withValues(alpha: 0.2),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Icon(widget.icon, color: AppColors.forest, size: 19),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class SceneLabel extends StatelessWidget {
  const SceneLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.forestDeep.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.waves_rounded, size: 15, color: AppColors.accentMint),
          SizedBox(width: 6),
          Text(
            'Ekosistem pesisir',
            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
