import '../../core/api/api_client.dart';
import '../../core/api/api_error.dart';

/// Un mois de cotisation à régler.
class DuePeriod {
  const DuePeriod({required this.periode, required this.amount});
  final String periode; // YYYY-MM
  final int amount;
}

/// Cotisations dues (`GET /payments/due`).
///
/// Règle du serveur : les mois impayés **les plus récents**, en remontant
/// depuis le mois courant (jamais de mois à l'avance). Le membre choisit
/// combien de mois régler ; ce sont toujours les plus récents d'abord.
class DueInfo {
  const DueInfo({
    required this.paymentsEnabled,
    required this.unitAmount,
    required this.maxMonths,
    required this.periods,
  });

  factory DueInfo.fromJson(Map<String, dynamic> j) => DueInfo(
        paymentsEnabled: j['paymentsEnabled'] == true,
        unitAmount: (j['unitAmount'] as num?)?.toInt() ?? 0,
        maxMonths: (j['maxMonths'] as num?)?.toInt() ?? 1,
        periods: [
          for (final p in (j['periods'] as List? ?? const []))
            if (p is Map)
              DuePeriod(
                periode: (p['periode'] ?? '').toString(),
                amount: (p['amount'] as num?)?.toInt() ?? 0,
              ),
        ],
      );

  final bool paymentsEnabled;
  final int unitAmount;
  final int maxMonths;

  /// Du plus ancien au plus récent (ordre du serveur).
  final List<DuePeriod> periods;

  /// Mois proposés, du plus récent au plus ancien.
  List<DuePeriod> get newestFirst => periods.reversed.toList(growable: false);

  /// Nombre maximal de mois que l'on peut choisir.
  int get selectableMonths => periods.length < maxMonths ? periods.length : maxMonths;

  /// Les [count] mois retenus (les plus récents).
  List<DuePeriod> selection(int count) => newestFirst.take(count).toList(growable: false);

  /// Aperçu du total : le serveur recalcule et fait foi.
  int previewTotal(int count) => unitAmount * count;
}

enum PayMethod { wave, orange, card }

/// Paiement créé côté serveur (toujours « pending »).
class PaymentIntent {
  const PaymentIntent({
    required this.paymentId,
    required this.amount,
    required this.periodes,
    required this.checkoutUrl,
  });

  factory PaymentIntent.fromJson(Map<String, dynamic> j) => PaymentIntent(
        paymentId: (j['paymentId'] ?? '').toString(),
        amount: (j['amount'] as num?)?.toInt() ?? 0,
        periodes: [for (final p in (j['periodes'] as List? ?? const [])) p.toString()],
        checkoutUrl: j['checkoutUrl'] as String?,
      );

  final String paymentId;
  final int amount;
  final List<String> periodes;

  /// Page de paiement hébergée (carte comprise).
  final String? checkoutUrl;
}

/// Où envoyer le membre pour valider le paiement.
class LaunchTarget {
  const LaunchTarget({this.url, this.alreadyPaid = false, this.hosted = false});
  final String? url;
  final bool alreadyPaid;

  /// `true` : page de paiement classique (SoftPay indisponible).
  final bool hosted;
}

enum PaymentState { pending, completed, canceled, failed }

class PaymentSnapshot {
  const PaymentSnapshot({
    required this.id,
    required this.state,
    required this.amount,
    required this.periodes,
    this.receiptUrl,
  });

  factory PaymentSnapshot.fromJson(Map<String, dynamic> j) => PaymentSnapshot(
        id: (j['id'] ?? '').toString(),
        state: switch (j['status']) {
          'completed' => PaymentState.completed,
          'canceled' => PaymentState.canceled,
          'failed' => PaymentState.failed,
          _ => PaymentState.pending,
        },
        amount: (j['amount'] as num?)?.toInt() ?? 0,
        periodes: [for (final p in (j['periodes'] as List? ?? const [])) p.toString()],
        receiptUrl: j['receiptUrl'] as String?,
      );

  final String id;
  final PaymentState state;
  final int amount;
  final List<String> periodes;
  final String? receiptUrl;

  bool get isFinal => state != PaymentState.pending;
}

/// Accès à `/api/mobile/v1/payments/*`. Aucune de ces méthodes ne « confirme »
/// quoi que ce soit : seul le statut renvoyé par le serveur fait foi.
class PaymentRepository {
  PaymentRepository(this._clients);
  final ApiClients _clients;

  Future<DueInfo> due() => guardApi(() async {
        final res = await _clients.authed.get<Map<String, dynamic>>('/api/mobile/v1/payments/due');
        return DueInfo.fromJson(res.data ?? const {});
      });

  Future<PaymentIntent> create(int monthsCount) => guardApi(() async {
        final res = await _clients.authed.post<Map<String, dynamic>>(
          '/api/mobile/v1/payments/cotisation',
          data: {'monthsCount': monthsCount},
        );
        return PaymentIntent.fromJson(res.data ?? const {});
      });

  Future<LaunchTarget> startSoftpay(String paymentId, PayMethod method, {String? phone}) =>
      guardApi(() async {
        final res = await _clients.authed.post<Map<String, dynamic>>(
          '/api/mobile/v1/payments/$paymentId/softpay',
          data: {
            'method': method == PayMethod.wave ? 'wave' : 'orange',
            if (phone != null && phone.isNotEmpty) 'phone': phone,
          },
        );
        final d = res.data ?? const {};
        if (d['alreadyPaid'] == true) return const LaunchTarget(alreadyPaid: true);
        final hosted = d['mode'] == 'hosted';
        final url = hosted
            ? d['url'] as String?
            : method == PayMethod.orange
                ? (d['omUrl'] ?? d['maxitUrl'] ?? d['url']) as String?
                : (d['url'] ?? d['omUrl']) as String?;
        return LaunchTarget(url: url, hosted: hosted);
      });

  Future<PaymentSnapshot> status(String paymentId) => guardApi(() async {
        final res = await _clients.authed.get<Map<String, dynamic>>('/api/mobile/v1/payments/$paymentId');
        return PaymentSnapshot.fromJson(res.data ?? const {});
      });
}
