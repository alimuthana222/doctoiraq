enum AppointmentStatus { pending, confirmed, completed, cancelled, noShow }

class Doctor {
  const Doctor({
    required this.id,
    required this.fullName,
    required this.specialty,
    required this.clinic,
    required this.distanceKm,
    required this.rating,
    required this.availableToday,
    required this.bio,
    required this.feeIqd,
    required this.timeSlots,
  });

  final String id;
  final String fullName;
  final String specialty;
  final String clinic;
  final double distanceKm;
  final double rating;
  final bool availableToday;
  final String bio;
  final int feeIqd;
  final List<DateTime> timeSlots;
}

class Appointment {
  const Appointment({
    required this.id,
    required this.doctor,
    required this.scheduledAt,
    required this.durationMinutes,
    required this.status,
    this.reason,
  });

  final String id;
  final Doctor doctor;
  final DateTime scheduledAt;
  final int durationMinutes;
  final AppointmentStatus status;
  final String? reason;

  bool get isUpcoming =>
      scheduledAt.isAfter(DateTime.now()) &&
      (status == AppointmentStatus.pending || status == AppointmentStatus.confirmed);
}

class MedicalRecord {
  const MedicalRecord({
    required this.id,
    required this.date,
    required this.clinic,
    required this.doctorName,
    required this.summary,
    required this.attachments,
  });

  final String id;
  final DateTime date;
  final String clinic;
  final String doctorName;
  final String summary;
  final List<String> attachments;
}
