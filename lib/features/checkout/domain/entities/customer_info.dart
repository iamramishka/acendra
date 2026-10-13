import 'package:flutter/foundation.dart';

@immutable
class CustomerInfo {
  const CustomerInfo({
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.address,
    required this.city,
    required this.country,
  });

  final String firstName;
  final String lastName;
  final String phone;
  final String address;
  final String city;
  final String country;

  bool get isValid =>
      firstName.isNotEmpty &&
      lastName.isNotEmpty &&
      phone.length >= 7 &&
      address.isNotEmpty &&
      city.isNotEmpty &&
      country.isNotEmpty;

  CustomerInfo copyWith({
    String? firstName,
    String? lastName,
    String? phone,
    String? address,
    String? city,
    String? country,
  }) {
    return CustomerInfo(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      city: city ?? this.city,
      country: country ?? this.country,
    );
  }
}
