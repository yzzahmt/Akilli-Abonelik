import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/subscription_provider.dart';
import '../providers/settings_provider.dart';
import '../constants/app_colors.dart';
import '../models/subscription.dart';
import '../utils/translations.dart';
import 'add_subscription_screen.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  List<Subscription> _getSubsForDay(DateTime day, List<Subscription> allSubs) {
    return allSubs.where((sub) {
      final nextDate = sub.nextRenewalDate;
      return nextDate.year == day.year &&
          nextDate.month == day.month &&
          nextDate.day == day.day;
    }).toList();
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'video':
        return AppColors.expensiveRed;
      case 'müzik':
        return AppColors.activeGreen;
      case 'ai':
      case 'yapay zeka':
        return AppColors.accentPurpleLight;
      case 'bulut':
        return AppColors.accentPurple;
      case 'oyun':
        return AppColors.warningAmber;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getEmojiForService(String name) {
    switch (name.toLowerCase()) {
      case 'netflix':
        return '🎬';
      case 'spotify':
        return '🎵';
      case 'youtube premium':
        return '▶️';
      case 'chatgpt':
        return '🤖';
      case 'icloud':
        return '☁️';
      default:
        return '➕';
    }
  }

  void _showDayBottomSheet(
    BuildContext context,
    DateTime day,
    List<Subscription> subs,
    String lang,
  ) {
    final dateFormat = DateFormat('dd MMMM yyyy', lang == 'TR' ? 'tr' : 'en');
    final notifier = ref.read(subscriptionProvider.notifier);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            border: Border(
              top: BorderSide(color: AppColors.borderMedium, width: 1.2),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppTranslations.translate(
                  lang,
                  'payments_on',
                ).replaceAll('{date}', dateFormat.format(day)),
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              if (subs.isEmpty)
                Text(
                  AppTranslations.translate(lang, 'no_payments_today'),
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: subs.length,
                    itemBuilder: (context, index) {
                      final sub = subs[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => AddSubscriptionScreen(
                                  subscriptionToEdit: sub,
                                ),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface1,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.borderSubtle,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      _getEmojiForService(sub.name),
                                      style: const TextStyle(fontSize: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          sub.name,
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          sub.category,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Text(
                                  '₺${notifier.convertToTRY(sub.price, sub.currency).toStringAsFixed(0)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final subState = ref.watch(subscriptionProvider);
    final notifier = ref.read(subscriptionProvider.notifier);

    final List<Subscription> sortedSubs = List.from(subState.subscriptions);
    sortedSubs.sort((a, b) => a.nextRenewalDate.compareTo(b.nextRenewalDate));

    final dateFormat = DateFormat('dd MMMM', lang == 'TR' ? 'tr' : 'en');
    final monthFormat = DateFormat('MMM', lang == 'TR' ? 'tr' : 'en');

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                AppTranslations.translate(lang, 'calendar'),
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ).animate().fade().slideX(),
              const SizedBox(height: 4),
              Text(
                AppTranslations.translate(lang, 'upcoming_payments'),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 18),

              // Table Calendar
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface1,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.borderSubtle, width: 1.2),
                ),
                child: TableCalendar(
                  firstDay: DateTime(2020),
                  lastDay: DateTime(2035),
                  focusedDay: _focusedDay,
                  locale: lang == 'TR' ? 'tr_TR' : 'en_US',
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                    final subs = _getSubsForDay(
                      selectedDay,
                      subState.subscriptions,
                    );
                    _showDayBottomSheet(context, selectedDay, subs, lang);
                  },
                  calendarFormat: CalendarFormat.month,
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  eventLoader: (day) =>
                      _getSubsForDay(day, subState.subscriptions),
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, day, events) {
                      if (events.isEmpty) return const SizedBox.shrink();
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: events.take(4).map((sub) {
                          return Container(
                            width: 5,
                            height: 5,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(
                              color: _getCategoryColor(
                                (sub as Subscription).category,
                              ),
                              shape: BoxShape.circle,
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  headerStyle: HeaderStyle(
                    titleCentered: true,
                    formatButtonVisible: false,
                    titleTextStyle: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    leftChevronIcon: const Icon(
                      Icons.chevron_left,
                      color: AppColors.textSecondary,
                    ),
                    rightChevronIcon: const Icon(
                      Icons.chevron_right,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  calendarStyle: CalendarStyle(
                    defaultTextStyle: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                    ),
                    weekendTextStyle: GoogleFonts.inter(
                      color: AppColors.expensiveRed,
                    ),
                    outsideTextStyle: GoogleFonts.inter(
                      color: AppColors.textMuted,
                    ),
                    selectedDecoration: const BoxDecoration(
                      color: AppColors.accentPurple,
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: AppColors.accentPurple.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.accentPurple,
                        width: 1,
                      ),
                    ),
                  ),
                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                    weekendStyle: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ).animate().fade(duration: 400.ms),

              const SizedBox(height: 20),

              Text(
                AppTranslations.translate(lang, 'this_month_calendar'),
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              if (sortedSubs.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      AppTranslations.translate(lang, 'no_payments'),
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: sortedSubs.length,
                    itemBuilder: (context, index) {
                      final sub = sortedSubs[index];
                      final nextDate = sub.nextRenewalDate;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => AddSubscriptionScreen(
                                  subscriptionToEdit: sub,
                                ),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface1,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.borderSubtle,
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.accentPurple.withValues(alpha: 
                                      0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        DateFormat('dd').format(nextDate),
                                        style: GoogleFonts.inter(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.accentPurple,
                                        ),
                                      ),
                                      Text(
                                        monthFormat
                                            .format(nextDate)
                                            .toUpperCase(),
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        sub.name,
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        dateFormat.format(nextDate),
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '₺${(sub.price * notifier.convertToTRY(1, sub.currency)).toStringAsFixed(0)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ).animate().fade(duration: 250.ms).slideY(begin: 0.1, end: 0.0),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
