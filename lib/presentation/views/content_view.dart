import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/datasources/remote/auth_service.dart';
import '../../data/services/pending_invite_service.dart';
import '../../data/services/pending_partner_token_service.dart';
import '../../domain/repositories/circle_repository.dart';
import '../providers/navigation_provider.dart';
import 'habits/partner_acceptance_screen.dart';
import 'circles/circle_invitation_dialog.dart';
import 'today/today_view.dart';
import 'practices/practices_view.dart';
import 'kingdom_life/kingdom_life_view.dart';
import 'circles/circles_tab.dart';
import 'journal/journal_tab.dart';

class ContentView extends StatefulWidget {
  const ContentView({super.key});

  @override
  State<ContentView> createState() => _ContentViewState();
}

class _ContentViewState extends State<ContentView> with WidgetsBindingObserver {
  int _selectedTab = 0;
  late final PageController _pageController;
  bool _hasNewGratitudes = false;
  int _circlesRefreshTrigger = 0;
  bool _checkingGratitudes = false;
  bool _prevAuthenticated = false;
  StreamSubscription<String>? _inviteSub;
  StreamSubscription<String>? _partnerTokenSub;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedTab);
    _prevAuthenticated = AuthService.shared.isAuthenticated;
    AuthService.shared.addListener(_onAuthChanged);
    WidgetsBinding.instance.addObserver(this);
    context.read<NavigationProvider>().addListener(_onNavigationRequest);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkNewGratitudes();
      _consumePendingInvite();
      _consumePendingPartnerToken();
    });
    _inviteSub = context
        .read<PendingInviteService>()
        .stream
        .listen((code) => _showInviteDialog(code));
    _partnerTokenSub = context
        .read<PendingPartnerTokenService>()
        .stream
        .listen((token) => _showPartnerAcceptance(token));
  }

  @override
  void dispose() {
    _pageController.dispose();
    AuthService.shared.removeListener(_onAuthChanged);
    context.read<NavigationProvider>().removeListener(_onNavigationRequest);
    _inviteSub?.cancel();
    _partnerTokenSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onNavigationRequest() {
    final navProvider = context.read<NavigationProvider>();
    final tab = navProvider.pendingTab;
    if (tab < 0 || !mounted) return;
    navProvider.clearPending();
    setState(() {
      _selectedTab = tab;
      if (tab == 4) _hasNewGratitudes = false;
    });
    _pageController.animateToPage(
      tab,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onAuthChanged() {
    final isNowAuthenticated = AuthService.shared.isAuthenticated;
    if (_prevAuthenticated && !isNowAuthenticated && mounted) {
      setState(() => _selectedTab = 0);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You have been signed out.')),
      );
    }
    _prevAuthenticated = isNowAuthenticated;
  }

  void _consumePendingInvite() {
    final code = context.read<PendingInviteService>().consume();
    if (code != null) _showInviteDialog(code);
  }

  void _consumePendingPartnerToken() {
    final token = context.read<PendingPartnerTokenService>().consume();
    if (token != null) _showPartnerAcceptance(token);
  }

  void _showPartnerAcceptance(String token) {
    if (!mounted) return;
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => PartnerAcceptanceScreen(token: token),
    ));
  }

  Future<void> _showInviteDialog(String code) async {
    if (!mounted) return;
    final joined = await CircleInvitationDialog.show(context, code);
    if (!mounted) return;
    if (joined == true) {
      setState(() {
        _circlesRefreshTrigger++;
        _selectedTab = 4;
      });
      _pageController.jumpToPage(4);
    }
    _checkNewGratitudes();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkNewGratitudes();
    }
  }

  Future<void> _checkNewGratitudes() async {
    final isAuthenticated = context.read<AuthService>().isAuthenticated;
    if (!isAuthenticated) return;
    if (_checkingGratitudes) return;
    _checkingGratitudes = true;
    try {
      final circleRepo = context.read<CircleRepository>();
      final circles = await circleRepo.listCircles();
      final counts = await Future.wait(
        circles.map((c) => circleRepo.getGratitudeNewCount(c.id)),
      );
      final hasNew = counts.any((n) => n > 0);
      if (mounted) setState(() => _hasNewGratitudes = hasNew);
    } catch (_) {
      // Network failure — leave badge state unchanged.
    } finally {
      _checkingGratitudes = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (i) => setState(() {
          _selectedTab = i;
          if (i == 4) _hasNewGratitudes = false;
        }),
        children: [
          const _KeepAlivePage(child: TodayView()),
          const _KeepAlivePage(child: PracticesView()),
          const _KeepAlivePage(child: JournalTab()),
          const _KeepAlivePage(child: KingdomLifeView()),
          _KeepAlivePage(child: CirclesTab(refreshTrigger: _circlesRefreshTrigger)),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTab,
        onTap: (i) {
          setState(() {
            _selectedTab = i;
            if (i == 4) _hasNewGratitudes = false;
          });
          _pageController.animateToPage(
            i,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.card_giftcard),
            label: 'Today',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.checklist_rounded),
            label: 'Practices',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.book_outlined),
            activeIcon: Icon(Icons.book),
            label: 'Journal',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome_outlined),
            activeIcon: Icon(Icons.auto_awesome),
            label: 'Kingdom Life',
          ),
          BottomNavigationBarItem(
            icon: _hasNewGratitudes
                ? Badge(child: const Icon(Icons.groups))
                : const Icon(Icons.groups),
            label: 'Groups',
          ),
        ],
      ),
    );
  }
}

class _KeepAlivePage extends StatefulWidget {
  final Widget child;
  const _KeepAlivePage({required this.child});

  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<_KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
