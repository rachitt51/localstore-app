import 'package:flutter/material.dart';

/// A pulsing grey block. Compose into list/grid loaders.
class Skeleton extends StatefulWidget {
  const Skeleton({super.key, this.width, this.height = 16, this.radius = 6});

  final double? width;
  final double height;
  final double radius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FadeTransition(
      opacity: Tween(begin: 0.4, end: 0.9).animate(_controller),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

/// A list of card-shaped skeleton rows.
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.rows = 6, this.rowHeight = 72});

  final int rows;
  final double rowHeight;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: rows,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, _) => Skeleton(height: rowHeight, radius: 12),
    );
  }
}

/// Two-column grid of product-card-shaped skeletons.
class SkeletonGrid extends StatelessWidget {
  const SkeletonGrid({super.key, this.count = 6});

  final int count;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: count,
      itemBuilder: (_, _) => const Skeleton(height: 200, radius: 12),
    );
  }
}
