import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/meal.dart';
import '../utils/timer_parser.dart';

// ─── Modelo interno para un paso con timer opcional ───────────────
class _CookStep {
  final String text;
  final int? timerSeconds; // null = no hay timer
  bool checked;

  _CookStep({
    required this.text,
    this.timerSeconds,
  }) : checked = false;
}

// ─── Pantalla principal ────────────────────────────────────────────
class CookingModeScreen extends StatefulWidget {
  final Meal meal;
  final List<String> steps;

  const CookingModeScreen({
    super.key,
    required this.meal,
    required this.steps,
  });

  @override
  State<CookingModeScreen> createState() => _CookingModeScreenState();
}

class _CookingModeScreenState extends State<CookingModeScreen>
    with TickerProviderStateMixin {
  // Fases: 0 = ingredientes, 1 = pasos
  int _phase = 0;

  // Ingredientes
  late List<bool> _ingChecked;

  // Pasos
  late List<_CookStep> _cookSteps;
  int _activeStep = 0;

  // Timers por paso
  final Map<int, Timer> _timers = {};
  final Map<int, int> _remaining = {}; // segundos restantes
  final Map<int, bool> _timerRunning = {};

  // Animación de completado
  late AnimationController _celebrationCtrl;
  late Animation<double> _celebrationScale;
  bool _finished = false;

  // Progreso global
  double get _totalProgress {
    if (_phase == 0) {
      final done = _ingChecked.where((c) => c).length;
      return done / _ingChecked.length * 0.5;
    }
    final done = _cookSteps.where((s) => s.checked).length;
    return 0.5 + done / _cookSteps.length * 0.5;
  }

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _ingChecked = List.filled(widget.meal.ingredients.length, false);
    _cookSteps = widget.steps.map((text) {
      return _CookStep(text: text, timerSeconds: detectTimerSeconds(text));
    }).toList();

    for (int i = 0; i < _cookSteps.length; i++) {
      if (_cookSteps[i].timerSeconds != null) {
        _remaining[i] = _cookSteps[i].timerSeconds!;
        _timerRunning[i] = false;
      }
    }

    _celebrationCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _celebrationScale = CurvedAnimation(
      parent: _celebrationCtrl,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    for (final t in _timers.values) {
      t.cancel();
    }
    _celebrationCtrl.dispose();
    super.dispose();
  }

  void _startTimer(int stepIndex) {
    if (_timers.containsKey(stepIndex)) {
      _timers[stepIndex]!.cancel();
    }
    setState(() => _timerRunning[stepIndex] = true);

    _timers[stepIndex] = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        final r = _remaining[stepIndex]! - 1;
        if (r <= 0) {
          _remaining[stepIndex] = 0;
          _timerRunning[stepIndex] = false;
          t.cancel();
          _showTimerDone(stepIndex);
        } else {
          _remaining[stepIndex] = r;
        }
      });
    });
  }

  void _pauseTimer(int stepIndex) {
    _timers[stepIndex]?.cancel();
    setState(() => _timerRunning[stepIndex] = false);
  }

  void _resetTimer(int stepIndex) {
    _timers[stepIndex]?.cancel();
    setState(() {
      _remaining[stepIndex] = _cookSteps[stepIndex].timerSeconds!;
      _timerRunning[stepIndex] = false;
    });
  }

  void _showTimerDone(int stepIndex) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 10),
            Text(
              '¡Tiempo completado! Paso ${stepIndex + 1}',
              style: GoogleFonts.nunito(
                  color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ── Verificar completado total ───────────────────────────────────
  void _checkAllDone() {
    if (_cookSteps.every((s) => s.checked) && !_finished) {
      setState(() => _finished = true);
      _celebrationCtrl.forward();
    }
  }

  // ─────────────────────────── BUILD ─────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F4F0),
      body: Column(
        children: [
          _buildHeader(),
          _buildProgressBar(),
          Expanded(
            child: _finished
                ? _buildFinishedScreen()
                : _phase == 0
                    ? _buildIngredientsPhase()
                    : _buildStepsPhase(),
          ),
          if (!_finished) _buildBottomBar(),
        ],
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Imagen de fondo difuminada
            Positioned.fill(
              child: Opacity(
                opacity: 0.25,
                child: CachedNetworkImage(
                  imageUrl: widget.meal.thumbnail,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => _confirmExit(),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8490F),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.menu_book,
                                color: Colors.white, size: 14),
                            const SizedBox(width: 5),
                            Text(
                              'Modo Cocinero',
                              style: GoogleFonts.nunito(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.meal.name,
                          style: GoogleFonts.playfairDisplay(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _phase == 0
                              ? '📋 Paso 1 de 2 — Prepara los ingredientes'
                              : '👨‍🍳 Paso 2 de 2 — Manos a la obra',
                          style: GoogleFonts.nunito(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Barra de progreso ────────────────────────────────────────────
  Widget _buildProgressBar() {
    final pct = _totalProgress;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _phase == 0
                    ? '${_ingChecked.where((c) => c).length}/${_ingChecked.length} ingredientes'
                    : '${_cookSteps.where((s) => s.checked).length}/${_cookSteps.length} pasos',
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF555555),
                ),
              ),
              Text(
                '${(pct * 100).round()}% completado',
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  color: const Color(0xFFE8490F),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: pct),
              duration: const Duration(milliseconds: 400),
              builder: (_, value, __) => LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: const Color(0xFFEEEEEE),
                valueColor: AlwaysStoppedAnimation(
                  value >= 1.0 ? Colors.green : const Color(0xFFE8490F),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── FASE 1: Ingredientes ─────────────────────────────────────────
  Widget _buildIngredientsPhase() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Row(
            children: [
              const Icon(Icons.shopping_basket,
                  color: Color(0xFFE8490F), size: 22),
              const SizedBox(width: 8),
              Text(
                'Comprueba que tienes todo',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Text(
            'Marca cada ingrediente antes de empezar a cocinar.',
            style: GoogleFonts.nunito(
                fontSize: 13, color: const Color(0xFF888888)),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            itemCount: widget.meal.ingredients.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: Color(0xFFEEEEEE)),
            itemBuilder: (context, i) {
              final ing = widget.meal.ingredients[i];
              final checked = _ingChecked[i];
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                color: checked
                    ? Colors.green.withValues(alpha: 0.05)
                    : Colors.white,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  leading: GestureDetector(
                    onTap: () => setState(() => _ingChecked[i] = !checked),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: checked
                            ? Colors.green
                            : Colors.transparent,
                        border: Border.all(
                          color: checked
                              ? Colors.green
                              : const Color(0xFFCCCCCC),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: checked
                          ? const Icon(Icons.check,
                              color: Colors.white, size: 16)
                          : null,
                    ),
                  ),
                  title: Text(
                    ing.name,
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: checked
                          ? const Color(0xFF888888)
                          : const Color(0xFF1A1A1A),
                      decoration: checked
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  trailing: ing.measure.isNotEmpty
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: checked
                                ? Colors.green.withValues(alpha: 0.1)
                                : const Color(0xFFE8490F).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            ing.measure,
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: checked
                                  ? Colors.green
                                  : const Color(0xFFE8490F),
                            ),
                          ),
                        )
                      : null,
                  onTap: () =>
                      setState(() => _ingChecked[i] = !checked),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── FASE 2: Pasos ────────────────────────────────────────────────
  Widget _buildStepsPhase() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _cookSteps.length,
      itemBuilder: (context, i) {
        final step = _cookSteps[i];
        final isActive = i == _activeStep;
        final isLocked = i > _activeStep && !step.checked;
        final isDone = step.checked;

        return GestureDetector(
          onTap: isLocked ? null : () => setState(() => _activeStep = i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isDone
                  ? Colors.green.withValues(alpha: 0.06)
                  : isActive
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDone
                    ? Colors.green.withValues(alpha: 0.3)
                    : isActive
                        ? const Color(0xFFE8490F)
                        : Colors.transparent,
                width: isActive ? 2 : 1,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: const Color(0xFFE8490F).withValues(alpha: 0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Número y check
                  Row(
                    children: [
                      _StepBubble(
                          number: i + 1, isDone: isDone, isActive: isActive),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Paso ${i + 1}',
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDone
                                ? Colors.green
                                : isActive
                                    ? const Color(0xFFE8490F)
                                    : const Color(0xFFAAAAAA),
                          ),
                        ),
                      ),
                      if (isLocked)
                        const Icon(Icons.lock_outline,
                            size: 16, color: Color(0xFFCCCCCC)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Texto del paso
                  Text(
                    step.text,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      height: 1.6,
                      color: isLocked
                          ? const Color(0xFFBBBBBB)
                          : const Color(0xFF333333),
                    ),
                  ),
                  // Timer (si aplica y está activo o hecho)
                  if (step.timerSeconds != null &&
                      (isActive || isDone)) ...[
                    const SizedBox(height: 14),
                    _buildTimer(i, step),
                  ],
                  // Botón de marcar (solo paso activo no hecho)
                  if (isActive && !isDone) ...[
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _cookSteps[i].checked = true;
                            if (i + 1 < _cookSteps.length) {
                              _activeStep = i + 1;
                            }
                          });
                          _checkAllDone();
                        },
                        icon: const Icon(Icons.check_circle_outline,
                            size: 18),
                        label: Text(
                          '✓  Paso completado',
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE8490F),
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                  // Badge "Completado" si ya hecho
                  if (isDone) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.check_circle,
                            color: Colors.green, size: 16),
                        const SizedBox(width: 5),
                        Text(
                          'Completado',
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            color: Colors.green,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Timer widget ─────────────────────────────────────────────────
  Widget _buildTimer(int i, _CookStep step) {
    final remaining = _remaining[i] ?? step.timerSeconds!;
    final running = _timerRunning[i] ?? false;
    final total = step.timerSeconds!;
    final progress = remaining / total;
    final done = remaining == 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: done
            ? Colors.green.withValues(alpha: 0.1)
            : const Color(0xFF1A1A1A).withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: done
              ? Colors.green.withValues(alpha: 0.3)
              : const Color(0xFFE8490F).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          // Icono
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: done
                  ? Colors.green.withValues(alpha: 0.15)
                  : const Color(0xFFE8490F).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              done ? Icons.check : Icons.timer,
              color: done ? Colors.green : const Color(0xFFE8490F),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Tiempo y barra
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  done ? '¡Listo!' : formatTime(remaining),
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: done ? Colors.green : const Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: 1 - progress,
                    minHeight: 4,
                    backgroundColor: const Color(0xFFEEEEEE),
                    valueColor: AlwaysStoppedAnimation(
                      done ? Colors.green : const Color(0xFFE8490F),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Botones control
          if (!done) ...[
            if (!running)
              _TimerBtn(
                icon: Icons.play_arrow,
                color: const Color(0xFFE8490F),
                onTap: () => _startTimer(i),
              )
            else
              _TimerBtn(
                icon: Icons.pause,
                color: Colors.orange,
                onTap: () => _pauseTimer(i),
              ),
            const SizedBox(width: 6),
            _TimerBtn(
              icon: Icons.refresh,
              color: const Color(0xFF888888),
              onTap: () => _resetTimer(i),
            ),
          ],
        ],
      ),
    );
  }

  // ── Pantalla de éxito ────────────────────────────────────────────
  Widget _buildFinishedScreen() {
    return ScaleTransition(
      scale: _celebrationScale,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('🍽️', style: TextStyle(fontSize: 52)),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '¡Plato listo!',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.meal.name,
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  color: const Color(0xFFE8490F),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '¡Enhorabuena! Has completado todos los pasos correctamente. ¡A disfrutar!',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  color: const Color(0xFF888888),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.home),
                  label: Text(
                    'Volver al inicio',
                    style: GoogleFonts.nunito(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE8490F),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Barra inferior ───────────────────────────────────────────────
  Widget _buildBottomBar() {
    if (_phase == 0) {
      final allChecked = _ingChecked.every((c) => c);
      return Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!allChecked)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.info_outline,
                        size: 14, color: Color(0xFFAAAAAA)),
                    const SizedBox(width: 5),
                    Text(
                      'Marca todos los ingredientes para continuar',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        color: const Color(0xFFAAAAAA),
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: allChecked
                    ? () => setState(() => _phase = 1)
                    : null,
                icon: const Icon(Icons.arrow_forward, size: 20),
                label: Text(
                  '¡A cocinar!',
                  style: GoogleFonts.nunito(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE8490F),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      const Color(0xFFE8490F).withValues(alpha: 0.35),
                  disabledForegroundColor: Colors.white70,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Fase de pasos — solo info de progreso
    final done = _cookSteps.where((s) => s.checked).length;
    final total = _cookSteps.length;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.flag_outlined,
              color: Color(0xFFE8490F), size: 18),
          const SizedBox(width: 8),
          Text(
            '$done de $total pasos completados',
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF555555),
            ),
          ),
        ],
      ),
    );
  }

  // ── Confirmar salida ─────────────────────────────────────────────
  Future<void> _confirmExit() async {
    final exit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('¿Salir del Modo Cocinero?',
            style: GoogleFonts.playfairDisplay(fontSize: 18)),
        content: Text(
          'Perderás el progreso actual de esta sesión.',
          style: GoogleFonts.nunito(fontSize: 14, color: Colors.grey[600]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                Text('Continuar', style: GoogleFonts.nunito(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE8490F),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Salir',
                style:
                    GoogleFonts.nunito(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (exit == true && mounted) Navigator.pop(context);
  }
}

// ─── Widgets auxiliares ───────────────────────────────────────────

class _StepBubble extends StatelessWidget {
  final int number;
  final bool isDone;
  final bool isActive;

  const _StepBubble(
      {required this.number,
      required this.isDone,
      required this.isActive});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    Widget child;

    if (isDone) {
      bg = Colors.green;
      fg = Colors.white;
      child = const Icon(Icons.check, color: Colors.white, size: 16);
    } else if (isActive) {
      bg = const Color(0xFFE8490F);
      fg = Colors.white;
      child = Text('$number',
          style: GoogleFonts.nunito(
              color: fg, fontWeight: FontWeight.bold, fontSize: 13));
    } else {
      bg = const Color(0xFFEEEEEE);
      fg = const Color(0xFF999999);
      child = Text('$number',
          style: GoogleFonts.nunito(
              color: fg, fontWeight: FontWeight.bold, fontSize: 13));
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 30,
      height: 30,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Center(child: child),
    );
  }
}

class _TimerBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _TimerBtn(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}