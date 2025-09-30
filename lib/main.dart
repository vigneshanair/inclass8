import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MoodModel()),
        ChangeNotifierProvider(create: (_) => ThemeModel()),
      ],
      child: const MyApp(),
    ),
  );
}

/// ---------- Models ----------
enum Mood { happy, sad, excited }

class MoodModel with ChangeNotifier {
  Mood _current = Mood.happy;
  final Map<Mood, int> _counts = {for (var m in Mood.values) m: 0};
  final List<Mood> _history = [];

  Mood get current => _current;
  Map<Mood, int> get counts => Map.unmodifiable(_counts);
  List<Mood> get history => List.unmodifiable(_history);

  void setMood(Mood mood) {
    _current = mood;
    _counts[mood] = (_counts[mood] ?? 0) + 1;
    _history.insert(0, mood);
    if (_history.length > 3) _history.removeLast();
    notifyListeners();
  }

  void randomize() {
    final idx = math.Random().nextInt(Mood.values.length);
    setMood(Mood.values[idx]);
  }

  String get asset => switch (_current) {
        Mood.happy => 'assets/moods/happy.png',
        Mood.sad => 'assets/moods/sad.png',
        Mood.excited => 'assets/moods/excited.png',
      };

  String get title => switch (_current) {
        Mood.happy => 'Happy',
        Mood.sad => 'Sad',
        Mood.excited => 'Excited',
      };

  String get subtitle => switch (_current) {
        Mood.happy => 'Sunshine vibes. Keep smiling!',
        Mood.sad => 'It’s okay to slow down today.',
        Mood.excited => 'Big energy! Let’s go!',
      };

  Color get baseColor => switch (_current) {
        Mood.happy => const Color(0xFF2ECC71),
        Mood.sad => const Color(0xFF3498DB),
        Mood.excited => const Color(0xFFE67E22),
      };

  List<Color> get gradient => switch (_current) {
        Mood.happy => const [
            Color(0xFFFFFEEB),
            Color(0xFFFFF7BD),
            Color(0xFFFFFEEB)
          ],
        Mood.sad => const [
            Color(0xFFEFF6FF),
            Color(0xFFDCEBFF),
            Color(0xFFEFF6FF)
          ],
        Mood.excited => const [
            Color(0xFFFFF2E6),
            Color(0xFFFFE2C7),
            Color(0xFFFFF2E6)
          ],
      };
}

class ThemeModel with ChangeNotifier {
  bool _dark = false;
  bool get dark => _dark;
  void toggle() {
    _dark = !_dark;
    notifyListeners();
  }
}

/// ---------- App ----------
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = context.watch<ThemeModel>().dark;
    final textTheme = GoogleFonts.interTextTheme();

    final lightTheme = ThemeData(
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6C63FF)),
      textTheme: textTheme,
      useMaterial3: true,
    );

    final darkTheme = ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6C63FF),
        brightness: Brightness.dark,
      ),
      textTheme: textTheme,
      useMaterial3: true,
    );

    return MaterialApp(
      title: 'Mood',
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      theme: lightTheme,
      darkTheme: darkTheme,
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}

/// ---------- UI ----------
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Parallax tilt
  double _dx = 0, _dy = 0;
  void _updateTilt(DragUpdateDetails d, double boxSize) {
    setState(() {
      // normalize by box size for consistent tilt on small screens
      _dx = (d.localPosition.dx / boxSize) - 0.5;
      _dy = (d.localPosition.dy / boxSize) - 0.5;
      _dx = _dx.clamp(-0.6, 0.6);
      _dy = _dy.clamp(-0.6, 0.6);
    });
  }

  void _resetTilt([_]) => setState(() {
        _dx = 0;
        _dy = 0;
      });

  @override
  Widget build(BuildContext context) {
    final mood = context.watch<MoodModel>();
    final theme = context.watch<ThemeModel>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
        title: Text('How are you feeling?',
            style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            tooltip: theme.dark ? 'Light mode' : 'Dark mode',
            onPressed: () => context.read<ThemeModel>().toggle(),
            icon: Icon(theme.dark ? Icons.wb_sunny : Icons.dark_mode),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, c) {
          final width = c.maxWidth;
          final height = c.maxHeight;

          // ----- Responsive sizing to prevent overflow -----
          final contentMaxWidth = width.clamp(320.0, 680.0);
          final verticalPad = height < 700 ? 12.0 : 20.0;
          final topPad = (height < 700) ? 80.0 : 110.0;

          // Image size scales with screen; capped to avoid overflow.
          final imageSize = [
            220.0,
            width * 0.55,
            height * 0.28, // keep under ~30% of height
          ].reduce((a, b) => a < b ? a : b).clamp(140.0, 260.0);

          // Container for tilt gestures uses a square close to imageSize
          final tiltBox = (imageSize + 36).clamp(160.0, 300.0);

          return Stack(
            children: [
              _AnimatedMoodBackground(
                  colors: mood.gradient, seed: mood.baseColor),
              // Use SafeArea + SingleChildScrollView to eliminate bottom overflow.
              SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: contentMaxWidth),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(16, topPad, 16, verticalPad),
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _GlassCard(
                            highlight: mood.baseColor.withOpacity(.25),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  onPanUpdate: (d) =>
                                      _updateTilt(d, tiltBox.toDouble()),
                                  onPanEnd: _resetTilt,
                                  onPanCancel: _resetTilt,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 220),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(22),
                                      border: Border.all(
                                        color: mood.baseColor.withOpacity(.28),
                                        width: 1.1,
                                      ),
                                    ),
                                    child: AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      switchInCurve: Curves.easeOut,
                                      switchOutCurve: Curves.easeIn,
                                      transitionBuilder: (child, a) =>
                                          FadeTransition(
                                        opacity: a,
                                        child: ScaleTransition(
                                          scale: Tween(begin: .98, end: 1.0)
                                              .animate(a),
                                          child: child,
                                        ),
                                      ),
                                      child: Transform(
                                        key: ValueKey(mood.asset),
                                        alignment: Alignment.center,
                                        transform: Matrix4.identity()
                                          ..setEntry(3, 2, 0.0015)
                                          ..rotateX(_dy * -0.6)
                                          ..rotateY(_dx * 0.6)
                                          ..scale(1 +
                                              (_dx.abs() + _dy.abs()) * 0.02),
                                        child: Image.asset(
                                          mood.asset,
                                          width: imageSize,
                                          height: imageSize,
                                          fit: BoxFit.contain,
                                          errorBuilder: (c, e, s) => SizedBox(
                                            width: imageSize,
                                            height: imageSize,
                                            child: const Center(
                                              child: Icon(Icons.broken_image,
                                                  size: 64),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  mood.title,
                                  style: GoogleFonts.inter(
                                    fontSize: height < 700 ? 24 : 28,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  mood.subtitle,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontSize: height < 700 ? 14 : 15,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(.72),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          const _MoodSegmented(),
                          const SizedBox(height: 14),
                          const _MoodCounters(),
                          const SizedBox(height: 10),
                          const _MoodHistory(),
                          const SizedBox(height: 14),
                          _RandomButton(color: mood.baseColor),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Animated background (gentle blobs)
class _AnimatedMoodBackground extends StatefulWidget {
  final List<Color> colors;
  final Color seed;
  const _AnimatedMoodBackground({required this.colors, required this.seed});
  @override
  State<_AnimatedMoodBackground> createState() =>
      _AnimatedMoodBackgroundState();
}

class _AnimatedMoodBackgroundState extends State<_AnimatedMoodBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 12))
        ..repeat();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: widget.colors),
      ),
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          final t = _c.value * 2 * math.pi;
          final a = 0.25 + 0.1 * math.sin(t);
          final b = 0.20 + 0.1 * math.cos(t * 1.2);
          final c = 0.18 + 0.08 * math.sin(t * 0.8 + 1.3);
          return Stack(
            children: [
              _blob(Offset(0.2 + 0.05 * math.sin(t), 0.25),
                  widget.seed.withOpacity(a)),
              _blob(Offset(0.85 + 0.04 * math.cos(t * 1.1), 0.3),
                  cs.primary.withOpacity(b)),
              _blob(Offset(0.5 + 0.06 * math.sin(t * .7), 0.85),
                  cs.secondary.withOpacity(c)),
            ],
          );
        },
      ),
    );
  }

  Widget _blob(Offset pos, Color color) {
    return Positioned.fill(
      child: FractionallySizedBox(
        alignment: Alignment(pos.dx * 2 - 1, pos.dy * 2 - 1),
        widthFactor: 0.6,
        heightFactor: 0.6,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [color, color.withOpacity(0)]),
          ),
        ),
      ),
    );
  }
}

/// Frosted glass card
class _GlassCard extends StatelessWidget {
  final Widget child;
  final Color highlight;
  const _GlassCard({required this.child, required this.highlight});
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withOpacity(0.06)
                : Colors.white.withOpacity(0.55),
            border: Border.all(color: highlight.withOpacity(.5), width: 1.0),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x23000000),
                  blurRadius: 28,
                  offset: Offset(0, 14))
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Segmented moods
class _MoodSegmented extends StatelessWidget {
  const _MoodSegmented();
  @override
  Widget build(BuildContext context) {
    final model = context.watch<MoodModel>();
    final items = <({Mood mood, IconData icon, String label})>[
      (mood: Mood.happy, icon: Icons.sentiment_satisfied_alt, label: 'Happy'),
      (mood: Mood.sad, icon: Icons.sentiment_dissatisfied, label: 'Sad'),
      (mood: Mood.excited, icon: Icons.celebration, label: 'Excited'),
    ];
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(.06), width: 1.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: SegmentedButton<Mood>(
          segments: [
            for (final it in items)
              ButtonSegment(
                  value: it.mood, icon: Icon(it.icon), label: Text(it.label))
          ],
          selected: {model.current},
          showSelectedIcon: false,
          onSelectionChanged: (set) {
            if (set.isNotEmpty) context.read<MoodModel>().setMood(set.first);
          },
        ),
      ),
    );
  }
}

/// Counters row
class _MoodCounters extends StatelessWidget {
  const _MoodCounters();
  @override
  Widget build(BuildContext context) {
    final counts = context.watch<MoodModel>().counts;
    Widget chip(IconData icon, String label, int count) => Chip(
          avatar: Icon(icon, size: 18),
          label: Text('$label • $count'),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        );
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: [
        chip(Icons.sentiment_satisfied_alt, 'Happy', counts[Mood.happy] ?? 0),
        chip(Icons.sentiment_dissatisfied, 'Sad', counts[Mood.sad] ?? 0),
        chip(Icons.celebration, 'Excited', counts[Mood.excited] ?? 0),
      ],
    );
  }
}

/// Last 3 history
class _MoodHistory extends StatelessWidget {
  const _MoodHistory();
  @override
  Widget build(BuildContext context) {
    final history = context.watch<MoodModel>().history;
    if (history.isEmpty) {
      return Text('No history yet',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600));
    }
    IconData iconFor(Mood m) => switch (m) {
          Mood.happy => Icons.sentiment_satisfied_alt,
          Mood.sad => Icons.sentiment_dissatisfied,
          Mood.excited => Icons.celebration,
        };
    return Column(
      children: [
        Text('Recent selections',
            style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final m in history)
              Chip(
                avatar: Icon(iconFor(m), size: 18),
                label: Text(m.name[0].toUpperCase() + m.name.substring(1)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
          ],
        ),
      ],
    );
  }
}

/// Random button
class _RandomButton extends StatefulWidget {
  final Color color;
  const _RandomButton({required this.color});
  @override
  State<_RandomButton> createState() => _RandomButtonState();
}

class _RandomButtonState extends State<_RandomButton> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _down ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 90),
      child: FilledButton.icon(
        onPressed: () {
          setState(() => _down = true);
          Future.delayed(const Duration(milliseconds: 110), () {
            setState(() => _down = false);
            context.read<MoodModel>().randomize();
          });
        },
        icon: const Icon(Icons.shuffle),
        label: const Text('Random Mood'),
        style: ButtonStyle(
          padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 18, vertical: 14)),
          backgroundColor: WidgetStatePropertyAll(widget.color),
          foregroundColor: const WidgetStatePropertyAll(Colors.white),
        ),
      ),
    );
  }
}
