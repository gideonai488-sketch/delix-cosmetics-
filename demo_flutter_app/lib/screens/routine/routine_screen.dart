import 'package:flutter/material.dart';
import '../../services/ai_routine_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';

class RoutineScreen extends StatefulWidget {
  const RoutineScreen({super.key});

  @override
  State<RoutineScreen> createState() => _RoutineScreenState();
}

class _RoutineScreenState extends State<RoutineScreen> {
  int _selectedSkinType = 2;
  int _selectedRoutineTab = 0;
  int _selectedConcern = 0;
  int _selectedGoal = 0;
  int _selectedRoutineDepth = 1;
  bool _isGeneratingAi = false;
  bool _reminderEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 21, minute: 0);
  List<_RoutineStep> _generatedMorningSteps = [];
  List<_RoutineStep> _generatedEveningSteps = [];
  final Set<String> _completedSteps = {
    'Morning-1',
    'Morning-2',
    'Evening-1',
  };

  @override
  Widget build(BuildContext context) {
    final hasGenerated = _generatedMorningSteps.isNotEmpty && _generatedEveningSteps.isNotEmpty;
    final activeSteps = _selectedRoutineTab == 0
        ? (hasGenerated ? _generatedMorningSteps : _morningSteps)
        : (hasGenerated ? _generatedEveningSteps : _eveningSteps);
    final completedForActive = _completedSteps
        .where((key) => key.startsWith(_selectedRoutineTab == 0 ? 'Morning' : 'Evening'))
        .length;
    final completionRate = completedForActive / activeSteps.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Routine Studio'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.muted,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.tune, size: 19, color: AppColors.foreground),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildPremiumHero(context, completionRate),
          const SizedBox(height: 16),
          _buildRoutineOverview(context, completionRate),
          const SizedBox(height: 20),
          _buildSkinTypeSection(context),
          const SizedBox(height: 20),
          _buildAiGeneratorSection(context),
          const SizedBox(height: 20),
          _buildRoutineSwitcher(context),
          const SizedBox(height: 14),
          _buildRoutineSteps(context, hasGenerated),
          const SizedBox(height: 16),
          _buildAdvancedCareSection(context),
          const SizedBox(height: 16),
          _buildTipsCard(context),
          const SizedBox(height: 16),
          _buildReminderCard(context),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildPremiumHero(BuildContext context, double completionRate) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.crimsonDark, AppColors.crimsonLight, AppColors.gold],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.58, 1.0],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.crimson.withValues(alpha: 0.26),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.local_fire_department, size: 14, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      '5 Day Streak',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                '${(completionRate * 100).round()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Skin Ritual Planner',
            style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Curated steps, active ingredients, and timing guidance for a polished glow every day.',
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: completionRate,
            minHeight: 8,
            borderRadius: BorderRadius.circular(12),
            backgroundColor: Colors.white.withValues(alpha: 0.25),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutineOverview(BuildContext context, double completionRate) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Completed',
            value: '${(completionRate * 10).round()}/10',
            icon: Icons.check_circle,
            color: AppColors.crimson,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: const _StatCard(
            label: 'Hydration',
            value: '92%',
            icon: Icons.water_drop,
            color: AppColors.gold,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: const _StatCard(
            label: 'UV Index',
            value: 'High',
            icon: Icons.wb_sunny,
            color: Color(0xFF7F8CFF),
          ),
        ),
      ],
    );
  }

  Widget _buildSkinTypeSection(BuildContext context) {
    final types = ['Oily', 'Dry', 'Combination', 'Sensitive', 'Normal'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your Skin Type',
            style: Theme.of(context)
                .textTheme
                .titleLarge!
                .copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: types
              .asMap()
              .entries
              .map(
                (entry) => _SkinTypeChip(
                  label: entry.value,
                  selected: _selectedSkinType == entry.key,
                  onTap: () => setState(() => _selectedSkinType = entry.key),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildAiGeneratorSection(BuildContext context) {
    const concerns = [
      'Acne / Breakouts',
      'Dryness',
      'Dark Spots',
      'Fine Lines',
      'Sensitivity',
    ];
    const goals = [
      'Clear Skin',
      'Glass Glow',
      'Hydration Focus',
      'Anti-Aging',
    ];
    const routineDepth = ['Quick', 'Balanced', 'Advanced'];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Text(
                  'AI Powered Routine',
                  style: TextStyle(
                    color: AppColors.crimson,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildOptionChips(
            title: 'Main concern',
            options: concerns,
            selected: _selectedConcern,
            onSelected: (index) => setState(() => _selectedConcern = index),
          ),
          const SizedBox(height: 10),
          _buildOptionChips(
            title: 'Primary goal',
            options: goals,
            selected: _selectedGoal,
            onSelected: (index) => setState(() => _selectedGoal = index),
          ),
          const SizedBox(height: 10),
          _buildOptionChips(
            title: 'Routine depth',
            options: routineDepth,
            selected: _selectedRoutineDepth,
            onSelected: (index) => setState(() => _selectedRoutineDepth = index),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isGeneratingAi ? null : _generateAiRoutine,
              icon: _isGeneratingAi
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(
                _isGeneratingAi ? 'Generating...' : 'Generate AI Routine',
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AiRoutineService.isConfigured
                ? 'Connected to live AI generation.'
                : 'No AI key set, using smart offline fallback.',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.mutedForeground,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionChips({
    required String title,
    required List<String> options,
    required int selected,
    required ValueChanged<int> onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.mutedForeground,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.asMap().entries.map((entry) {
            final isSelected = entry.key == selected;
            return GestureDetector(
              onTap: () => onSelected(entry.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.crimson : AppColors.muted,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  entry.value,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.foreground,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRoutineSwitcher(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.muted,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _buildRoutineTab('Morning', 0, Icons.wb_sunny_outlined),
          _buildRoutineTab('Evening', 1, Icons.nightlight_round),
        ],
      ),
    );
  }

  Widget _buildRoutineTab(String label, int index, IconData icon) {
    final selected = _selectedRoutineTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRoutineTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.card : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? AppColors.crimson : AppColors.mutedForeground,
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? AppColors.crimson : AppColors.mutedForeground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoutineSteps(BuildContext context, bool hasGenerated) {
    final isMorning = _selectedRoutineTab == 0;
    final title = isMorning ? 'Morning Precision Layering' : 'Night Repair Sequence';
    final steps = isMorning
        ? (hasGenerated ? _generatedMorningSteps : _morningSteps)
        : (hasGenerated ? _generatedEveningSteps : _eveningSteps);
    final accentColor = isMorning ? AppColors.gold : AppColors.crimson;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(title,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge!
                          .copyWith(fontWeight: FontWeight.bold)),
                ),
                if (hasGenerated)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Text(
                      'AI',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.crimson,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          ...steps.asMap().entries.map((entry) {
            final key = '${isMorning ? 'Morning' : 'Evening'}-${entry.key + 1}';
            return _RoutineStepTile(
              step: entry.value,
              index: entry.key + 1,
              accentColor: accentColor,
              isLast: entry.key == steps.length - 1,
              completed: _completedSteps.contains(key),
              onToggleCompleted: () {
                setState(() {
                  if (_completedSteps.contains(key)) {
                    _completedSteps.remove(key);
                  } else {
                    _completedSteps.add(key);
                  }
                });
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAdvancedCareSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Advanced Add-ons',
          style: Theme.of(context).textTheme.titleLarge!.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 140,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: const [
              _AdvancedCareCard(
                title: 'LED Therapy',
                subtitle: '10 min collagen boost',
                icon: Icons.light_mode,
                tone: Color(0xFFFFF1D6),
              ),
              SizedBox(width: 10),
              _AdvancedCareCard(
                title: 'Ice Sculpt',
                subtitle: 'Depuff + tighten',
                icon: Icons.ac_unit,
                tone: Color(0xFFE9F4FF),
              ),
              SizedBox(width: 10),
              _AdvancedCareCard(
                title: 'Overnight Mask',
                subtitle: 'Barrier recovery',
                icon: Icons.night_shelter,
                tone: Color(0xFFFBE8F0),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTipsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('💡', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text('Pro Tips',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge!
                      .copyWith(color: AppColors.crimson, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          ..._tips.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 5, right: 8),
                      child: Icon(Icons.circle, size: 5, color: AppColors.crimson),
                    ),
                    Expanded(
                      child: Text(t,
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.foreground, height: 1.5)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildReminderCard(BuildContext context) {
    final timeText = _reminderTime.format(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notifications_active_outlined,
                  color: AppColors.crimson),
              const SizedBox(width: 8),
              Text(
                'Daily Routine Reminder',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge!
                    .copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Switch(
                value: _reminderEnabled,
                onChanged: (value) async {
                  final messenger = ScaffoldMessenger.of(context);
                  setState(() => _reminderEnabled = value);
                  if (value) {
                    await NotificationService.scheduleDailyRoutineReminder(
                      time: _reminderTime,
                      title: 'Delix Routine Time',
                      body: 'Your personalized skincare ritual is waiting.',
                    );
                  } else {
                    await NotificationService.cancelDailyRoutineReminder();
                  }
                  if (!mounted) return;
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        value
                            ? 'Daily reminder enabled for $timeText.'
                            : 'Daily reminder disabled.',
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Time: $timeText',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.foreground,
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final selected = await showTimePicker(
                    context: context,
                    initialTime: _reminderTime,
                  );
                  if (!mounted) return;
                  if (selected == null) return;
                  final selectedLabel = _formatTime(selected);
                  setState(() => _reminderTime = selected);
                  if (_reminderEnabled) {
                    await NotificationService.scheduleDailyRoutineReminder(
                      time: selected,
                      title: 'Delix Routine Time',
                      body: 'Routine reminder at $selectedLabel.',
                    );
                  }
                },
                icon: const Icon(Icons.schedule, size: 16),
                label: const Text('Change Time'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _generateAiRoutine() async {
    const skinTypes = ['Oily', 'Dry', 'Combination', 'Sensitive', 'Normal'];
    const concerns = [
      'Acne / Breakouts',
      'Dryness',
      'Dark Spots',
      'Fine Lines',
      'Sensitivity',
    ];
    const goals = [
      'Clear Skin',
      'Glass Glow',
      'Hydration Focus',
      'Anti-Aging',
    ];
    const depth = ['Quick', 'Balanced', 'Advanced'];

    final skin = skinTypes[_selectedSkinType];
    final concern = concerns[_selectedConcern];
    final goal = goals[_selectedGoal];
    final routineDepth = depth[_selectedRoutineDepth];

    setState(() => _isGeneratingAi = true);

    AiRoutinePlan? plan;
    try {
      plan = await AiRoutineService.generateRoutine(
        skinType: skin,
        concern: concern,
        goal: goal,
        routineDepth: routineDepth,
      );
    } catch (_) {
      plan = null;
    }

    if (!mounted) return;

    final morning = <_RoutineStep>[
      _RoutineStep('Gentle Cleanser', 'Use a $skin-friendly cleanser to prep the skin.', '🧼', 'skincare'),
      _RoutineStep('Target Serum', 'Focus on $concern with an active treatment serum.', '🧪', 'skincare'),
      _RoutineStep('Moisturizer', 'Lock hydration and barrier support before SPF.', '💧', 'skincare'),
      _RoutineStep('Sunscreen SPF 50', 'Protect progress and prevent rebound concerns.', '☀️'),
    ];

    final evening = <_RoutineStep>[
      _RoutineStep('Double Cleanse', 'Remove sunscreen and impurities gently.', '🫧', 'skincare'),
      _RoutineStep('Repair Treatment', 'Apply PM actives aligned to $goal.', '🌙', 'skincare'),
      _RoutineStep('Barrier Cream', 'Seal actives and prevent overnight water loss.', '🛡️', 'skincare'),
    ];

    if (routineDepth != 'Quick') {
      morning.insert(
        2,
        _RoutineStep('Essence / Toner', 'Boost absorption and soothe pre-moisturizer.', '✨', 'skincare'),
      );
      evening.insert(
        2,
        _RoutineStep('Eye + Neck Care', 'Support delicate zones with peptides.', '👁️', 'skincare'),
      );
    }

    if (routineDepth == 'Advanced') {
      morning.add(
        _RoutineStep('Glow Primer', 'Optional prep for makeup and smooth finish.', '💄', 'makeup'),
      );
      evening.add(
        _RoutineStep('Overnight Mask', 'Intensive recovery boost 2-3 nights weekly.', '🛌', 'skincare'),
      );
    }

    final generatedMorning = plan?.morning
            .map((step) => _RoutineStep(step, 'AI tailored step for your profile.', '✨', 'skincare'))
            .toList() ??
        morning;

    final generatedEvening = plan?.evening
            .map((step) => _RoutineStep(step, 'AI tailored step for your profile.', '🌙', 'skincare'))
            .toList() ??
        evening;

    setState(() {
      _generatedMorningSteps = generatedMorning;
      _generatedEveningSteps = generatedEvening;
      _isGeneratingAi = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          plan == null
              ? 'Generated with offline smart engine for $skin skin.'
              : 'Live AI routine generated for $skin skin with $goal focus.',
        ),
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    final isPm = time.hour >= 12;
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${isPm ? 'PM' : 'AM'}';
  }
}

class _SkinTypeChip extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  final String label;
  const _SkinTypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.crimson : AppColors.muted,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: selected ? Colors.transparent : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.foreground,
          ),
        ),
      ),
    );
  }
}

class _RoutineStep {
  final String step;
  final String description;
  final String emoji;
  final String? productCategory;

  const _RoutineStep(this.step, this.description, this.emoji,
      [this.productCategory]);
}

class _RoutineStepTile extends StatelessWidget {
  final _RoutineStep step;
  final int index;
  final Color accentColor;
  final bool isLast;
  final bool completed;
  final VoidCallback onToggleCompleted;

  const _RoutineStepTile({
    required this.step,
    required this.index,
    required this.accentColor,
    required this.isLast,
    required this.completed,
    required this.onToggleCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$index',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: accentColor),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(step.emoji),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            step.step,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              decoration:
                                  completed ? TextDecoration.lineThrough : null,
                              color: completed
                                  ? AppColors.mutedForeground
                                  : AppColors.foreground,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: onToggleCompleted,
                          child: Icon(
                            completed
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            size: 20,
                            color: completed
                                ? accentColor
                                : AppColors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(step.description,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.mutedForeground,
                            height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
          if (!isLast) ...[
            const SizedBox(height: 12),
            const Divider(color: AppColors.border, height: 1),
          ] else
            const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.mutedForeground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdvancedCareCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color tone;

  const _AdvancedCareCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tone,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 16, color: AppColors.foreground),
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.mutedForeground,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

const _morningSteps = [
  _RoutineStep('Cleanser', 'Gently cleanse with a mild, sulfate-free cleanser.', '🧼', 'skincare'),
  _RoutineStep('Vitamin C Serum', 'Apply 3-4 drops to brighten and protect against UV damage.', '🍋', 'skincare'),
  _RoutineStep('Moisturizer', 'Lock in hydration with a lightweight moisturizer.', '💧', 'skincare'),
  _RoutineStep('SPF 30+', 'Never skip sunscreen — your skin will thank you!', '☀️'),
  _RoutineStep('Makeup', 'Apply foundation, concealer, or tinted moisturizer as desired.', '💄', 'makeup'),
];

const _eveningSteps = [
  _RoutineStep('Makeup Remover', 'Double cleanse to remove all traces of makeup and SPF.', '🧹', 'skincare'),
  _RoutineStep('Exfoliate (2x/week)', 'Use a gentle chemical exfoliant to remove dead skin cells.', '✨'),
  _RoutineStep('Treatment Serum', 'Apply retinol, niacinamide, or targeted serum.', '🔬', 'skincare'),
  _RoutineStep('Eye Cream', 'Pat gently around the eye area to prevent fine lines.', '👁️', 'skincare'),
  _RoutineStep('Night Moisturizer / Mask', 'Seal with a rich night cream or overnight hydrating mask.', '🌙', 'skincare'),
];

const _tips = [
  'Apply products thinnest to thickest consistency.',
  'Always apply to slightly damp skin for better absorption.',
  'Drink at least 8 glasses of water daily for inner glow.',
  'Get 7-8 hours of sleep — it\'s the best anti-aging treatment!',
  'Patch test new products before adding to your full routine.',
];
