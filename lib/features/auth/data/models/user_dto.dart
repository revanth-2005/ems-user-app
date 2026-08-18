import '../../domain/entities/user_entity.dart';

// Hand-written DTO — no code-gen required.
// Fields match the API JSON response from the backend.

class UserDto {
  final String id;
  final String email;
  final String name;
  final String phone;
  final String city;
  final bool isOrganizer;
  final bool canHostEvents;
  final String kycStatus;

  const UserDto({
    required this.id,
    required this.email,
    required this.name,
    this.phone = '',
    this.city = '',
    this.isOrganizer = false,
    this.canHostEvents = false,
    this.kycStatus = 'PENDING',
  });

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      city: (json['city'] ?? '').toString(),
      isOrganizer: json['isOrganizer'] as bool? ?? false,
      canHostEvents: json['canHostEvents'] as bool? ?? false,
      kycStatus: (json['kycStatus'] ?? 'PENDING').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'phone': phone,
        'city': city,
        'isOrganizer': isOrganizer,
        'canHostEvents': canHostEvents,
        'kycStatus': kycStatus,
      };

  UserEntity toEntity() => UserEntity(
        id: id,
        email: email,
        name: name,
        phone: phone,
        city: city,
        isOrganizer: isOrganizer,
        canHostEvents: canHostEvents,
        kycStatus: _parseKycStatus(kycStatus),
      );

  static KycStatus _parseKycStatus(String raw) {
    return KycStatus.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => KycStatus.PENDING,
    );
  }
}
