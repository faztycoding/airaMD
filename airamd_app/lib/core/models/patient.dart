import 'enums.dart';

class Patient {
  final String id;
  final String clinicId;
  final String? hn;
  final String firstName;
  final String lastName;
  final String? nickname;
  final DateTime? dateOfBirth;
  final GenderType? gender;
  final String? nationalId;
  final String? passportNo;
  final String? phone;
  final String? lineId;
  final String? facebook;
  final String? instagram;
  final String? email;
  final String? address;
  final PatientStatus status;
  final List<String> drugAllergies;
  final String? allergySymptoms;
  final List<String> medicalConditions;
  final List<String> currentMedications;
  final SmokingType smoking;
  final AlcoholType alcohol;
  final bool isUsingRetinoids;
  final bool isOnAnticoagulant;
  final PreferredChannel preferredChannel;
  final String? profilePhotoUrl;
  final String? notes;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Patient({
    required this.id,
    required this.clinicId,
    this.hn,
    required this.firstName,
    required this.lastName,
    this.nickname,
    this.dateOfBirth,
    this.gender,
    this.nationalId,
    this.passportNo,
    this.phone,
    this.lineId,
    this.facebook,
    this.instagram,
    this.email,
    this.address,
    this.status = PatientStatus.normal,
    this.drugAllergies = const [],
    this.allergySymptoms,
    this.medicalConditions = const [],
    this.currentMedications = const [],
    this.smoking = SmokingType.none,
    this.alcohol = AlcoholType.none,
    this.isUsingRetinoids = false,
    this.isOnAnticoagulant = false,
    this.preferredChannel = PreferredChannel.none,
    this.profilePhotoUrl,
    this.notes,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  String get fullName => '$firstName $lastName';
  String get displayName => nickname != null && nickname!.isNotEmpty
      ? '$firstName ($nickname)'
      : firstName;

  int? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int years = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      years--;
    }
    return years;
  }

  factory Patient.fromJson(Map<String, dynamic> json) => Patient(
        id: json['id'] as String,
        clinicId: json['clinic_id'] as String,
        hn: json['hn'] as String?,
        firstName: json['first_name'] as String,
        lastName: json['last_name'] as String,
        nickname: json['nickname'] as String?,
        dateOfBirth: json['date_of_birth'] != null
            ? DateTime.tryParse(json['date_of_birth'].toString())
            : null,
        gender: json['gender'] != null
            ? GenderType.fromDb(json['gender'] as String?)
            : null,
        nationalId: json['national_id'] as String?,
        passportNo: json['passport_no'] as String?,
        phone: json['phone'] as String?,
        lineId: json['line_id'] as String?,
        facebook: json['facebook'] as String?,
        instagram: json['instagram'] as String?,
        email: json['email'] as String?,
        address: json['address'] as String?,
        status: PatientStatus.fromDb(json['status'] as String?),
        drugAllergies: _parseStringList(json['drug_allergies']),
        allergySymptoms: json['allergy_symptoms'] as String?,
        medicalConditions: _parseStringList(json['medical_conditions']),
        currentMedications: _parseStringList(json['current_medications']),
        smoking: SmokingType.fromDb(json['smoking'] as String?),
        alcohol: AlcoholType.fromDb(json['alcohol'] as String?),
        isUsingRetinoids: json['is_using_retinoids'] as bool? ?? false,
        isOnAnticoagulant: json['is_on_anticoagulant'] as bool? ?? false,
        preferredChannel:
            PreferredChannel.fromDb(json['preferred_channel'] as String?),
        profilePhotoUrl: json['profile_photo_url'] as String?,
        notes: json['notes'] as String?,
        isActive: json['is_active'] as bool? ?? true,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'].toString())
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.tryParse(json['updated_at'].toString())
            : null,
      );

  Map<String, dynamic> toInsertJson() => {
        'clinic_id': clinicId,
        'first_name': firstName,
        'last_name': lastName,
        if (nickname != null) 'nickname': nickname,
        if (dateOfBirth != null)
          'date_of_birth': dateOfBirth!.toIso8601String().split('T').first,
        if (gender != null) 'gender': gender!.dbValue,
        if (nationalId != null) 'national_id': nationalId,
        if (passportNo != null) 'passport_no': passportNo,
        if (phone != null) 'phone': phone,
        if (lineId != null) 'line_id': lineId,
        if (facebook != null) 'facebook': facebook,
        if (instagram != null) 'instagram': instagram,
        if (email != null) 'email': email,
        if (address != null) 'address': address,
        'status': status.dbValue,
        'drug_allergies': drugAllergies,
        if (allergySymptoms != null) 'allergy_symptoms': allergySymptoms,
        'medical_conditions': medicalConditions,
        'current_medications': currentMedications,
        'smoking': smoking.dbValue,
        'alcohol': alcohol.dbValue,
        'is_using_retinoids': isUsingRetinoids,
        'is_on_anticoagulant': isOnAnticoagulant,
        'preferred_channel': preferredChannel.dbValue,
        if (profilePhotoUrl != null) 'profile_photo_url': profilePhotoUrl,
        if (notes != null) 'notes': notes,
      };

  Map<String, dynamic> toUpdateJson() => {
        'first_name': firstName,
        'last_name': lastName,
        'nickname': nickname,
        'date_of_birth': dateOfBirth?.toIso8601String().split('T').first,
        'gender': gender?.dbValue,
        'national_id': nationalId,
        'passport_no': passportNo,
        'phone': phone,
        'line_id': lineId,
        'facebook': facebook,
        'instagram': instagram,
        'email': email,
        'address': address,
        'status': status.dbValue,
        'drug_allergies': drugAllergies,
        'allergy_symptoms': allergySymptoms,
        'medical_conditions': medicalConditions,
        'current_medications': currentMedications,
        'smoking': smoking.dbValue,
        'alcohol': alcohol.dbValue,
        'is_using_retinoids': isUsingRetinoids,
        'is_on_anticoagulant': isOnAnticoagulant,
        'preferred_channel': preferredChannel.dbValue,
        'profile_photo_url': profilePhotoUrl,
        'notes': notes,
      };

  Patient copyWith({
    String? id,
    String? clinicId,
    String? hn,
    String? firstName,
    String? lastName,
    String? nickname,
    DateTime? dateOfBirth,
    GenderType? gender,
    String? nationalId,
    String? passportNo,
    String? phone,
    String? lineId,
    String? facebook,
    String? instagram,
    String? email,
    String? address,
    PatientStatus? status,
    List<String>? drugAllergies,
    String? allergySymptoms,
    List<String>? medicalConditions,
    List<String>? currentMedications,
    SmokingType? smoking,
    AlcoholType? alcohol,
    bool? isUsingRetinoids,
    bool? isOnAnticoagulant,
    PreferredChannel? preferredChannel,
    String? profilePhotoUrl,
    String? notes,
  }) =>
      Patient(
        id: id ?? this.id,
        clinicId: clinicId ?? this.clinicId,
        hn: hn ?? this.hn,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        nickname: nickname ?? this.nickname,
        dateOfBirth: dateOfBirth ?? this.dateOfBirth,
        gender: gender ?? this.gender,
        nationalId: nationalId ?? this.nationalId,
        passportNo: passportNo ?? this.passportNo,
        phone: phone ?? this.phone,
        lineId: lineId ?? this.lineId,
        facebook: facebook ?? this.facebook,
        instagram: instagram ?? this.instagram,
        email: email ?? this.email,
        address: address ?? this.address,
        status: status ?? this.status,
        drugAllergies: drugAllergies ?? this.drugAllergies,
        allergySymptoms: allergySymptoms ?? this.allergySymptoms,
        medicalConditions: medicalConditions ?? this.medicalConditions,
        currentMedications: currentMedications ?? this.currentMedications,
        smoking: smoking ?? this.smoking,
        alcohol: alcohol ?? this.alcohol,
        isUsingRetinoids: isUsingRetinoids ?? this.isUsingRetinoids,
        isOnAnticoagulant: isOnAnticoagulant ?? this.isOnAnticoagulant,
        preferredChannel: preferredChannel ?? this.preferredChannel,
        profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
        notes: notes ?? this.notes,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    return [];
  }
}
