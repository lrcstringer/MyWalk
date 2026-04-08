import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../domain/entities/memorization_item.dart';
import '../../../../presentation/providers/memorization_provider.dart';
import '../../../../presentation/theme/app_theme.dart';
import '../../../../presentation/views/shared/mywalk_paywall_view.dart';
import '../memorization_router.dart';
import '../widgets/memorization_list_tile.dart';
import 'memorization_circles_screen.dart';

class MemorizationHomeScreen extends StatefulWidget {
  const MemorizationHomeScreen({super.key});

  @override
  State<MemorizationHomeScreen> createState() => _MemorizationHomeScreenState();
}

class _MemorizationHomeScreenState extends State<MemorizationHomeScreen> {
  Timer? _dueTimer;

  @override
  void initState() {
    super.initState();
    // Re-evaluate isDueNow every minute so items move into "Today's reviews"
    // without requiring a Firestore snapshot.
    _dueTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _dueTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      appBar: AppBar(
        title: const Text('Meditating on His Word'),
        backgroundColor: MyWalkColor.charcoal,
        foregroundColor: MyWalkColor.warmWhite,
        actions: [
          IconButton(
            icon: const Icon(Icons.groups_2_outlined),
            tooltip: 'Circles',
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => const MemorizationCirclesScreen(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart_outlined),
            tooltip: 'My Progress',
            onPressed: () {
              if (context.read<MemorizationProvider>().showAnalyticsDashboard) {
                Navigator.of(context).pushNamed('/memorization/global-dashboard');
              } else {
                _showPremiumSheet(context);
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: MyWalkColor.golden,
        foregroundColor: MyWalkColor.charcoal,
        icon: const Icon(Icons.add),
        label: const Text('Add verse'),
        onPressed: () {
          final provider = context.read<MemorizationProvider>();
          if (!provider.canAddItem) {
            _showPremiumSheet(context);
          } else {
            MemorizationRouter.pushNewItem(context);
          }
        },
      ),
      body: Consumer<MemorizationProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: MyWalkColor.golden));
          }

          if (provider.items.isEmpty) {
            return _EmptyState(onAdd: () => MemorizationRouter.pushNewItem(context));
          }

          final dueItems = provider.dueItems;
          final otherItems = provider.activeItems
              .where((i) => !i.isDueNow)
              .toList();
          final mastered = provider.masteredItems;

          return CustomScrollView(
            slivers: [
              if (dueItems.isNotEmpty) ...[
                _SectionHeader(
                  label: "Today's reviews",
                  count: dueItems.length,
                  accent: true,
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _buildTile(context, provider, dueItems[i]),
                    childCount: dueItems.length,
                  ),
                ),
              ],
              if (otherItems.isNotEmpty) ...[
                _SectionHeader(label: 'Coming up', count: otherItems.length),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _buildTile(context, provider, otherItems[i]),
                    childCount: otherItems.length,
                  ),
                ),
              ],
              if (mastered.isNotEmpty) ...[
                _SectionHeader(label: 'Hidden in your heart', count: mastered.length),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _buildTile(context, provider, mastered[i]),
                    childCount: mastered.length,
                  ),
                ),
              ],
              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTile(
    BuildContext context,
    MemorizationProvider provider,
    MemorizationItem item,
  ) {
    return MemorizationListTile(
      item: item,
      onTap: () => MemorizationRouter.pushItemDashboard(context, item),
      onReview: () => MemorizationRouter.pushModeSelection(context, item),
      onArchive: () => provider.archiveItem(item),
    );
  }

  void _showPremiumSheet(BuildContext context) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => const MyWalkPaywallView(
          contextTitle: 'Unlock unlimited memorization',
          contextMessage:
              'Free tier: up to 3 items with Flip Card & Fill the Word. Premium: unlimited items, all 5 modes, and analytics.',
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final int count;
  final bool accent;

  const _SectionHeader({
    required this.label,
    required this.count,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      sliver: SliverToBoxAdapter(
        child: Row(
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: accent ? MyWalkColor.golden : MyWalkColor.warmWhite.withValues(alpha: 0.6),
                    letterSpacing: 0.5,
                  ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: (accent ? MyWalkColor.golden : MyWalkColor.warmWhite).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: accent ? MyWalkColor.golden : MyWalkColor.warmWhite.withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_stories_outlined, size: 72, color: MyWalkColor.golden.withValues(alpha: 0.5)),
            const SizedBox(height: 24),
            Text(
              'Thy word have I hid\nin mine heart',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: MyWalkColor.warmWhite,
                    height: 1.4,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '— Psalm 119:11',
              style: TextStyle(color: MyWalkColor.golden, fontSize: 13),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              style: MyWalkButtonStyle.primary(),
              icon: const Icon(Icons.add),
              label: const Text('Add your first verse'),
              onPressed: onAdd,
            ),
          ],
        ),
      ),
    );
  }
}
