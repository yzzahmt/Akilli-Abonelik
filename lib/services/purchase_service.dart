import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Google Play tek seferlik satın alma servisi
/// Ürün ID: substrack_premium
class PurchaseService {
  static const String _productId = 'substrack_premium';
  static const String _prefKey = 'is_permanent_premium';

  static final PurchaseService instance = PurchaseService._internal();
  PurchaseService._internal();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  // Dış dünyadan izlenebilir premium durumu
  final ValueNotifier<bool> isPremium = ValueNotifier(false);

  // Satın alma işlemi devam ediyor mu?
  final ValueNotifier<bool> isPurchasing = ValueNotifier(false);

  // Hata mesajı (null = hata yok)
  final ValueNotifier<String?> errorMessage = ValueNotifier(null);

  /// Servisi başlat — main.dart'ta çağrılmalı
  Future<void> init() async {
    // Yerel olarak kaydedilmiş premium durumunu yükle
    await _loadLocalPremium();

    // Google Play kullanılabilir mi kontrol et
    final available = await _iap.isAvailable();
    if (!available) {
      debugPrint('PurchaseService: Google Play Store kullanılamıyor');
      return;
    }

    // Satın alma akışını dinle
    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (error) {
        debugPrint('PurchaseService stream error: $error');
        isPurchasing.value = false;
        errorMessage.value = 'Bağlantı hatası oluştu.';
      },
    );

    // Tamamlanmamış önceki işlemleri temizle
    await _restorePendingPurchases();
  }

  /// Yerel premium durumunu yükle
  Future<void> _loadLocalPremium() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      isPremium.value = prefs.getBool(_prefKey) ?? false;
    } catch (_) {}
  }

  /// Premium durumunu kaydet
  Future<void> savePremium(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, value);
      isPremium.value = value;
    } catch (_) {}
  }

  /// Satın alma akışını dinle
  void _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.productID != _productId) continue;

      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          // Satın alma onaylandı → premium aktif et
          await savePremium(true);
          isPurchasing.value = false;
          errorMessage.value = null;
          // Google Play'e teslim onayı gönder
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          break;

        case PurchaseStatus.error:
          isPurchasing.value = false;
          final code = purchase.error?.code ?? '';
          if (code != 'userCancelled') {
            errorMessage.value = 'Satın alma başarısız: ${purchase.error?.message ?? 'Bilinmeyen hata'}';
          }
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          break;

        case PurchaseStatus.pending:
          // Bekliyor (örn. aile onayı)
          isPurchasing.value = true;
          break;

        case PurchaseStatus.canceled:
          isPurchasing.value = false;
          break;
      }
    }
  }

  /// Önceki tamamlanmamış satın almaları işle
  Future<void> _restorePendingPurchases() async {
    try {
      await _iap.restorePurchases();
    } catch (e) {
      debugPrint('PurchaseService restore error: $e');
    }
  }

  /// Premium satın al — kullanıcı "Satın Al" butonuna bastığında çağır
  Future<void> buyPremium() async {
    isPurchasing.value = true;
    errorMessage.value = null;

    try {
      // Ürün bilgisini al
      final ProductDetailsResponse response = await _iap.queryProductDetails({_productId});

      if (response.error != null) {
        isPurchasing.value = false;
        errorMessage.value = 'Ürün bilgisi alınamadı: ${response.error!.message}';
        return;
      }

      if (response.productDetails.isEmpty) {
        isPurchasing.value = false;
        errorMessage.value = 'Ürün bulunamadı. Lütfen Google Play\'in kullanılabilir olduğundan emin olun.';
        return;
      }

      final ProductDetails product = response.productDetails.first;
      final PurchaseParam param = PurchaseParam(productDetails: product);

      // Tek seferlik satın alma başlat
      await _iap.buyNonConsumable(purchaseParam: param);
    } catch (e) {
      isPurchasing.value = false;
      debugPrint('PurchaseService buyPremium error: $e');
      errorMessage.value = 'Satın alma başlatılamadı: $e';
    }
  }

  /// Önceki satın almaları geri yükle (kullanıcı yeni telefon aldıysa)
  Future<void> restorePurchases() async {
    isPurchasing.value = true;
    errorMessage.value = null;
    try {
      await _iap.restorePurchases();
      // Sonuç _onPurchaseUpdate'e gelir
    } catch (e) {
      isPurchasing.value = false;
      errorMessage.value = 'Geri yükleme başarısız: $e';
    }
  }

  /// Premium ürünün fiyatını getir (göstermek için)
  Future<String?> fetchPrice() async {
    try {
      final response = await _iap.queryProductDetails({_productId});
      if (response.productDetails.isNotEmpty) {
        return response.productDetails.first.price;
      }
    } catch (_) {}
    return null;
  }

  /// Servisi kapat
  void dispose() {
    _subscription?.cancel();
    isPremium.dispose();
    isPurchasing.dispose();
    errorMessage.dispose();
  }
}
