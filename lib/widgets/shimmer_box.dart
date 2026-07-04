import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../core/constants/app_colors.dart';

/// A single shimmering placeholder block, used to build skeleton layouts.
class ShimmerBox extends StatelessWidget {
  final double? width;
  final double height;
  final BorderRadius borderRadius;

  const ShimmerBox({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: AppColors.divider, borderRadius: borderRadius),
    );
  }
}

/// A shimmering list of card-shaped skeletons, matching the padding/spacing
/// used by the job/application list screens so the loading state doesn't
/// jump when real content arrives.
class ShimmerCardList extends StatelessWidget {
  final int itemCount;
  final double itemHeight;

  const ShimmerCardList({super.key, this.itemCount = 6, this.itemHeight = 96});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.divider,
      highlightColor: AppColors.surface,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, _) => ShimmerBox(
          height: itemHeight,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
