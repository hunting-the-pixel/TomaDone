import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:numberpicker/numberpicker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TomaDone',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      // Automatically adapt to system theme
      home: const PomodoroTimerScreen(),
    );
  }
}

// Enum to manage the different states of the timer.
enum TimerState { initial, running, paused, finished }

class PomodoroTimerScreen extends StatefulWidget {
  const PomodoroTimerScreen({super.key});

  @override
  State<PomodoroTimerScreen> createState() => _PomodoroTimerScreenState();
}

class _PomodoroTimerScreenState extends State<PomodoroTimerScreen> {
  // Timer duration is configurable by the user.
  int _selectedMinutes = 25;
  int get _totalPomodoroTime => _selectedMinutes * 60;

  // State variables to manage the timer's behavior and UI.
  TimerState _timerState = TimerState.initial;
  late int _secondsRemaining;
  int _completedPomodoros = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = _totalPomodoroTime;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Formats the time in seconds into a user-friendly MM:SS string.
  String _formatTime(int seconds) {
    final minutes = (seconds / 60).floor().toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainingSeconds';
  }

  /// Calculates the timer's progress from 1.0 (start) down to 0.0 (end).
  double get _progress =>
      _totalPomodoroTime > 0 ? _secondsRemaining / _totalPomodoroTime : 1.0;

  /// Determines the color of the progress indicator based on the current timer state.
  Color get _progressColor {
    switch (_timerState) {
      case TimerState.running:
        return Colors.green;
      case TimerState.paused:
        return Colors.orange;
      case TimerState.finished:
        return Colors.greenAccent;
      default:
        return Colors.green.withValues(green: .6);
    }
  }

  /// Toggles the timer between play and pause states.
  void _togglePlayPause() {
    if (_timerState == TimerState.running) {
      _pauseTimer();
    } else {
      // If the timer is finished, pressing play will reset it for a new session.
      if (_timerState == TimerState.finished) {
        // Don't reset the pomodoro counter, just the timer itself.
        _resetTimer(resetPomodoroCounter: false);
      }
      _startTimer();
    }
  }

  /// Starts the timer, updating the UI every second.
  void _startTimer() {
    // Prevent starting if time is 0
    if (_secondsRemaining <= 0) return;

    setState(() {
      _timerState = TimerState.running;
    });

    // Create a periodic timer that fires every second.
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        // When the timer reaches 00:00.
        _timer?.cancel();
        setState(() {
          _timerState = TimerState.finished;
          _completedPomodoros++;
          // After the 4th pomodoro, the counter resets on the next completion.
          if (_completedPomodoros > 4) {
            _completedPomodoros = 0;
          }
        });
      }
    });
  }

  /// Pauses the timer and cancels the periodic updates.
  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _timerState = TimerState.paused;
    });
  }

  /// Resets the timer to its initial state. Can optionally reset the pomodoro counter.
  void _resetTimer({bool resetPomodoroCounter = true}) {
    _timer?.cancel();
    setState(() {
      _timerState = TimerState.initial;
      _secondsRemaining = _totalPomodoroTime;
      if (resetPomodoroCounter) {
        _completedPomodoros = 0;
      }
    });
  }

  /// Shows a confirmation dialog before resetting progress.
  void _showResetConfirmation() {
    // If the timer is already finished or in its initial state, reset immediately without a dialog.
    if (_timerState == TimerState.finished ||
        _timerState == TimerState.initial) {
      _resetTimer();
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Timer?'),
        content: const Text(
          'Are you sure? Your current progress will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetTimer();
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        toolbarHeight: 100,
        title: const Text('TomaDone'),
        titleTextStyle: TextStyle(
          height: 4,
          color: Theme.of(context).textTheme.bodyLarge?.color,
          fontSize: 36,
          fontWeight: FontWeight.w500,
          letterSpacing: 1,
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(5.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.values.last,
          children: [
            _buildPomodoroTracker(),
            _buildTimerDisplay(),
            _buildControls(),
          ],
        ),
      ),
    );
  }

  /// Builds the top section that tracks completed Pomodoro sessions with checkmark icons.
  Widget _buildPomodoroTracker() {
    return Container(
      margin: const EdgeInsets.only(top: 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(4, (index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Icon(
              Icons.check_circle,
              size: 36,
              // Icon color is green if completed, otherwise dimmed.
              color: index < _completedPomodoros
                  ? Colors.green
                  : Theme.of(context).colorScheme.onSurface.withAlpha(77),
            ),
          );
        }),
      ),
    );
  }

  /// Builds the central timer display using a Stack to overlay text on the progress circle.
  Widget _buildTimerDisplay() {
    return Container(
      margin: const EdgeInsets.only(bottom: 60),
      padding: const EdgeInsets.all(15.0),
      child: AspectRatio(
        aspectRatio: 1.0,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Progress circle.
            SizedBox.expand(),
            SizedBox.expand(
              child: CircularProgressIndicator(
                value: _progress,
                strokeWidth: 20,
                strokeCap: StrokeCap.round,
                valueColor: AlwaysStoppedAnimation<Color>(_progressColor),
                backgroundColor: Colors.grey.shade500.withAlpha(90),
              ),
            ),
            // Timer text and status labels in the center.
            _buildTimerCenterContent(),
          ],
        ),
      ),
    );
  }

  /// Builds the content shown in the center of the circle, changing based on state.
  Widget _buildTimerCenterContent() {
    // If finished, show "Done".
    if (_timerState == TimerState.finished) {
      return const Text(
        'Done',
        style: TextStyle(
          fontSize: 60,
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
      );
    }

    // If initial, show the number picker for minutes.
    if (_timerState == TimerState.initial) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          NumberPicker(
            value: _selectedMinutes,
            zeroPad: true,
            minValue: 5,
            maxValue: 95,
            itemHeight: 102,
            itemCount: 1,
            step: 5,
            haptics: true,
            itemWidth: 84,
            axis: Axis.vertical,
            onChanged: (value) {
              setState(() {
                _selectedMinutes = value;
                _secondsRemaining = _totalPomodoroTime;
              });
            },
            textStyle: const TextStyle(
              fontSize: 72,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
            selectedTextStyle: TextStyle(
              fontSize: 72,
              color: Theme.of(context).textTheme.bodyLarge?.color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            ':${(_secondsRemaining % 60).toString().padLeft(2, '0')}',
            style: TextStyle(
              fontSize: 72,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ],
      );
    }

    // Otherwise (running or paused), show the time and a "PAUSED" label if applicable.
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_timerState == TimerState.paused)
          Text(
            'PAUSED',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.red[200],
            ),
          ),
        Text(
          _formatTime(_secondsRemaining),
          style: const TextStyle(fontSize: 72, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  /// Builds the control buttons (Play/Pause, Restart) at the bottom.
  Widget _buildControls() {
    final bool isRunning = _timerState == TimerState.running;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Restart Button - only visible when the timer is not in its initial state.
        Visibility(
          visible: _timerState != TimerState.initial,
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          child: IconButton(
            icon: const Icon(Icons.restart_alt),
            onPressed: _showResetConfirmation,
            iconSize: 36,
          ),
        ),
        const SizedBox(width: 40),
        // Central Play/Pause Floating Action Button.
        FloatingActionButton.large(
          onPressed: _togglePlayPause,
          backgroundColor: isRunning ? Colors.orangeAccent : Colors.green,
          child: Icon(isRunning ? Icons.pause : Icons.play_arrow, size: 48),
        ),
        const SizedBox(width: 40),
        // Placeholder to keep the FAB perfectly centered.
        const Visibility(
          visible: true,
          // Always visible to maintain balance
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          child: SizedBox(width: 36),
        ),
      ],
    );
  }
}
