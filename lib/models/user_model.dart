import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserProfile {
  final String currency;
  @JsonKey(name: 'monthly_budget')
  final double? monthlyBudget;
  final String? avatar;
  @JsonKey(name: 'phone_number')
  final String? phoneNumber;
  @JsonKey(name: 'date_of_birth')
  final String? dateOfBirth;

  const UserProfile({
    required this.currency,
    this.monthlyBudget,
    this.avatar,
    this.phoneNumber,
    this.dateOfBirth,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);

  Map<String, dynamic> toJson() => _$UserProfileToJson(this);

  UserProfile copyWith({
    String? currency,
    double? monthlyBudget,
    String? avatar,
    String? phoneNumber,
    String? dateOfBirth,
  }) {
    return UserProfile(
      currency: currency ?? this.currency,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
      avatar: avatar ?? this.avatar,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
    );
  }
}

@JsonSerializable()
class UserModel {
  final int id;
  final String username;
  final String email;
  @JsonKey(name: 'first_name')
  final String? firstName;
  @JsonKey(name: 'last_name')
  final String? lastName;
  @JsonKey(name: 'date_joined')
  final String dateJoined;
  final UserProfile? profile;

  const UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.firstName,
    this.lastName,
    required this.dateJoined,
    this.profile,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName'.trim();
    } else if (firstName != null) {
      return firstName!;
    } else if (lastName != null) {
      return lastName!;
    }
    return username;
  }

  String get displayName => fullName.isNotEmpty ? fullName : username;

  UserModel copyWith({
    int? id,
    String? username,
    String? email,
    String? firstName,
    String? lastName,
    String? dateJoined,
    UserProfile? profile,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      dateJoined: dateJoined ?? this.dateJoined,
      profile: profile ?? this.profile,
    );
  }
} 