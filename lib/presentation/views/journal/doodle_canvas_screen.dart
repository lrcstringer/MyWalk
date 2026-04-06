import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:perfect_freehand/perfect_freehand.dart';

// ── Public entry point ────────────────────────────────────────────────────────

class DoodleCanvasScreen extends StatefulWidget {
  /// Accent colour used for selection rings and the Done button.
  final Color accentColor;

  const DoodleCanvasScreen({super.key, required this.accentColor});

  @override
  State<DoodleCanvasScreen> createState() => _DoodleCanvasScreenState();
}

// ── Internal model ────────────────────────────────────────────────────────────

class _Stroke {
  final List<PointVector> points;
  final Color color;
  final double size;

  const _Stroke({
    required this.points,
    required this.color,
    required this.size,
  });
}

// ── Helpers ───────────────────────────────────────────────────────────────────

Path _strokeToPath(List<Offset> outlinePoints) {
  if (outlinePoints.isEmpty) return Path();
  final path = Path()
    ..moveTo(outlinePoints.first.dx, outlinePoints.first.dy);
  for (final p in outlinePoints.skip(1)) {
    path.lineTo(p.dx, p.dy);
  }
  return path..close();
}

List<Offset> _getOutline(List<PointVector> points, double size) =>
    getStroke(
      points,
      options: StrokeOptions(
        size: size,
        smoothing: 0.5,
        thinning: 0.5,
        simulatePressure: true,
      ),
    );

// ── State ─────────────────────────────────────────────────────────────────────

class _DoodleCanvasScreenState extends State<DoodleCanvasScreen> {
  static const _strokeSize = 6.0;
  static const _palette = [
    Colors.black,
    Color(0xFF1B4F8A), // deep blue
    Color(0xFFB22222), // crimson
    Color(0xFF2D7D32), // forest green
    Color(0xFF6B3FA0), // purple
    Colors.white, // eraser — draws in white on white bg
  ];

  final List<_Stroke> _strokes = [];
  List<PointVector> _currentPoints = [];
  Color _color = Colors.black;
  Size? _canvasSize;
  bool _isExporting = false;

  // ── Gesture handlers ────────────────────────────────────────────────────────

  void _onPanStart(DragStartDetails d) => setState(() {
        _currentPoints = [
          PointVector(d.localPosition.dx, d.localPosition.dy, 0.5)
        ];
      });

  void _onPanUpdate(DragUpdateDetails d) => setState(() {
        _currentPoints = [
          ..._currentPoints,
          PointVector(d.localPosition.dx, d.localPosition.dy, 0.5),
        ];
      });

  void _onPanEnd(DragEndDetails _) {
    if (_currentPoints.isNotEmpty) {
      setState(() {
        _strokes.add(_Stroke(
          points: List.of(_currentPoints),
          color: _color,
          size: _strokeSize,
        ));
        _currentPoints = [];
      });
    }
  }

  // ── Actions ─────────────────────────────────────────────────────────────────

  void _undo() => setState(() {
        if (_strokes.isNotEmpty) _strokes.removeLast();
      });

  void _clear() => setState(() {
        _strokes.clear();
        _currentPoints = [];
      });

  Future<void> _done() async {
    if (_strokes.isEmpty) {
      Navigator.pop(context);
      return;
    }
    setState(() => _isExporting = true);
    try {
      final path = await _exportAsPng();
      if (mounted) Navigator.pop(context, path);
    } catch (_) {
      if (mounted) {
        setState(() => _isExporting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save doodle'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<String> _exportAsPng() async {
    final size = _canvasSize!;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, size.width, size.height),
    );

    // White background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.white,
    );

    for (final stroke in _strokes) {
      final outline = _getOutline(stroke.points, stroke.size);
      canvas.drawPath(
        _strokeToPath(outline),
        Paint()
          ..color = stroke.color
          ..style = PaintingStyle.fill,
      );
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.width.toInt(), size.height.toInt());
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);

    final dir = await getApplicationDocumentsDirectory();
    final file = File(
        '${dir.path}/doodle_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    return file.path;
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        title: const Text(
          'Doodle',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        actions: [
          if (_strokes.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.undo),
              tooltip: 'Undo',
              onPressed: _undo,
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear all',
            onPressed: _strokes.isNotEmpty ? _clear : null,
          ),
          if (_isExporting)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _done,
              child: Text(
                'Done',
                style: TextStyle(
                  color: widget.accentColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          _ColorPalette(
            palette: _palette,
            selected: _color,
            accentColor: widget.accentColor,
            onSelect: (c) => setState(() => _color = c),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                _canvasSize =
                    Size(constraints.maxWidth, constraints.maxHeight);
                return GestureDetector(
                  onPanStart: _onPanStart,
                  onPanUpdate: _onPanUpdate,
                  onPanEnd: _onPanEnd,
                  child: CustomPaint(
                    painter: _DoodlePainter(
                      strokes: _strokes,
                      currentPoints: _currentPoints,
                      currentColor: _color,
                      currentSize: _strokeSize,
                    ),
                    size: Size.infinite,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Color palette bar ─────────────────────────────────────────────────────────

class _ColorPalette extends StatelessWidget {
  final List<Color> palette;
  final Color selected;
  final Color accentColor;
  final ValueChanged<Color> onSelect;

  const _ColorPalette({
    required this.palette,
    required this.selected,
    required this.accentColor,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: palette.map((c) {
          final isSelected = selected == c;
          final isEraser = c == Colors.white;
          return GestureDetector(
            onTap: () => onSelect(c),
            child: Container(
              width: 30,
              height: 30,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? accentColor : Colors.grey.shade300,
                  width: isSelected ? 2.5 : 1,
                ),
                boxShadow: isEraser
                    ? [
                        BoxShadow(
                          color: Colors.grey.shade300,
                          blurRadius: 3,
                          spreadRadius: 1,
                        )
                      ]
                    : null,
              ),
              child: isEraser
                  ? Icon(Icons.auto_fix_high,
                      size: 15, color: Colors.grey.shade500)
                  : null,
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Canvas painter ────────────────────────────────────────────────────────────

class _DoodlePainter extends CustomPainter {
  final List<_Stroke> strokes;
  final List<PointVector> currentPoints;
  final Color currentColor;
  final double currentSize;

  const _DoodlePainter({
    required this.strokes,
    required this.currentPoints,
    required this.currentColor,
    required this.currentSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      _paint(canvas, stroke.points, stroke.color, stroke.size);
    }
    if (currentPoints.isNotEmpty) {
      _paint(canvas, currentPoints, currentColor, currentSize);
    }
  }

  void _paint(
      Canvas canvas, List<PointVector> points, Color color, double size) {
    final outline = _getOutline(points, size);
    if (outline.isEmpty) return;
    canvas.drawPath(
      _strokeToPath(outline),
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_DoodlePainter old) => true;
}
