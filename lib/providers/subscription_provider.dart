import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import '../models/subscription.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../services/currency_service.dart';
import '../services/ad_service.dart';

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

    await NotificationService.instance.scheduleRenewalNotification(insertedSub);
    AdService.onSubscriptionAdded();
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
          await NotificationService.instance.scheduleRenewalNotification(updatedS);
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
      await NotificationService.instance.scheduleRenewalNotification(sub);
    }
    _updateHomeWidget();
  }

  Future<void> deleteSubscription(int id) async {
    await DBService.instance.deleteSubscription(id);

    final filteredSubs = state.subscriptions.where((s) => s.id != id).toList();

    state = state.copyWith(subscriptions: filteredSubs);

    await NotificationService.instance.cancelNotification(id);
  }

  double convertToTRY(double price, String currency) {
    final rate = state.rates[currency] ?? 1.0;
    return price * rate;
  }

  double get totalThisMonth {
    double total = 0.0;
    for (var sub in state.subscriptions) {
      if (sub.isActive) {
        total += convertToTRY(sub.price, sub.currency);
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
