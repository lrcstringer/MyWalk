import 'package:flutter/material.dart';

/// Defines the visual skin for all journalling screens.
///
/// Only the semantic color roles + a hero image are needed — everything
/// else (fruit chip colors, recording-ring red/amber, fullscreen viewer
/// black) is either domain data or a fixed functional color that must
/// not vary with the skin.
class JournalTheme {
  final String id;
  final String name;

  /// Main scaffold background.
  final Color bgPrimary;

  /// Card surfaces, inputs, dialogs, bottom sheets.
  final Color bgCard;

  /// Body text, headings, icon fills on light surfaces.
  final Color textPrimary;

  /// Hints, metadata, secondary labels, dividers, subtle borders.
  final Color textSecondary;

  /// Every interactive/tappable element: buttons, sliders, FAB accent,
  /// mic & playback controls.
  final Color accentAction;

  /// Subtle non-interactive container tints (upload banner, dividers).
  final Color accentMuted;

  /// Optional secondary accent for themes that use a contrasting pop color.
  final Color? accentPop;

  /// Optional tertiary accent for themes that use an additional volt/neon tone.
  final Color? accentVolt;

  /// Hero image shown at the top of the journal list.
  final String heroImageAsset;

  const JournalTheme({
    required this.id,
    required this.name,
    required this.bgPrimary,
    required this.bgCard,
    required this.textPrimary,
    required this.textSecondary,
    required this.accentAction,
    required this.accentMuted,
    required this.heroImageAsset,
    this.accentPop,
    this.accentVolt,
  });

  // ── Built-in themes ───────────────────────────────────────────────────────

  /// 01 — Warm cream/parchment — the default.
  static const parchment = JournalTheme(
    id: 'parchment',
    name: 'Parchment',
    bgPrimary:     Color(0xFFF3EDE2),
    bgCard:        Color(0xFFFBF7F0),
    textPrimary:   Color(0xFF5B4B3E),
    textSecondary: Color(0xFF7A6B5D),
    accentAction:  Color(0xFFD4A843),
    accentMuted:   Color(0xFFDCE3D6),
    heroImageAsset: 'assets/Journalling.png',
  );

  /// 02 — Deep navy with sage-green accents — quiet evening reflection.
  static const nightGarden = JournalTheme(
    id: 'night_garden',
    name: 'Night Garden',
    bgPrimary:     Color(0xFF1A1F2E),
    bgCard:        Color(0xFF232A3B),
    textPrimary:   Color(0xFFE8E4DC),
    textSecondary: Color(0xFF8A96A8),
    accentAction:  Color(0xFF7A9E7E),
    accentMuted:   Color(0xFF2A3828),
    heroImageAsset: 'assets/Journalling.png',
  );

  /// 03 — Clean bright linen — minimal, distraction-free writing.
  static const linen = JournalTheme(
    id: 'linen',
    name: 'Linen',
    bgPrimary:     Color(0xFFFAFAF8),
    bgCard:        Color(0xFFFFFFFF),
    textPrimary:   Color(0xFF2C2826),
    textSecondary: Color(0xFF6E6560),
    accentAction:  Color(0xFFD4A843),
    accentMuted:   Color(0xFFEDF2ED),
    heroImageAsset: 'assets/Journalling.png',
  );

  /// 04 — Iron & Ember — charcoal and warm rust tones.
  static const ironAndEmber = JournalTheme(
    id: 'iron_and_ember',
    name: 'Iron & Ember',
    bgPrimary:     Color(0xFF1C1A18),
    bgCard:        Color(0xFF2C2925),
    textPrimary:   Color(0xFFE8DDD0),
    textSecondary: Color(0xFFB5A898),
    accentAction:  Color(0xFFC46A2B),
    accentMuted:   Color(0xFF6B3D1A),
    heroImageAsset: 'assets/Journalling.png',
  );

  /// 05 — Deep Current — dark ocean with cyan and amber pop.
  static const deepCurrent = JournalTheme(
    id: 'deep_current',
    name: 'Deep Current',
    bgPrimary:     Color(0xFF0D1B2A),
    bgCard:        Color(0xFF162638),
    textPrimary:   Color(0xFFD6E8F5),
    textSecondary: Color(0xFF8AAFC4),
    accentAction:  Color(0xFF3AB8C8),
    accentMuted:   Color(0xFF1A4A52),
    accentPop:     Color(0xFFF5A623),
    heroImageAsset: 'assets/Journalling.png',
  );

  /// 06 — Flint & Field — forest green-grey with steel blue accent.
  static const flintAndField = JournalTheme(
    id: 'flint_and_field',
    name: 'Flint & Field',
    bgPrimary:     Color(0xFF1E2118),
    bgCard:        Color(0xFF2C3024),
    textPrimary:   Color(0xFFD8D4C0),
    textSecondary: Color(0xFF9A9C80),
    accentAction:  Color(0xFF7A9BB5),
    accentMuted:   Color(0xFF2E4858),
    heroImageAsset: 'assets/Journalling.png',
  );

  /// 07 — Solar Edge — bright white with bold orange-red accent.
  static const solarEdge = JournalTheme(
    id: 'solar_edge',
    name: 'Solar Edge',
    bgPrimary:     Color(0xFFF5F5F0),
    bgCard:        Color(0xFFFFFFFF),
    textPrimary:   Color(0xFF111111),
    textSecondary: Color(0xFF555555),
    accentAction:  Color(0xFFD4541A),
    accentMuted:   Color(0xFFF0E0D6),
    heroImageAsset: 'assets/Journalling.png',
  );

  /// 08 — Wipeout — deep ocean with electric blue and amber pop.
  static const wipeout = JournalTheme(
    id: 'wipeout',
    name: 'Wipeout',
    bgPrimary:     Color(0xFF0B1F2E),
    bgCard:        Color(0xFF112B3E),
    textPrimary:   Color(0xFFE8F4FF),
    textSecondary: Color(0xFF7DB8D4),
    accentAction:  Color(0xFF00C2FF),
    accentMuted:   Color(0xFF0D3A50),
    accentPop:     Color(0xFFF5A623),
    heroImageAsset: 'assets/Journalling.png',
  );

  /// 09 — Concrete Gospel — near-black with acid yellow-green and red pop.
  static const concreteGospel = JournalTheme(
    id: 'concrete_gospel',
    name: 'Concrete Gospel',
    bgPrimary:     Color(0xFF161616),
    bgCard:        Color(0xFF222222),
    textPrimary:   Color(0xFFEFEFEF),
    textSecondary: Color(0xFF888888),
    accentAction:  Color(0xFFC8E600),
    accentMuted:   Color(0xFF2A2A2A),
    accentPop:     Color(0xFFFF3C3C),
    heroImageAsset: 'assets/Journalling.png',
  );

  /// 10 — Signal Void — near-black with magenta, cyan, and violet.
  static const signalVoid = JournalTheme(
    id: 'signal_void',
    name: 'Signal Void',
    bgPrimary:     Color(0xFF0A0A0F),
    bgCard:        Color(0xFF12121E),
    textPrimary:   Color(0xFFF0EEFF),
    textSecondary: Color(0xFF8A80CC),
    accentAction:  Color(0xFFFF2D9B),
    accentMuted:   Color(0xFF1E1A3A),
    accentPop:     Color(0xFF00F5FF),
    accentVolt:    Color(0xFFB44FFF),
    heroImageAsset: 'assets/Journalling.png',
  );

  /// 11 — Static Bloom — near-white with deep violet, hot pink, and cyan.
  static const staticBloom = JournalTheme(
    id: 'static_bloom',
    name: 'Static Bloom',
    bgPrimary:     Color(0xFFF7F5FF),
    bgCard:        Color(0xFFFFFFFF),
    textPrimary:   Color(0xFF0D0A1E),
    textSecondary: Color(0xFF5544AA),
    accentAction:  Color(0xFFCC006E),
    accentMuted:   Color(0xFFEAE6FF),
    accentPop:     Color(0xFF0099CC),
    accentVolt:    Color(0xFF7700CC),
    heroImageAsset: 'assets/Journalling.png',
  );

  static const all = [
    parchment,
    nightGarden,
    linen,
    ironAndEmber,
    deepCurrent,
    flintAndField,
    solarEdge,
    wipeout,
    concreteGospel,
    signalVoid,
    staticBloom,
  ];
}
