/// Domain entities for User Event Hosting Subscriptions, plan tiers,
/// usage tracking, and Razorpay payment order payloads.

class EventSubscriptionPlan {
  final String id;
  final String tier; // 'BASIC' | 'MEDIUM' | 'ADVANCED'
  final String name;
  final int monthlyPriceInPaise;
  final int annualPriceInPaise;
  final int? maxActiveEvents; // null means Unlimited
  final String supportLevel;
  final Map<String, dynamic> featureFlags;
  final bool isActive;

  const EventSubscriptionPlan({
    required this.id,
    required this.tier,
    required this.name,
    required this.monthlyPriceInPaise,
    required this.annualPriceInPaise,
    this.maxActiveEvents,
    required this.supportLevel,
    this.featureFlags = const {},
    this.isActive = true,
  });

  bool get isFree => monthlyPriceInPaise == 0 && annualPriceInPaise == 0;
  bool get isUnlimited => maxActiveEvents == null;

  int get monthlyPriceInRupees => (monthlyPriceInPaise / 100).round();
  int get annualPriceInRupees => (annualPriceInPaise / 100).round();

  factory EventSubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return EventSubscriptionPlan(
      id: json['id']?.toString() ?? '',
      tier: json['tier']?.toString().toUpperCase() ?? 'BASIC',
      name: json['name']?.toString() ?? 'Event Host Plan',
      monthlyPriceInPaise: (json['monthlyPriceInPaise'] as num?)?.toInt() ?? 0,
      annualPriceInPaise: (json['annualPriceInPaise'] as num?)?.toInt() ?? 0,
      maxActiveEvents: (json['maxActiveEvents'] as num?)?.toInt(),
      supportLevel: json['supportLevel']?.toString() ?? 'Standard Support',
      featureFlags: (json['featureFlags'] is Map<String, dynamic>)
          ? json['featureFlags'] as Map<String, dynamic>
          : const {},
      isActive: json['isActive'] == true || json['is_active'] == true,
    );
  }
}

class SubscriptionUsage {
  final int activeEvents;
  final int? maxActiveEvents;

  const SubscriptionUsage({
    required this.activeEvents,
    this.maxActiveEvents,
  });

  bool get isUnlimited => maxActiveEvents == null;
  bool get isLimitReached => maxActiveEvents != null && activeEvents >= maxActiveEvents!;
  
  int get remainingSlots => isUnlimited ? 9999 : (maxActiveEvents! - activeEvents).clamp(0, 9999);

  double get usageRatio {
    if (isUnlimited || maxActiveEvents == 0) return 0.0;
    return (activeEvents / maxActiveEvents!).clamp(0.0, 1.0);
  }

  factory SubscriptionUsage.fromJson(Map<String, dynamic> json) {
    return SubscriptionUsage(
      activeEvents: (json['activeEvents'] as num?)?.toInt() ?? 0,
      maxActiveEvents: (json['maxActiveEvents'] as num?)?.toInt(),
    );
  }
}

class UserEventSubscription {
  final String id;
  final String? userId;
  final String? planId;
  final String status; // 'ACTIVE' | 'PAST_DUE' | 'CANCELLED'
  final String billingCycle; // 'monthly' | 'annual'
  final DateTime? currentPeriodStart;
  final DateTime? currentPeriodEnd;
  final EventSubscriptionPlan? plan;

  const UserEventSubscription({
    required this.id,
    this.userId,
    this.planId,
    required this.status,
    this.billingCycle = 'monthly',
    this.currentPeriodStart,
    this.currentPeriodEnd,
    this.plan,
  });

  bool get isActive => status.toUpperCase() == 'ACTIVE';

  factory UserEventSubscription.fromJson(Map<String, dynamic> json) {
    EventSubscriptionPlan? parsedPlan;
    if (json['plan'] is Map<String, dynamic>) {
      parsedPlan = EventSubscriptionPlan.fromJson(json['plan'] as Map<String, dynamic>);
    }

    return UserEventSubscription(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString(),
      planId: json['planId']?.toString(),
      status: json['status']?.toString().toUpperCase() ?? 'ACTIVE',
      billingCycle: json['billingCycle']?.toString().toLowerCase() ?? 'monthly',
      currentPeriodStart: json['currentPeriodStart'] != null
          ? DateTime.tryParse(json['currentPeriodStart'].toString())
          : null,
      currentPeriodEnd: json['currentPeriodEnd'] != null
          ? DateTime.tryParse(json['currentPeriodEnd'].toString())
          : null,
      plan: parsedPlan,
    );
  }
}

class UserEventSubscriptionResponse {
  final bool hasSubscription;
  final UserEventSubscription? subscription;
  final SubscriptionUsage usage;

  const UserEventSubscriptionResponse({
    required this.hasSubscription,
    this.subscription,
    required this.usage,
  });

  factory UserEventSubscriptionResponse.fromJson(Map<String, dynamic> json) {
    UserEventSubscription? sub;
    if (json['subscription'] is Map<String, dynamic>) {
      sub = UserEventSubscription.fromJson(json['subscription'] as Map<String, dynamic>);
    }

    final usageJson = (json['usage'] is Map<String, dynamic>)
        ? json['usage'] as Map<String, dynamic>
        : <String, dynamic>{'activeEvents': 0, 'maxActiveEvents': 5};

    return UserEventSubscriptionResponse(
      hasSubscription: json['hasSubscription'] == true,
      subscription: sub,
      usage: SubscriptionUsage.fromJson(usageJson),
    );
  }
}

class SubscriptionPaymentOrder {
  final String? paymentId;
  final String gatewayOrderId;
  final int amountInPaise;
  final String currency;
  final String paymentType;
  final String key;

  const SubscriptionPaymentOrder({
    this.paymentId,
    required this.gatewayOrderId,
    required this.amountInPaise,
    this.currency = 'INR',
    this.paymentType = 'SUBSCRIPTION',
    required this.key,
  });

  factory SubscriptionPaymentOrder.fromJson(Map<String, dynamic> json) {
    return SubscriptionPaymentOrder(
      paymentId: json['paymentId']?.toString() ?? json['payment_id']?.toString(),
      gatewayOrderId: json['gatewayOrderId']?.toString() ?? json['order_id']?.toString() ?? '',
      amountInPaise: (json['amountInPaise'] as num?)?.toInt() ?? (json['amount'] as num?)?.toInt() ?? 0,
      currency: json['currency']?.toString() ?? 'INR',
      paymentType: json['paymentType']?.toString() ?? 'SUBSCRIPTION',
      key: json['key']?.toString() ?? 'rzp_test_YourKeyId',
    );
  }
}

class SelectPlanResponse {
  final bool requiresPayment;
  final SubscriptionPaymentOrder? paymentOrder;
  final UserEventSubscription? subscription;

  const SelectPlanResponse({
    required this.requiresPayment,
    this.paymentOrder,
    this.subscription,
  });

  factory SelectPlanResponse.fromJson(Map<String, dynamic> json) {
    SubscriptionPaymentOrder? order;
    if (json['paymentOrder'] is Map<String, dynamic>) {
      order = SubscriptionPaymentOrder.fromJson(json['paymentOrder'] as Map<String, dynamic>);
    }

    UserEventSubscription? sub;
    if (json['subscription'] is Map<String, dynamic>) {
      sub = UserEventSubscription.fromJson(json['subscription'] as Map<String, dynamic>);
    }

    return SelectPlanResponse(
      requiresPayment: json['requiresPayment'] == true,
      paymentOrder: order,
      subscription: sub,
    );
  }
}
