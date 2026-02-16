// main.dart
// Flutter 雛形：全画面タップで +1、左下 -1、下中央リセット(確認あり)、右下設定
// 背景は毎操作（+/-）でランダムグラデーションに変化（AnimatedContainerで滑らかに遷移）

import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

void main() {
  runApp(const CounterApp());
}

class CounterApp extends StatelessWidget {
  const CounterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tap Counter',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: const CounterScreen(),
    );
  }
}

class CounterScreen extends StatefulWidget {
  const CounterScreen({super.key});

  @override
  State<CounterScreen> createState() => _CounterScreenState();
}

class _CounterScreenState extends State<CounterScreen>
    with SingleTickerProviderStateMixin {
  int _count = 0;
  final Random _rng = Random();

  late LinearGradient _bg;

  // 数字バウンド用
  late final AnimationController _popCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 110),
    lowerBound: 0.0,
    upperBound: 1.0,
  );

  late final Animation<double> _popScale = Tween<double>(begin: 1.0, end: 1.08)
      .chain(CurveTween(curve: Curves.easeOut))
      .animate(_popCtrl);

  @override
  void initState() {
    super.initState();
    _bg = _randomGamingGradient();
  }

  @override
  void dispose() {
    _popCtrl.dispose();
    super.dispose();
  }

  void _bump() {
    // 連打でも気持ちよくする
    _popCtrl.forward(from: 0);
  }

  void _inc() {
    setState(() {
      _count += 1;
      _bg = _randomGamingGradient();
    });
    _bump();
  }

  void _dec() {
    setState(() {
      _count -= 1;
      _bg = _randomGamingGradient();
    });
    _bump();
  }

  Future<void> _confirmReset() async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          title: const Text('リセットしますか？'),
          content: const Text('カウントを 0 に戻します。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('リセット'),
            ),
          ],
        );
      },
    );

    if (ok == true) {
      setState(() {
        _count = 0;
        _bg = _randomGamingGradient(); // リセット後も雰囲気変える
      });
      _bump();
    }
  }

  void _openSettings() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.black.withOpacity(0.65),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ListTile(
                  title: Text(
                    '設定（仮）',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('ここにバイブ/サウンド等を追加していく想定'),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.palette_outlined),
                  title: const Text('背景をランダム更新'),
                  subtitle: const Text('テスト用：今の背景を変える'),
                  onTap: () {
                    setState(() => _bg = _randomGamingGradient());
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.close),
                  title: const Text('閉じる'),
                  onTap: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 「ゲーミングっぽいけど下品すぎない」寄せ方：
  // - 彩度高めのネオン系をベースにしつつ、黒/濃紺寄りの色も混ぜる
  LinearGradient _randomGamingGradient() {
    final neon = <Color>[
      const Color(0xFF00E5FF), // cyan
      const Color(0xFF7C4DFF), // deep purple
      const Color(0xFFFF1744), // neon red
      const Color(0xFF1DE9B6), // teal/mint
      const Color(0xFFFFEA00), // yellow
      const Color(0xFFFF3D00), // orange red
      const Color(0xFF00C853), // green
      const Color(0xFFD500F9), // magenta
    ];

    // 暗めを混ぜる（実用的に落ち着かせる）
    final darks = <Color>[
      const Color(0xFF060A10),
      const Color(0xFF070B1E),
      const Color(0xFF0B1026),
      const Color(0xFF0A0F14),
    ];

    // 3色グラデ：ネオン2 + 暗め1（順番ランダム）
    final c1 = neon[_rng.nextInt(neon.length)];
    final c2 = neon[_rng.nextInt(neon.length)];
    final c3 = darks[_rng.nextInt(darks.length)];

    final colors = [c1, c2, c3]..shuffle(_rng);

    final begin = Alignment(
      _rng.nextDouble() * 2 - 1,
      _rng.nextDouble() * 2 - 1,
    );
    final end = Alignment(
      _rng.nextDouble() * 2 - 1,
      _rng.nextDouble() * 2 - 1,
    );

    return LinearGradient(
      begin: begin,
      end: end,
      colors: colors,
      stops: const [0.0, 0.55, 1.0],
    );
  }

  @override
  Widget build(BuildContext context) {
    // ボタンが下にあるので、誤タップを避けるために下部は少し余白を持たせる
    const bottomBarHeight = 92.0;

    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _inc,
        child: Stack(
          children: [
            // 背景（滑らかに遷移）
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(gradient: _bg),
            ),

            // うっすらゲーミング感：ノイズっぽい上掛け（軽量）
            IgnorePointer(
              child: Opacity(
                opacity: 0.08,
                child: CustomPaint(
                  painter: _NoisePainter(seed: _count),
                  size: Size.infinite,
                ),
              ),
            ),

            // 中央カウント
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: bottomBarHeight * 0.35),
                child: ScaleTransition(
                  scale: _popScale,
                  child: _GlowingText(
                    _count.toString(),
                    fontSize: 110,
                  ),
                ),
              ),
            ),

            // 下部ボタン群
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: SafeArea(
                top: false,
                child: SizedBox(
                  height: bottomBarHeight - 16,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // 左下：マイナス
                      _GlassIconButton(
                        icon: Icons.remove,
                        label: '-',
                        onPressed: _dec,
                      ),
                      const Spacer(),

                      // 下中央：リセット
                      _GlassIconButton(
                        icon: Icons.restart_alt,
                        label: 'Reset',
                        onPressed: _confirmReset,
                        emphasis: true,
                      ),
                      const Spacer(),

                      // 右下：設定
                      _GlassIconButton(
                        icon: Icons.settings,
                        label: '⚙',
                        onPressed: _openSettings,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ちょい案内（消したければここ削除）
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: SafeArea(
                bottom: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    _HintChip(text: '画面タップで +1'),
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

class _GlowingText extends StatelessWidget {
  final String text;
  final double fontSize;

  const _GlowingText(this.text, {required this.fontSize});

  @override
  Widget build(BuildContext context) {
    // “エンジニアが使ってそう”に寄せて等幅フォント
    final style = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
      fontFeatures: const [FontFeature.tabularFigures()],
      letterSpacing: -2,
      height: 1.0,
      color: Colors.white,
      shadows: const [
        Shadow(blurRadius: 18, color: Color(0xAA00E5FF), offset: Offset(0, 0)),
        Shadow(blurRadius: 28, color: Color(0x6600E5FF), offset: Offset(0, 0)),
      ],
    );

    return Text(
      text,
      textAlign: TextAlign.center,
      style: style,
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool emphasis;

  const _GlassIconButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.emphasis = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);

    return SizedBox(
      width: emphasis ? 120 : 76,
      height: 62,
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Material(
            color: Colors.white.withOpacity(emphasis ? 0.14 : 0.10),
            child: InkWell(
              onTap: onPressed,
              splashColor: Colors.white.withOpacity(0.10),
              highlightColor: Colors.white.withOpacity(0.06),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: emphasis ? 24 : 22),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: TextStyle(
                        fontWeight:
                            emphasis ? FontWeight.w800 : FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HintChip extends StatelessWidget {
  final String text;
  const _HintChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.25),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withOpacity(0.85),
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}

/// 軽いノイズ風ペインター（見た目の“ゲーミング”をほんのり足す）
/// seedを変えるとパターンも変化するので、毎カウントでちょっと変わる感じになる
class _NoisePainter extends CustomPainter {
  final int seed;
  _NoisePainter({required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(seed);
    final paint = Paint()..color = Colors.white;

    // 点を少しだけ散らす（重すぎないように数を抑える）
    final count = (size.width * size.height / 12000).clamp(80, 220).toInt();
    for (int i = 0; i < count; i++) {
      final dx = rng.nextDouble() * size.width;
      final dy = rng.nextDouble() * size.height;
      final r = rng.nextDouble() * 1.2 + 0.2;
      paint.color = Colors.white.withOpacity(rng.nextDouble() * 0.8);
      canvas.drawCircle(Offset(dx, dy), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _NoisePainter oldDelegate) {
    return oldDelegate.seed != seed;
  }
}
