import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../domain/entities/memorization_item.dart';
import '../../../../presentation/providers/memorization_provider.dart';
import '../../../../presentation/theme/app_theme.dart';
import '../../../../presentation/views/shared/mywalk_paywall_view.dart';
import '../memorization_router.dart';
import '../widgets/memorization_list_tile.dart';

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
    final imageHeight = MediaQuery.of(context).size.width * 0.65;
    final provider = context.watch<MemorizationProvider>();
    final dueItems = provider.dueItems;
    final otherItems = provider.activeItems.where((i) => !i.isDueNow).toList();
    final mastered = provider.masteredItems;

    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: MyWalkColor.golden,
        foregroundColor: MyWalkColor.charcoal,
        icon: const Icon(Icons.add),
        label: const Text('Add verse'),
        onPressed: () {
          if (!provider.canAddItem) {
            _showPremiumSheet(context);
          } else {
            MemorizationRouter.pushNewItem(context);
          }
        },
      ),
      body: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(child: DeepSpaceBackground()),
          ),
          CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: MyWalkColor.charcoal,
                foregroundColor: MyWalkColor.warmWhite,
                expandedHeight: imageHeight,
                pinned: true,
                title: Text(
                  'Meditating on His Word',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: MyWalkColor.warmWhite,
                  ),
                ),
                actions: [
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
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.parallax,
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        'assets/memorization pic.png',
                        fit: BoxFit.fitWidth,
                        alignment: Alignment.topCenter,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              MyWalkColor.charcoal.withValues(alpha: 0.5),
                              MyWalkColor.charcoal,
                            ],
                            stops: const [0.0, 0.55, 1.0],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: 14,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Scripture Memorization',
                              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                color: MyWalkColor.warmWhite,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              '"I have stored up your word in my heart,\nthat I might not sin against you."',
                              style: TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: MyWalkColor.softGold,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 3),
                            const Text(
                              'Psalm 119:11',
                              style: TextStyle(
                                fontSize: 11,
                                color: MyWalkColor.golden,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (provider.isLoading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: CircularProgressIndicator(color: MyWalkColor.golden),
                  ),
                )
              else if (provider.items.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(onAdd: () => MemorizationRouter.pushNewItem(context)),
                )
              else ...[
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
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTile(
    BuildContext context,
    MemorizationProvider provider,
    MemorizationItem item,
  ) {
    if (!item.initialEncounterComplete) {
      return MemorizationListTile(
        item: item,
        onTap: () => MemorizationRouter.pushInitialMemorization(
          context,
          item,
          startStep: item.currentInitialStep,
        ),
        onReview: () => MemorizationRouter.pushInitialMemorization(
          context,
          item,
          startStep: item.currentInitialStep,
        ),
        onArchive: () => provider.archiveItem(item),
        onDelete: () => provider.deleteItem(item),
      );
    }
    return MemorizationListTile(
      item: item,
      onTap: () => MemorizationRouter.pushItemDashboard(context, item),
      onReview: () => MemorizationRouter.pushReviewSession(context, item),
      onArchive: () => provider.archiveItem(item),
      onDelete: () => provider.deleteItem(item),
    );
  }

  void _showPremiumSheet(BuildContext context) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => const MyWalkPaywallView(
          contextTitle: 'Unlock scripture memorization',
          contextMessage:
              'Premium: unlimited verses, all 6 review modes, and full analytics dashboard.',
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
            const Text(
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
