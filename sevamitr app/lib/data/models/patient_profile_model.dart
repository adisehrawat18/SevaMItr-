class PatientProfile {
  final int? id;
  final String fullName;
  final String preferredName;
  final int age;
  final String caregiverName;
  final String caregiverPhone;
  final String careNotes;
  final DateTime createdAt;
  final String gender;
  final String region;
  final String primaryLanguage;
  final String dementiaStage;
  final String emergencyContact;
  final bool enableKiosk;
  final String kioskIdentifier;
  final String kioskPin;
  final String serverPatientId;
  final int serverSyncedAt;

  const PatientProfile({
    this.id,
    required this.fullName,
    required this.preferredName,
    required this.age,
    required this.caregiverName,
    required this.caregiverPhone,
    this.careNotes = '',
    required this.createdAt,
    this.gender = 'Female',
    this.region = 'Kamrup Rural, Assam',
    this.primaryLanguage = 'en',
    this.dementiaStage = 'Mild',
    this.emergencyContact = '',
    this.enableKiosk = false,
    this.kioskIdentifier = '',
    this.kioskPin = '',
    this.serverPatientId = '',
    this.serverSyncedAt = 0,
  });

  PatientProfile copyWith({
    int? id,
    String? fullName,
    String? preferredName,
    int? age,
    String? caregiverName,
    String? caregiverPhone,
    String? careNotes,
    DateTime? createdAt,
    String? gender,
    String? region,
    String? primaryLanguage,
    String? dementiaStage,
    String? emergencyContact,
    bool? enableKiosk,
    String? kioskIdentifier,
    String? kioskPin,
    String? serverPatientId,
    int? serverSyncedAt,
  }) => PatientProfile(
    id: id ?? this.id,
    fullName: fullName ?? this.fullName,
    preferredName: preferredName ?? this.preferredName,
    age: age ?? this.age,
    caregiverName: caregiverName ?? this.caregiverName,
    caregiverPhone: caregiverPhone ?? this.caregiverPhone,
    careNotes: careNotes ?? this.careNotes,
    createdAt: createdAt ?? this.createdAt,
    gender: gender ?? this.gender,
    region: region ?? this.region,
    primaryLanguage: primaryLanguage ?? this.primaryLanguage,
    dementiaStage: dementiaStage ?? this.dementiaStage,
    emergencyContact: emergencyContact ?? this.emergencyContact,
    enableKiosk: enableKiosk ?? this.enableKiosk,
    kioskIdentifier: kioskIdentifier ?? this.kioskIdentifier,
    kioskPin: kioskPin ?? this.kioskPin,
    serverPatientId: serverPatientId ?? this.serverPatientId,
    serverSyncedAt: serverSyncedAt ?? this.serverSyncedAt,
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'fullName': fullName,
    'preferredName': preferredName,
    'age': age,
    'caregiverName': caregiverName,
    'caregiverPhone': caregiverPhone,
    'careNotes': careNotes,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'gender': gender,
    'region': region,
    'primaryLanguage': primaryLanguage,
    'dementiaStage': dementiaStage,
    'emergencyContact': emergencyContact.isNotEmpty ? emergencyContact : caregiverPhone,
    'enableKiosk': enableKiosk ? 1 : 0,
    'kioskIdentifier': kioskIdentifier,
    'kioskPin': kioskPin,
    'serverPatientId': serverPatientId,
    'serverSyncedAt': serverSyncedAt,
  };

  factory PatientProfile.fromMap(Map<String, Object?> map) => PatientProfile(
    id: map['id'] as int?,
    fullName: (map['fullName'] as String?) ?? '',
    preferredName: (map['preferredName'] as String?) ?? (map['fullName'] as String? ?? '').split(' ').first,
    age: (map['age'] as int?) ?? 70,
    caregiverName: (map['caregiverName'] as String?) ?? '',
    caregiverPhone: (map['caregiverPhone'] as String?) ?? (map['emergencyContact'] as String? ?? ''),
    careNotes: (map['careNotes'] as String?) ?? '',
    createdAt: DateTime.fromMillisecondsSinceEpoch(
      (map['createdAt'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
    ),
    gender: (map['gender'] as String?) ?? 'Female',
    region: (map['region'] as String?) ?? 'Kamrup Rural, Assam',
    primaryLanguage: (map['primaryLanguage'] as String?) ?? 'en',
    dementiaStage: (map['dementiaStage'] as String?) ?? 'Mild',
    emergencyContact: (map['emergencyContact'] as String?) ?? (map['caregiverPhone'] as String? ?? ''),
    enableKiosk: (map['enableKiosk'] as int? ?? 0) == 1,
    kioskIdentifier: (map['kioskIdentifier'] as String?) ?? '',
    kioskPin: (map['kioskPin'] as String?) ?? '',
    serverPatientId: (map['serverPatientId'] as String?) ?? '',
    serverSyncedAt: (map['serverSyncedAt'] as int?) ?? 0,
  );
}
