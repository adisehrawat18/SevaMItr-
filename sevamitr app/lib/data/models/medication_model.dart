/// Medication Schedule Model for Offline-First Storage
class MedicationSchedule {
  final int? id;
  final String title; // e.g. "Morning Blood Pressure Tablet"
  final String regionalTitle; // e.g. "ৰাতিপুৱাৰ ঔষধ" (Assamese)
  final String dosageDescription; // e.g. "1 Green Pill with warm water"
  final String visualAssetType; // "PILL_GREEN", "WATER_GLASS", "SYRUP_SPOON"
  final String scheduledTimeFormatted; // "08:00 AM"
  final int hourOfDay; // 8
  final int minute; // 0
  final String audioChimeKey; // "chime_flute_calm"
  final bool isCompletedToday;
  final int? completedAtTimestamp;
  final String caregiverPhone;

  const MedicationSchedule({
    this.id,
    required this.title,
    required this.regionalTitle,
    required this.dosageDescription,
    required this.visualAssetType,
    required this.scheduledTimeFormatted,
    required this.hourOfDay,
    required this.minute,
    this.audioChimeKey = "chime_flute_calm",
    this.isCompletedToday = false,
    this.completedAtTimestamp,
    this.caregiverPhone = "+919876543210",
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'regionalTitle': regionalTitle,
      'dosageDescription': dosageDescription,
      'visualAssetType': visualAssetType,
      'scheduledTimeFormatted': scheduledTimeFormatted,
      'hourOfDay': hourOfDay,
      'minute': minute,
      'audioChimeKey': audioChimeKey,
      'isCompletedToday': isCompletedToday ? 1 : 0,
      'completedAtTimestamp': completedAtTimestamp,
      'caregiverPhone': caregiverPhone,
    };
  }

  factory MedicationSchedule.fromMap(Map<String, dynamic> map) {
    return MedicationSchedule(
      id: map['id'] as int?,
      title: map['title'] as String,
      regionalTitle: map['regionalTitle'] as String,
      dosageDescription: map['dosageDescription'] as String,
      visualAssetType: map['visualAssetType'] as String,
      scheduledTimeFormatted: map['scheduledTimeFormatted'] as String,
      hourOfDay: map['hourOfDay'] as int,
      minute: map['minute'] as int,
      audioChimeKey: map['audioChimeKey'] as String? ?? "chime_flute_calm",
      isCompletedToday: (map['isCompletedToday'] as int) == 1,
      completedAtTimestamp: map['completedAtTimestamp'] as int?,
      caregiverPhone: map['caregiverPhone'] as String? ?? "+919876543210",
    );
  }

  MedicationSchedule copyWith({
    int? id,
    String? title,
    String? regionalTitle,
    String? dosageDescription,
    String? visualAssetType,
    String? scheduledTimeFormatted,
    int? hourOfDay,
    int? minute,
    String? audioChimeKey,
    bool? isCompletedToday,
    int? completedAtTimestamp,
    String? caregiverPhone,
  }) {
    return MedicationSchedule(
      id: id ?? this.id,
      title: title ?? this.title,
      regionalTitle: regionalTitle ?? this.regionalTitle,
      dosageDescription: dosageDescription ?? this.dosageDescription,
      visualAssetType: visualAssetType ?? this.visualAssetType,
      scheduledTimeFormatted:
          scheduledTimeFormatted ?? this.scheduledTimeFormatted,
      hourOfDay: hourOfDay ?? this.hourOfDay,
      minute: minute ?? this.minute,
      audioChimeKey: audioChimeKey ?? this.audioChimeKey,
      isCompletedToday: isCompletedToday ?? this.isCompletedToday,
      completedAtTimestamp: completedAtTimestamp ?? this.completedAtTimestamp,
      caregiverPhone: caregiverPhone ?? this.caregiverPhone,
    );
  }
}
