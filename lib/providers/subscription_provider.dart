import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import '../models/subscription.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../services/currency_service.dart';
import '../services/ad_service.dart';
import '../services/activity_tracker.dart';
import '../providers/settings_provider.dart';

class SubscriptionState {
  final List<Subscription> subscriptions;
  final Map<String, double> rates;
  final bool isLoading;

  SubscriptionState({
    required this.subscriptions,
    required this.rates,
    required this.isLoading,
  });

  SubscriptionState copyWith({
    List<Subscription>? subscriptions,
    Map<String, double>? rates,
    bool? isLoading,
  }) {
    return SubscriptionState(
      subscriptions: subscriptions ?? this.subscriptions,
      rates: rates ?? this.rates,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class SubscriptionNotifier extends Notifier<SubscriptionState> {
  @override
  SubscriptionState build() {
    Future.microtask(() => init());
    return SubscriptionState(
      subscriptions: [],
      rates: {'TRY': 1.0, 'USD': 32.5},
      isLoading: true,
    );
  }

  Future<void> fetchSubscriptions() async {
    state = state.copyWith(isLoading: true);
    final subs = await DBService.instance.getAllSubscriptions();
    state = state.copyWith(
      subscriptions: subs,
      isLoading: false,
    );
    _updateHomeWidget();
  }

  void _updateHomeWidget() {
    try {
      final total = totalThisMonth;
      HomeWidget.saveWidgetData<String>('monthly_total', total.toStringAsFixed(0));
      HomeWidget.updateWidget(name: 'WidgetProvider');
    } catch (_) {}
  }

  Future<void> init() async {
    state = state.copyWith(isLoading: true);

    final subs = await DBService.instance.getAllSubscriptions();
    final rates = await DBService.instance.getRates();

    state = state.copyWith(
      subscriptions: subs,
      rates: rates,
      isLoading: false,
    );

    _updateHomeWidget();
    fetchFreshRates();
  }

  Future<void> fetchFreshRates() async {
    final rate = await CurrencyService.getUSDToTRYRate();
    state = state.copyWith(rates: {'TRY': 1.0, 'USD': rate});
  }

  Future<void> addSubscription(Subscription sub) async {
    final id = await DBService.instance.insertSubscription(sub);
    final insertedSub = sub.copyWith(id: id);

    state = state.copyWith(
      subscriptions: [...state.subscriptions, insertedSub],
    );

    await NotificationService.scheduleReminder(id: insertedSub.id!, name: insertedSub.name, amount: insertedSub.price, currency: insertedSub.currency, renewalDate: insertedSub.nextRenewalDate, daysBefore: insertedSub.notifyDaysBefore);
    AdService.onSubscriptionAdded(ref.read(isPremiumProvider));
  }

  Future<void> updateSubscription(Subscription sub, {bool updateAllWithName = false}) async {
    if (updateAllWithName) {
      final allSubs = await DBService.instance.getAllSubscriptions();
      final updatedSubs = <Subscription>[];
      
      for (var s in allSubs) {
        if (s.name == sub.name) {
          final updatedS = s.copyWith(
            priceInTL: sub.priceInTL,
            isUsdBased: sub.isUsdBased,
            usdAmount: sub.usdAmount,
          );
          await DBService.instance.updateSubscription(updatedS);
          updatedSubs.add(updatedS);
          await NotificationService.scheduleReminder(id: updatedS.id!, name: updatedS.name, amount: updatedS.price, currency: updatedS.currency, renewalDate: updatedS.nextRenewalDate, daysBefore: updatedS.notifyDaysBefore);
        } else {
          updatedSubs.add(s);
        }
      }
      state = state.copyWith(subscriptions: updatedSubs);
    } else {
      await DBService.instance.updateSubscription(sub);
      final updatedSubs = state.subscriptions.map((s) {
        return s.id == sub.id ? sub : s;
      }).toList();
      state = state.copyWith(subscriptions: updatedSubs);
      await NotificationService.scheduleReminder(id: sub.id!, name: sub.name, amount: sub.price, currency: sub.currency, renewalDate: sub.nextRenewalDate, daysBefore: sub.notifyDaysBefore);
    }
    _updateHomeWidget();
  }

  Future<void> deleteSubscription(int id) async {
    final subToDelete = state.subscriptions.firstWhere((s) => s.id == id);
    await DBService.instance.deleteSubscription(id);

    final filteredSubs = state.subscriptions.where((s) => s.id != id).toList();

    state = state.copyWith(subscriptions: filteredSubs);

    await NotificationService.cancel(id);
    await ActivityTracker.logAction("Abonelik Silindi", "Kullanıcı '${subToDelete.name}' aboneliğini sildi.");
  }

  double convertToTRY(double price, String currency) {
    final rate = state.rates[currency] ?? 1.0;
    return price * rate;
  }

  double get totalThisMonth {
    double total = 0.0;
    for (var sub in state.subscriptions) {
      if (sub.isActive) {
        double subPriceTRY = convertToTRY(sub.price, sub.currency);
        double monthlyCost = subPriceTRY;
        
        switch (sub.billingCycle) {
          case 'Haftalık':
            monthlyCost = (subPriceTRY / 7) * 30;
            break;
          case '2 Haftada Bir':
            monthlyCost = (subPriceTRY / 14) * 30;
            break;
          case 'Aylık':
            monthlyCost = subPriceTRY;
            break;
          case '3 Aylık':
            monthlyCost = subPriceTRY / 3;
            break;
          case '6 Aylık':
            monthlyCost = subPriceTRY / 6;
            break;
          case 'Yıllık':
            monthlyCost = subPriceTRY / 12;
            break;
          case 'Özel':
            if (sub.cycleDays > 0) {
              monthlyCost = (subPriceTRY / sub.cycleDays) * 30;
            }
            break;
        }
        total += monthlyCost;
      }
    }
    return total;
  }

  double get totalThisYear {
    return totalThisMonth * 12.0;
  }

  Subscription? get nextUpcomingSubscription {
    if (state.subscriptions.isEmpty) return null;
    final now = DateTime.now();
    Subscription? nextSub;
    Duration? minDiff;

    for (var sub in state.subscriptions) {
      final nextDate = sub.nextRenewalDate;
      final diff = nextDate.difference(now);
      if (!diff.isNegative) {
        if (minDiff == null || diff < minDiff) {
          minDiff = diff;
          nextSub = sub;
        }
      }
    }
    return nextSub;
  }

  Subscription? get mostExpensiveSubscription {
    if (state.subscriptions.isEmpty) return null;
    Subscription? expensiveSub;
    double maxPrice = 0.0;

    for (var sub in state.subscriptions) {
      if (sub.priceInTL > maxPrice) {
        maxPrice = sub.priceInTL;
        expensiveSub = sub;
      }
    }
    return expensiveSub;
  }
}

final subscriptionProvider = NotifierProvider<SubscriptionNotifier, SubscriptionState>(() {
  return SubscriptionNotifier();
});
