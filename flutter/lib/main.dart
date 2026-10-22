// StudyBuddy — study & habit tracker for students (MVP)
// Single-file Flutter app, no external packages.
// Run: flutter create study_buddy  ->  replace lib/main.dart  ->  flutter run

import 'dart:async';
import 'package:flutter/material.dart';

void main() => runApp(const StudyBuddyApp());

// ---------------------------------------------------------------------------
// App state (in memory)
// ---------------------------------------------------------------------------

class StudyTask {
  StudyTask(this.title, this.subject, {this.done = false});
  final String title;
  final String subject;
  bool done;
}

class AppState extends ChangeNotifier {
  String name = '';
  int dailyGoalMinutes = 50;
  int streakDays = 4;
  int bestStreak = 9;
  int todayMinutes = 0;
  int weekMinutes = 180;
  int totalMinutes = 1240;
  int sessionsToday = 0;
  bool goalMetToday = false;

  final List<String> subjects = ['Math', 'English', 'Physics', 'History', 'IT'];
  final Map<String, int> minutesBySubject = {
    'Math': 420,
    'English': 310,
    'Physics': 260,
    'History': 130,
    'IT': 120,
  };

  final List<StudyTask> tasks = [
    StudyTask('Solve 10 algebra problems', 'Math'),
    StudyTask('Read chapter 4', 'History'),
    StudyTask('Learn 20 new words', 'English', done: true),
  ];

  bool get onboarded => name.isNotEmpty;
  double get goalProgress =>
      (todayMinutes / dailyGoalMinutes).clamp(0.0, 1.0).toDouble();

  void finishOnboarding(String n, int goal) {
    name = n;
    dailyGoalMinutes = goal;
    notifyListeners();
  }

  void addTask(String title, String subject) {
    tasks.insert(0, StudyTask(title, subject));
    notifyListeners();
  }

  void toggleTask(StudyTask t) {
    t.done = !t.done;
    notifyListeners();
  }

  void removeTask(StudyTask t) {
    tasks.remove(t);
    notifyListeners();
  }

  void logSession(String subject, int minutes) {
    todayMinutes += minutes;
    weekMinutes += minutes;
    totalMinutes += minutes;
    sessionsToday += 1;
    minutesBySubject[subject] = (minutesBySubject[subject] ?? 0) + minutes;
    if (!goalMetToday && sessionsToday == 1) {
      streakDays += 1; // first finished session of the day keeps the streak
      if (streakDays > bestStreak) bestStreak = streakDays;
    }
    if (todayMinutes >= dailyGoalMinutes) goalMetToday = true;
    notifyListeners();
  }
}

/// Makes AppState available to the widget tree without extra packages.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
      : super(notifier: state);

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
}

// ---------------------------------------------------------------------------
// App shell
// ---------------------------------------------------------------------------

const seed = Color(0xFF5B5BD6);

class StudyBuddyApp extends StatefulWidget {
  const StudyBuddyApp({super.key});

  @override
  State<StudyBuddyApp> createState() => _StudyBuddyAppState();
}

class _StudyBuddyAppState extends State<StudyBuddyApp> {
  final AppState state = AppState();

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: MaterialApp(
        title: 'StudyBuddy',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: seed,
          useMaterial3: true,
          brightness: Brightness.light,
        ),
        darkTheme: ThemeData(
          colorSchemeSeed: seed,
          useMaterial3: true,
          brightness: Brightness.dark,
        ),
        home: const RootGate(),
      ),
    );
  }
}

class RootGate extends StatelessWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return s.onboarded ? const MainShell() : const OnboardingScreen();
  }
}

// ---------------------------------------------------------------------------
// Onboarding
// ---------------------------------------------------------------------------

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _name = TextEditingController();
  double _goal = 50;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              CircleAvatar(
                radius: 36,
                backgroundColor: cs.primaryContainer,
                child: Icon(Icons.school_rounded,
                    size: 40, color: cs.onPrimaryContainer),
              ),
              const SizedBox(height: 24),
              Text('StudyBuddy',
                  style: tt.displaySmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('Study a little every day.\nKeep your streak. Beat your friends.',
                  style: tt.titleMedium?.copyWith(color: cs.onSurfaceVariant)),
              const SizedBox(height: 32),
              TextField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Your name',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 24),
              Text('Daily focus goal: ${_goal.round()} min',
                  style: tt.titleMedium),
              Slider(
                value: _goal,
                min: 25,
                max: 180,
                divisions: 31,
                label: '${_goal.round()} min',
                onChanged: (v) => setState(() => _goal = v),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16)),
                  onPressed: _name.text.trim().isEmpty
                      ? null
                      : () => AppScope.of(context)
                          .finishOnboarding(_name.text.trim(), _goal.round()),
                  child: const Text("Let's start"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Main shell with bottom navigation
// ---------------------------------------------------------------------------

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  void goTo(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(onStartFocus: () => goTo(1)),
      const FocusScreen(),
      const LeaderboardScreen(),
      const ProfileScreen(),
    ];
    return Scaffold(
      body: SafeArea(child: IndexedStack(index: _index, children: pages)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: goTo,
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.timer_outlined),
              selectedIcon: Icon(Icons.timer),
              label: 'Focus'),
          NavigationDestination(
              icon: Icon(Icons.leaderboard_outlined),
              selectedIcon: Icon(Icons.leaderboard),
              label: 'Friends'),
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile'),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Home
// ---------------------------------------------------------------------------

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onStartFocus});
  final VoidCallback onStartFocus;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final openTasks = s.tasks.where((t) => !t.done).length;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTask(context),
        icon: const Icon(Icons.add),
        label: const Text('Task'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          Text('Hi, ${s.name} 👋', style: tt.headlineSmall),
          const SizedBox(height: 4),
          Text('$openTasks tasks left today',
              style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.local_fire_department,
                  iconColor: Colors.deepOrange,
                  value: '${s.streakDays}',
                  label: 'day streak',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.timer,
                  iconColor: cs.primary,
                  value: '${s.todayMinutes}',
                  label: 'min today',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            color: cs.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Daily goal',
                      style: tt.titleMedium
                          ?.copyWith(color: cs.onPrimaryContainer)),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: s.goalProgress,
                      minHeight: 10,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('${s.todayMinutes} / ${s.dailyGoalMinutes} min',
                      style: tt.bodyMedium
                          ?.copyWith(color: cs.onPrimaryContainer)),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: onStartFocus,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start focus session'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Tasks', style: tt.titleLarge),
          const SizedBox(height: 8),
          if (s.tasks.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                  child: Text('No tasks yet — add one with the + button',
                      style: tt.bodyMedium)),
            ),
          for (final t in s.tasks)
            Dismissible(
              key: ObjectKey(t),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                color: cs.errorContainer,
                child: Icon(Icons.delete, color: cs.onErrorContainer),
              ),
              onDismissed: (_) => s.removeTask(t),
              child: Card(
                elevation: 0,
                color: cs.surfaceContainerHighest,
                child: CheckboxListTile(
                  value: t.done,
                  onChanged: (_) => s.toggleTask(t),
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(
                    t.title,
                    style: TextStyle(
                      decoration: t.done ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  subtitle: Text(t.subject),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showAddTask(BuildContext context) {
    final s = AppScope.of(context);
    final controller = TextEditingController();
    String subject = s.subjects.first;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: StatefulBuilder(
          builder: (ctx, setSheet) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('New task', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'What do you need to do?',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: subject,
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final sub in s.subjects)
                    DropdownMenuItem(value: sub, child: Text(sub)),
                ],
                onChanged: (v) => setSheet(() => subject = v ?? subject),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  if (controller.text.trim().isEmpty) return;
                  s.addTask(controller.text.trim(), subject);
                  Navigator.pop(ctx);
                },
                child: const Text('Add task'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Card(
      elevation: 0,
      color: cs.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 32),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: tt.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                Text(label,
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Focus timer
// ---------------------------------------------------------------------------

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  static const focusMinutes = 25;
  static const breakMinutes = 5;

  Timer? _timer;
  bool _onBreak = false;
  bool _demoSpeed = false; // 1 second = 1 minute, handy for demos
  int _secondsLeft = focusMinutes * 60;
  String _subject = 'Math';

  int get _total => (_onBreak ? breakMinutes : focusMinutes) * 60;
  bool get _running => _timer != null;

  void _start() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    setState(() {});
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _timer = null);
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _timer = null;
      _onBreak = false;
      _secondsLeft = focusMinutes * 60;
    });
  }

  void _tick() {
    if (!mounted) return;
    setState(() {
      _secondsLeft -= _demoSpeed ? 60 : 1;
      if (_secondsLeft < 0) _secondsLeft = 0;
    });
    if (_secondsLeft > 0) return;

    _timer?.cancel();
    _timer = null;
    if (!_onBreak) {
      AppScope.of(context).logSession(_subject, focusMinutes);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Great job! +$focusMinutes min of $_subject. Take a break.'),
      ));
      setState(() {
        _onBreak = true;
        _secondsLeft = breakMinutes * 60;
      });
    } else {
      setState(() {
        _onBreak = false;
        _secondsLeft = focusMinutes * 60;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final mm = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final ss = (_secondsLeft % 60).toString().padLeft(2, '0');
    final ringColor = _onBreak ? Colors.teal : cs.primary;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(_onBreak ? 'Break time' : 'Focus', style: tt.headlineSmall),
        const SizedBox(height: 4),
        Text(
          _onBreak
              ? 'Stretch, drink water, look away from the screen.'
              : 'Pick a subject and stay with it for $focusMinutes minutes.',
          style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final sub in s.subjects)
              ChoiceChip(
                label: Text(sub),
                selected: _subject == sub,
                onSelected: _running || _onBreak
                    ? null
                    : (_) => setState(() => _subject = sub),
              ),
          ],
        ),
        const SizedBox(height: 32),
        Center(
          child: SizedBox(
            width: 240,
            height: 240,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: 1 - _secondsLeft / _total,
                  strokeWidth: 12,
                  color: ringColor,
                  backgroundColor: cs.surfaceContainerHighest,
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$mm:$ss',
                          style: tt.displayMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      Text(_onBreak ? 'break' : _subject,
                          style: tt.titleMedium
                              ?.copyWith(color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: _reset,
              icon: const Icon(Icons.restart_alt),
              label: const Text('Reset'),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 16)),
              onPressed: _running ? _pause : _start,
              icon: Icon(_running ? Icons.pause : Icons.play_arrow),
              label: Text(_running ? 'Pause' : 'Start'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SwitchListTile(
          value: _demoSpeed,
          onChanged: (v) => setState(() => _demoSpeed = v),
          title: const Text('Demo speed'),
          subtitle: const Text('1 second = 1 minute (for presentations)'),
        ),
        ListTile(
          leading: const Icon(Icons.check_circle_outline),
          title: Text('${s.sessionsToday} sessions completed today'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Leaderboard
// ---------------------------------------------------------------------------

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final entries = <MapEntry<String, int>>[
      const MapEntry('Aziza', 265),
      const MapEntry('Timur', 210),
      const MapEntry('Madina', 150),
      const MapEntry('Javohir', 95),
      MapEntry('${s.name} (you)', s.weekMinutes),
    ]..sort((a, b) => b.value.compareTo(a.value));
    final top = entries.first.value;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('This week', style: tt.headlineSmall),
        const SizedBox(height: 4),
        Text('Focus minutes among friends',
            style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 20),
        for (var i = 0; i < entries.length; i++)
          Card(
            elevation: 0,
            color: entries[i].key.endsWith('(you)')
                ? cs.primaryContainer
                : cs.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  SizedBox(
                    width: 32,
                    child: Text(
                      i < 3 ? ['🥇', '🥈', '🥉'][i] : '${i + 1}',
                      style: tt.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entries[i].key, style: tt.titleMedium),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: entries[i].value / top,
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('${entries[i].value} min', style: tt.titleSmall),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Your friend code: SB-4821')),
          ),
          icon: const Icon(Icons.person_add_alt),
          label: const Text('Invite a friend'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Profile
// ---------------------------------------------------------------------------

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final maxSubject =
        s.minutesBySubject.values.fold<int>(1, (a, b) => a > b ? a : b);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Center(
          child: CircleAvatar(
            radius: 40,
            backgroundColor: cs.primaryContainer,
            child: Text(
              s.name.isEmpty ? '?' : s.name[0].toUpperCase(),
              style: tt.headlineMedium?.copyWith(color: cs.onPrimaryContainer),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(child: Text(s.name, style: tt.headlineSmall)),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.emoji_events,
                iconColor: Colors.amber,
                value: '${s.bestStreak}',
                label: 'best streak',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.hourglass_bottom,
                iconColor: cs.primary,
                value: '${(s.totalMinutes / 60).toStringAsFixed(1)} h',
                label: 'total focus',
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Minutes by subject', style: tt.titleLarge),
        const SizedBox(height: 12),
        for (final e in s.minutesBySubject.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                SizedBox(width: 72, child: Text(e.key)),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: e.value / maxSubject,
                      minHeight: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                    width: 64,
                    child: Text('${e.value} min', textAlign: TextAlign.end)),
              ],
            ),
          ),
        const SizedBox(height: 12),
        ListTile(
          leading: const Icon(Icons.flag_outlined),
          title: const Text('Daily goal'),
          trailing: Text('${s.dailyGoalMinutes} min'),
        ),
      ],
    );
  }
}
