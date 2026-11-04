import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config.dart';

/// The one subscription state for the whole app.
///
/// The truth lives in the Supabase `subscriptions` table, which RevenueCat's
/// webhook keeps up to date. The database also enforces the free limits, so a
/// stale phone can never get around them. RevenueCat is only the checkout.
class SubscriptionStore extends ChangeNotifier {
  bool active = false;

  /// 'free', 'premium' or 'admin' (set by hand in the database).
  String accountType = 'free';
  bool get isAdmin => accountType == 'admin';
  bool get hasGift => accountType == 'premium' || accountType == 'admin';
  bool busy = false;
  String? message;
  Package? monthly;
  Package? yearly;

  static bool _configured = false;

  /// False until a RevenueCat key is supplied (e.g. during early testing).
  bool get storeAvailable => AppConfig.revenueCatKey.isNotEmpty;

  SupabaseClient get _db => Supabase.instance.client;

  Future<void> init() async {
    await refresh();
    await _setupStore();
  }

  /// Reads the subscription row the server keeps for this runner.
  Future<void> refresh() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) {
      active = false;
      notifyListeners();
      return;
    }
    try {
      final row = await _db
          .from('subscriptions')
          .select('active, expires_at')
          .eq('user_id', uid)
          .maybeSingle();
      var on = false;
      if (row != null && row['active'] == true) {
        final raw = row['expires_at'] as String?;
        on = raw == null || DateTime.parse(raw).isAfter(DateTime.now());
      }
      final prof = await _db
          .from('profiles')
          .select('account_type')
          .eq('id', uid)
          .maybeSingle();
      accountType = (prof?['account_type'] as String?) ?? 'free';
      active = on || hasGift;
    } catch (_) {
      // Keep the last known state when offline.
    }
    notifyListeners();
  }

  Future<void> _setupStore() async {
    if (!storeAvailable) return;
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return;
    try {
      if (!_configured) {
        await Purchases.configure(
            PurchasesConfiguration(AppConfig.revenueCatKey)..appUserID = uid);
        _configured = true;
      } else {
        await Purchases.logIn(uid);
      }
      final offerings = await Purchases.getOfferings();
      monthly = offerings.current?.monthly;
      yearly = offerings.current?.annual;
    } catch (e) {
      message = 'The store is not available right now.';
    }
    notifyListeners();
  }

  Future<void> purchase(Package? package) async {
    if (package == null) return;
    busy = true;
    message = null;
    notifyListeners();
    try {
      await Purchases.purchasePackage(package);
      await _waitForServer();
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code != PurchasesErrorCode.purchaseCancelledError) {
        message = 'The purchase did not go through. ${e.message ?? ''}'.trim();
      }
    } catch (e) {
      message = 'The purchase did not go through.';
    }
    busy = false;
    notifyListeners();
  }

  Future<void> restore() async {
    if (!storeAvailable || !_configured) return;
    busy = true;
    message = null;
    notifyListeners();
    try {
      await Purchases.restorePurchases();
      await _waitForServer();
      if (!active) message = 'No active subscription was found to restore.';
    } catch (_) {
      message = 'Could not restore right now.';
    }
    busy = false;
    notifyListeners();
  }

  /// The webhook takes a few seconds, so check the server until it catches up.
  Future<void> _waitForServer() async {
    for (var i = 0; i < 10; i++) {
      await refresh();
      if (active) return;
      await Future<void>.delayed(const Duration(milliseconds: 1500));
    }
    message = 'Payment received. Your subscription will switch on in a moment.';
  }

  Future<void> reset() async {
    active = false;
    accountType = 'free';
    monthly = null;
    yearly = null;
    message = null;
    if (_configured) {
      try {
        await Purchases.logOut();
      } catch (_) {}
    }
    notifyListeners();
  }
}

final subscription = SubscriptionStore();
