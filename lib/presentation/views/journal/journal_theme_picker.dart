import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/journal_theme.dart';
import '../../providers/journal_theme_provider.dart';

/// Modal bottom sheet that lets the user pick a journal skin.
/// Call via [showJournalThemePicker].
void showJournalThemePicker(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => ChangeNotifierProvider.value(
      value: context.read<JournalThemeProvider>(),
      child: const _JournalThemePickerSheet(),
    ),
  );
}

class _JournalThemePickerSheet extends StatelessWidget {
  const _JournalThemePickerSheet();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<JournalThemeProvider>();
    final current = provider.theme;

    // Sheet itself adopts the *current* theme so it looks coherent.
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      decoration: BoxDecoration(
        color: current.bgCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fixed header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: current.textSecondary.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Journal Theme',
                    style: TextStyle(
                      color: current.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Choose a look for your journal',
                    style: TextStyle(
                      color: current.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            // Scrollable grid
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: GridView.count(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.82,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: JournalTheme.all.map((theme) {
                    final isSelected = theme.id == current.id;
                    return _ThemeCard(
                      theme: theme,
                      isSelected: isSelected,
                      onTap: () {
                        provider.setTheme(theme);
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final JournalTheme theme;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.theme,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: theme.bgPrimary,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? theme.accentAction
                : theme.textSecondary.withValues(alpha: 0.2),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.accentAction.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero image across the top
            SizedBox(
              height: 62,
              width: double.infinity,
              child: Image.asset(
                theme.heroImageAsset,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    Container(color: theme.bgCard),
              ),
            ),

            // Swatches + name
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _Swatch(color: theme.textPrimary),
                        const SizedBox(width: 3),
                        _Swatch(color: theme.accentAction),
                        if (theme.accentPop != null) ...[
                          const SizedBox(width: 3),
                          _Swatch(color: theme.accentPop!),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            theme.name,
                            style: TextStyle(
                              color: theme.textPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check_circle_rounded,
                              size: 14, color: theme.accentAction),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  final Color color;

  const _Swatch({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
