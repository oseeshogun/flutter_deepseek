class UserBalance {
  const UserBalance({
    required this.currency,
    required this.totalBalance,
    required this.grantedBalance,
    required this.toppedUpBalance,
  });

  factory UserBalance.fromJson(Map<String, dynamic> json) {
    final balanceInfos = json['balance_infos'] as List<dynamic>?;
    if (balanceInfos != null && balanceInfos.isNotEmpty) {
      final info = balanceInfos.first as Map<String, dynamic>;
      return UserBalance(
        currency: info['currency'] as String? ?? 'USD',
        totalBalance: _parseAmount(info['total_balance']),
        grantedBalance: _parseAmount(info['granted_balance']),
        toppedUpBalance: _parseAmount(info['topped_up_balance']),
      );
    }

    return UserBalance(
      currency: json['currency'] as String? ?? 'USD',
      totalBalance: _parseAmount(json['total_balance']),
      grantedBalance: _parseAmount(json['granted_balance']),
      toppedUpBalance: _parseAmount(json['topped_up_balance']),
    );
  }

  static double _parseAmount(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  final String currency;
  final double totalBalance;
  final double grantedBalance;
  final double toppedUpBalance;
}
