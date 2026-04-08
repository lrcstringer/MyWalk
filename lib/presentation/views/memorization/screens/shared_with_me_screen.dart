import 'package:flutter/material.dart';
import '../../../../domain/entities/memorization_item.dart';
import '../../../../presentation/theme/app_theme.dart';
import '../widgets/chunk_heat_map.dart';

// Read-only view of a memorization item shared by a circle friend.
// Allows viewing the item content and chunks but not modifying SM2 state.

class SharedWithMeScreen extends StatelessWidget {
  final MemorizationItem item;
  final String sharedByName;

  const SharedWithMeScreen({
    super.key,
    required this.item,
    required this.sharedByName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      appBar: AppBar(
        title: const Text('Shared with me'),
        backgroundColor: MyWalkColor.charcoal,
        foregroundColor: MyWalkColor.warmWhite,
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Shared-by banner
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: MyWalkColor.golden.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: MyWalkColor.golden.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person_outline,
                          size: 16, color: MyWalkColor.golden),
                      const SizedBox(width: 8),
                      Text(
                        'Shared by $sharedByName',
                        style: const TextStyle(
                          color: MyWalkColor.golden,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Title
                Text(
                  item.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: MyWalkColor.warmWhite,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 16),
                // Full text
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: MyWalkColor.cardBackground,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    item.fullText,
                    style: const TextStyle(
                      color: MyWalkColor.warmWhite,
                      fontSize: 16,
                      height: 1.8,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Chunks list
                Text(
                  'Phrases (${item.chunks.length})',
                  style: TextStyle(
                    color: MyWalkColor.warmWhite.withValues(alpha: 0.5),
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 10),
                ...item.chunks.asMap().entries.map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: MyWalkColor.cardBackground,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                margin:
                                    const EdgeInsets.only(top: 1, right: 10),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: MyWalkColor.golden
                                      .withValues(alpha: 0.15),
                                ),
                                child: Center(
                                  child: Text(
                                    '${e.key + 1}',
                                    style: const TextStyle(
                                      color: MyWalkColor.golden,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  e.value.text,
                                  style: const TextStyle(
                                    color: MyWalkColor.warmWhite,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                const SizedBox(height: 20),
                if (item.chunks.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: MyWalkColor.cardBackground,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ChunkHeatMap(chunks: item.chunks),
                  ),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
