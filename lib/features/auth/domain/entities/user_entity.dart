// Immutable domain entity for the authenticated user.
// Hand-written (no code-gen) for immediate compilation.
// Migrate to @freezed in Phase 5 when build_runner is run.

enum KycStatus { PENDING, UNDER_REVIEW, APPROVED, REJECTED }
enum ActivePortal { CUSTOMER, ORGANIZER, HOST }

class UserEntity {
  final String id;
  final String email;
  final String name;
  final String phone;
  final String city;
  final bool isOrganizer;
  final bool canHostEvents;
  final KycStatus kycStatus;
  final ActivePortal activePortal;

  const UserEntity({
    required this.id,
    required this.email,
    required this.name,
    this.phone = '',
    this.city = '',
    this.isOrganizer = false,
    this.canHostEvents = false,
    this.kycStatus = KycStatus.PENDING,
    this.activePortal = ActivePortal.CUSTOMER,
  });

  UserEntity copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    String? city,
    bool? isOrganizer,
    bool? canHostEvents,
    KycStatus? kycStatus,
    ActivePortal? activePortal,
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      city: city ?? this.city,
      isOrganizer: isOrganizer ?? this.isOrganizer,
      canHostEvents: canHostEvents ?? this.canHostEvents,
      kycStatus: kycStatus ?? this.kycStatus,
      activePortal: activePortal ?? this.activePortal,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email;

  @override
  int get hashCode => Object.hash(id, email);

  @override
  String toString() =>
      'UserEntity(id: $id, name: $name, isOrganizer: $isOrganizer)';
}
