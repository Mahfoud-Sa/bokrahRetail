import 'package:bokrah_design_system/bokrah_design_system.dart';
import 'package:flutter/material.dart';
import '../../data/models/working_day_model.dart';
import '../../data/services/working_days_service.dart';

class _DayScheduleState {
  final int day;
  bool isWorking;
  TimeOfDay from;
  TimeOfDay to;
  int? id;

  _DayScheduleState({
    required this.day,
    this.isWorking = false,
    this.from = const TimeOfDay(hour: 8, minute: 0),
    this.to = const TimeOfDay(hour: 17, minute: 0),
    this.id,
  });

  String get dayName {
    switch (day) {
      case 0:
        return 'الأحد';
      case 1:
        return 'الاثنين';
      case 2:
        return 'الثلاثاء';
      case 3:
        return 'الأربعاء';
      case 4:
        return 'الخميس';
      case 5:
        return 'الجمعة';
      case 6:
        return 'السبت';
      default:
        return 'يوم $day';
    }
  }

  double get durationHours {
    final fromMinutes = from.hour * 60 + from.minute;
    final toMinutes = to.hour * 60 + to.minute;
    var diff = toMinutes - fromMinutes;
    if (diff < 0) diff += 24 * 60; // Over midnight
    return diff / 60.0;
  }
}

class WorkingDaysSection extends StatefulWidget {
  final int userId;
  final WorkingDaysService workingDaysService;
  final bool isWide;

  const WorkingDaysSection({
    super.key,
    required this.userId,
    required this.workingDaysService,
    this.isWide = true,
  });

  @override
  State<WorkingDaysSection> createState() => _WorkingDaysSectionState();
}

class _WorkingDaysSectionState extends State<WorkingDaysSection> {
  late List<_DayScheduleState> _schedules;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initDefaultSchedules();
    _loadWorkingDays();
  }

  @override
  void didUpdateWidget(covariant WorkingDaysSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _loadWorkingDays();
    }
  }

  void _initDefaultSchedules() {
    _schedules = List.generate(7, (i) {
      final isWeekday = i >= 0 && i <= 4; // Sunday to Thursday
      return _DayScheduleState(
        day: i,
        isWorking: isWeekday,
        from: const TimeOfDay(hour: 8, minute: 0),
        to: const TimeOfDay(hour: 17, minute: 0),
      );
    });
  }

  Future<void> _loadWorkingDays() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final days = await widget.workingDaysService.getWorkingDays(
        userId: widget.userId,
      );

      if (days.isNotEmpty) {
        // Reset all to not working first
        for (final s in _schedules) {
          s.isWorking = false;
          s.id = null;
        }

        for (final item in days) {
          if (item.day >= 0 && item.day < 7) {
            final s = _schedules[item.day];
            s.isWorking = true;
            s.id = item.id;
            s.from = item.fromTimeOfDay;
            s.to = item.toTimeOfDay;
          }
        }
      }
    } catch (e) {
      _errorMessage = 'تعذر تحميل مواعيد العمل من الخادم';
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveWorkingDays() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final activeDays = _schedules
          .where((s) => s.isWorking)
          .map((s) => WorkingDayModel(
                id: s.id,
                userId: widget.userId,
                day: s.day,
                fromTime: WorkingDayModel.formatForApi(s.from),
                toTime: WorkingDayModel.formatForApi(s.to),
              ))
          .toList();

      await widget.workingDaysService.saveWorkingDaysForUser(
        userId: widget.userId,
        days: activeDays,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ وتحديث مواعيد العمل بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل حفظ مواعيد العمل: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _pickTime({
    required BuildContext context,
    required _DayScheduleState schedule,
    required bool isFrom,
  }) async {
    final initial = isFrom ? schedule.from : schedule.to;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: isFrom
          ? 'اختر وقت بدء العمل ليوم ${schedule.dayName}'
          : 'اختر وقت انتهاء العمل ليوم ${schedule.dayName}',
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        if (isFrom) {
          schedule.from = picked;
        } else {
          schedule.to = picked;
        }
      });
    }
  }

  void _applyHoursToAllActiveDays(_DayScheduleState template) {
    setState(() {
      for (final s in _schedules) {
        if (s.isWorking) {
          s.from = template.from;
          s.to = template.to;
        }
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تم تطبيق مواعيد يوم ${template.dayName} (${_formatTod(template.from)} - ${_formatTod(template.to)}) على كافة أيام العمل المحددة.',
        ),
      ),
    );
  }

  String _formatTod(TimeOfDay tod) {
    final hour = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
    final minute = tod.minute.toString().padLeft(2, '0');
    final period = tod.period == DayPeriod.am ? 'ص' : 'م';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _schedules.where((s) => s.isWorking).length;
    final totalHours = _schedules
        .where((s) => s.isWorking)
        .fold<double>(0.0, (acc, s) => acc + s.durationHours);

    return BkCard(
      child: Padding(
        padding: EdgeInsets.all(widget.isWide ? 24 : 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'أيام ومواعيد العمل (Working Days)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                BkBadge(
                  label: '$activeCount أيام / ${totalHours.toStringAsFixed(totalHours.truncateToDouble() == totalHours ? 0 : 1)} ساعة أسبوعياً',
                  tone: activeCount > 0 ? BkTone.info : BkTone.neutral,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'حدد أيام دوامك الأسبوعية وساعات بدء ونهاية الوردية لكل يوم عمل.',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const Divider(height: 24),

            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(BkRadius.sm),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(24.0),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              // Days List
              ..._schedules.map((schedule) {
                final isWork = schedule.isWorking;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isWork
                        ? Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
                        : Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(BkRadius.md),
                    border: Border.all(
                      color: isWork
                          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.25)
                          : Theme.of(context).dividerColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Day Switch & Name
                      Switch(
                        value: isWork,
                        onChanged: (val) {
                          setState(() => schedule.isWorking = val);
                        },
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 75,
                        child: Text(
                          schedule.dayName,
                          style: TextStyle(
                            fontWeight: isWork ? FontWeight.bold : FontWeight.normal,
                            fontSize: 14,
                            color: isWork
                                ? Theme.of(context).colorScheme.onSurface
                                : Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      if (isWork) ...[
                        // From Time Button
                        Expanded(
                          child: InkWell(
                            onTap: () => _pickTime(
                              context: context,
                              schedule: schedule,
                              isFrom: true,
                            ),
                            borderRadius: BorderRadius.circular(BkRadius.sm),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                border: Border.all(
                                  color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
                                ),
                                borderRadius: BorderRadius.circular(BkRadius.sm),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.login_rounded,
                                    size: 14,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'من: ${_formatTod(schedule.from)}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // To Time Button
                        Expanded(
                          child: InkWell(
                            onTap: () => _pickTime(
                              context: context,
                              schedule: schedule,
                              isFrom: false,
                            ),
                            borderRadius: BorderRadius.circular(BkRadius.sm),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                border: Border.all(
                                  color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
                                ),
                                borderRadius: BorderRadius.circular(BkRadius.sm),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.logout_rounded,
                                    size: 14,
                                    color: Theme.of(context).colorScheme.secondary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'إلى: ${_formatTod(schedule.to)}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Duration Badge
                        BkBadge(
                          label: '${schedule.durationHours.toStringAsFixed(schedule.durationHours.truncateToDouble() == schedule.durationHours ? 0 : 1)} س',
                          tone: BkTone.info,
                        ),

                        // Copy hours popup menu
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, size: 18),
                          tooltip: 'خيارات المواعيد',
                          onSelected: (val) {
                            if (val == 'apply_all') {
                              _applyHoursToAllActiveDays(schedule);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'apply_all',
                              child: Row(
                                children: [
                                  Icon(Icons.copy_rounded, size: 16),
                                  SizedBox(width: 8),
                                  Text(
                                    'تطبيق نفس المواعيد على باقي الأيام',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        // Off day badge
                        const Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: BkBadge(
                              label: 'إجازة أسبوعية / غير متاح',
                              tone: BkTone.neutral,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),

              const SizedBox(height: 16),

              // Save Button
              Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveWorkingDays,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_outlined, size: 18),
                    label: Text(
                      _isSaving ? 'جاري الحفظ...' : 'حفظ مواعيد وأيام العمل',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(BkRadius.md),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
