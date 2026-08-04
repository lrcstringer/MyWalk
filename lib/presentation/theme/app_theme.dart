import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class JournalColor {
  static const bgPrimary    = Color(0xFFF3EDE2);
  static const bgCard       = Color(0xFFFBF7F0);
  static const accentMuted  = Color(0xFFDCE3D6);
  static const accentBlue   = Color(0xFFC9D3D6);
  static const textPrimary  = Color(0xFF5B4B3E);
  static const textSecondary = Color(0xFF7A6B5D);
}

class MyWalkColor {
  static const charcoal = Color(0xFF1E1B1A);
  static const warmWhite = Color(0xFFFAF7F2);
  static const golden = Color(0xFFD4A843);
  static const sage = Color(0xFF7A9E7E);
  static const warmCoral = Color(0xFFD4836B);
  static const softGold = Color(0xFFE8D5A3);
  static const mutedSage = Color(0xFFC5D8C7);
  static const eventPurple = Color(0xFF7B8EC8);

  static const cardBackground = Color(0xFF272320);
  static const cardBorder = Color(0x0FFFFFFF); // white 6% opacity

  static const surfaceOverlay = Color(0x0AFFFFFF); // white 4%
  static const inputBackground = Color(0x1AFFFFFF); // white 10%

  static const LinearGradient goldenGradient = LinearGradient(
    colors: [Color(0xFFD4A843), Color(0xFFE8D5A3)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const RadialGradient warmGlow = RadialGradient(
    colors: [Color(0x1FD4A843), Color(0x0AD4A843), Colors.transparent],
    center: Alignment.topCenter,
    radius: 1.0,
  );
}

class _DeepSpacePainter extends CustomPainter {
  const _DeepSpacePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    // Vignette: edges recede toward near-black, centre stays warm
    canvas.drawRect(rect, Paint()
      ..shader = const RadialGradient(
        center: Alignment(0.0, 0.1),
        radius: 1.35,
        colors: [Colors.transparent, Color(0x40000000)],
        stops: [0.3, 1.0],
      ).createShader(rect));
    // Warm ambient: faint amber sphere high on screen, like a candle far away
    canvas.drawRect(rect, Paint()
      ..shader = const RadialGradient(
        center: Alignment(0.0, -0.8),
        radius: 0.8,
        colors: [Color(0x18D4A843), Color(0x00D4A843)],
      ).createShader(rect));
  }

  @override
  bool shouldRepaint(covariant _DeepSpacePainter oldDelegate) => false;
}

/// Full-screen depth background. Paints a vignette (edges recede to near-black)
/// plus a subtle warm amber glow at the top-centre, creating a sense of depth.
class DeepSpaceBackground extends StatelessWidget {
  const DeepSpaceBackground({super.key});

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(
      painter: const _DeepSpacePainter(),
      child: const SizedBox.expand(),
    ),
  );
}

class AppTheme {
  static TextTheme _buildTextTheme(Color baseColor) {
    final inter = GoogleFonts.interTextTheme().apply(bodyColor: baseColor, displayColor: baseColor);
    return inter.copyWith(
      displayLarge: GoogleFonts.dmSerifDisplay(color: baseColor),
      displayMedium: GoogleFonts.dmSerifDisplay(color: baseColor),
      headlineLarge: GoogleFonts.dmSerifDisplay(color: baseColor, fontWeight: FontWeight.w700),
      headlineMedium: GoogleFonts.dmSerifDisplay(color: baseColor, fontWeight: FontWeight.w600),
      titleLarge: GoogleFonts.dmSerifDisplay(color: baseColor, fontWeight: FontWeight.w600),
    );
  }

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: MyWalkColor.charcoal,
      colorScheme: const ColorScheme.dark(
        primary: MyWalkColor.golden,
        secondary: MyWalkColor.sage,
        surface: MyWalkColor.cardBackground,
        onPrimary: MyWalkColor.charcoal,
        onSurface: MyWalkColor.warmWhite,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: MyWalkColor.charcoal,
        selectedItemColor: MyWalkColor.golden,
        unselectedItemColor: Colors.white38,
        type: BottomNavigationBarType.fixed,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: MyWalkColor.charcoal,
        foregroundColor: MyWalkColor.warmWhite,
        elevation: 0,
      ),
      textTheme: _buildTextTheme(MyWalkColor.warmWhite),
    );
  }

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: MyWalkColor.warmWhite,
      colorScheme: ColorScheme.light(
        primary: MyWalkColor.golden,
        secondary: MyWalkColor.sage,
        surface: const Color(0xFFF0EDE8),
        onPrimary: MyWalkColor.charcoal,
        onSurface: MyWalkColor.charcoal,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: MyWalkColor.warmWhite,
        selectedItemColor: MyWalkColor.golden,
        unselectedItemColor: MyWalkColor.charcoal.withValues(alpha: 0.4),
        type: BottomNavigationBarType.fixed,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: MyWalkColor.warmWhite,
        foregroundColor: MyWalkColor.charcoal,
        elevation: 0,
      ),
      textTheme: _buildTextTheme(MyWalkColor.charcoal),
    );
  }
}

// Reusable decoration helpers
class MyWalkDecorations {
  static BoxDecoration get card => BoxDecoration(
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF2C2823), Color(0xFF221F1B)],
    ),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: const Color(0x1FFFFFFF), width: 1.0),
  );

  static BoxDecoration get inputField => BoxDecoration(
    color: MyWalkColor.inputBackground,
    borderRadius: BorderRadius.circular(12),
  );
}

// Reusable button style
class MyWalkButtonStyle {
  static ButtonStyle primary({Color color = MyWalkColor.golden}) =>
      ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: MyWalkColor.charcoal,
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      );
}

class MyWalkAvatar extends StatelessWidget {
  final String? name;
  final double size;

  const MyWalkAvatar({super.key, this.name, this.size = 26});

  @override
  Widget build(BuildContext context) {
    if (name == null || name!.trim().isEmpty) {
      return Container(
        width: size, height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.08),
        ),
        child: Icon(Icons.person_outline_rounded,
            size: size * 0.5, color: Colors.white.withValues(alpha: 0.3)),
      );
    }
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: _colorFor(name!)),
      child: Center(
        child: Text(_initials(name!),
          style: TextStyle(
            fontSize: size * 0.35,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  static Color _colorFor(String name) {
    const palette = [
      Color(0xFF4A6FA5),
      Color(0xFF6A5AAA),
      Color(0xFF5A8A6A),
      Color(0xFFA05A5A),
      Color(0xFF7A6A50),
      Color(0xFF556B8A),
    ];
    final hash = name.codeUnits.fold(0, (acc, c) => acc + c);
    return palette[hash % palette.length];
  }
}
