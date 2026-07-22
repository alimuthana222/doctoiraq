import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/domain.dart';

abstract class NabdaRepository {
  Future<void> requestOtp(String phone);
  Future<void> verifyOtp({required String phone, required String token});
  Future<List<Doctor>> getDoctors({String? specialty, bool availableTodayOnly = false});
  Future<List<Appointment>> getAppointments();
  Future<List<MedicalRecord>> getMedicalRecords();
  Future<void> bookAppointment({
    required String doctorId,
    required String patientId,
    required DateTime scheduledAt,
    required String reason,
  });
  Future<void> cancelAppointment(String appointmentId);
}

class MockNabdaRepository implements NabdaRepository {
  MockNabdaRepository();

  final _doctors = <Doctor>[
    Doctor(
      id: 'd1',
      fullName: 'د. علي مهدي',
      specialty: 'قلبية',
      clinic: 'عيادة النبض التخصصية',
      distanceKm: 1.7,
      rating: 4.9,
      availableToday: true,
      bio: 'اختصاص قلبية مع خبرة أكثر من 12 سنة.',
      feeIqd: 25000,
      timeSlots: List.generate(6, (i) => DateTime.now().add(Duration(hours: i + 2))),
    ),
    Doctor(
      id: 'd2',
      fullName: 'د. زهراء كريم',
      specialty: 'أطفال',
      clinic: 'مركز الرعاية للأطفال',
      distanceKm: 3.1,
      rating: 4.8,
      availableToday: false,
      bio: 'طب أطفال وحديثي الولادة.',
      feeIqd: 20000,
      timeSlots: List.generate(5, (i) => DateTime.now().add(Duration(days: 1, hours: i + 1))),
    ),
  ];

  final _appointments = <Appointment>[];

  @override
  Future<void> requestOtp(String phone) async => Future<void>.delayed(const Duration(milliseconds: 350));

  @override
  Future<void> verifyOtp({required String phone, required String token}) async =>
      Future<void>.delayed(const Duration(milliseconds: 350));

  @override
  Future<List<Doctor>> getDoctors({String? specialty, bool availableTodayOnly = false}) async {
    var list = _doctors;
    if (specialty != null && specialty.isNotEmpty) {
      list = list.where((d) => d.specialty == specialty).toList();
    }
    if (availableTodayOnly) {
      list = list.where((d) => d.availableToday).toList();
    }
    return list;
  }

  @override
  Future<List<Appointment>> getAppointments() async => _appointments;

  @override
  Future<List<MedicalRecord>> getMedicalRecords() async => [
    MedicalRecord(
      id: 'mr1',
      date: DateTime.now().subtract(const Duration(days: 30)),
      clinic: 'عيادة النبض التخصصية',
      doctorName: 'د. علي مهدي',
      summary: 'فحص دوري للقلب مع توصية بالمتابعة بعد شهر.',
      attachments: const ['ecg-report.pdf', 'prescription.jpg'],
    ),
  ];

  @override
  Future<void> bookAppointment({
    required String doctorId,
    required String patientId,
    required DateTime scheduledAt,
    required String reason,
  }) async {
    final doctor = _doctors.firstWhere((d) => d.id == doctorId);
    final clash = _appointments.any((a) =>
        a.doctor.id == doctorId &&
        a.scheduledAt.isAtSameMomentAs(scheduledAt) &&
        a.status != AppointmentStatus.cancelled);
    if (clash) {
      throw Exception('هذا الموعد محجوز بالفعل، اختر وقتاً آخر.');
    }

    _appointments.add(
      Appointment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        doctor: doctor,
        scheduledAt: scheduledAt,
        durationMinutes: 30,
        status: AppointmentStatus.pending,
        reason: reason,
      ),
    );
  }

  @override
  Future<void> cancelAppointment(String appointmentId) async {
    final index = _appointments.indexWhere((a) => a.id == appointmentId);
    if (index == -1) return;
    final old = _appointments[index];
    _appointments[index] = Appointment(
      id: old.id,
      doctor: old.doctor,
      scheduledAt: old.scheduledAt,
      durationMinutes: old.durationMinutes,
      status: AppointmentStatus.cancelled,
      reason: old.reason,
    );
  }
}

class SupabaseNabdaRepository implements NabdaRepository {
  SupabaseNabdaRepository(this.client);

  final SupabaseClient client;

  @override
  Future<void> requestOtp(String phone) => client.auth.signInWithOtp(phone: phone);

  @override
  Future<void> verifyOtp({required String phone, required String token}) =>
      client.auth.verifyOTP(type: OtpType.sms, phone: phone, token: token);

  @override
  Future<List<Doctor>> getDoctors({String? specialty, bool availableTodayOnly = false}) async {
    var query = client.from('staff').select('id,full_name,specialty,clinic_id').eq('role', 'doctor');
    if (specialty != null && specialty.isNotEmpty) {
      query = query.eq('specialty', specialty);
    }

    final rows = await query;
    final doctors = (rows as List)
        .map(
          (r) => Doctor(
            id: r['id'] as String,
            fullName: (r['full_name'] ?? '') as String,
            specialty: (r['specialty'] ?? 'عام') as String,
            clinic: (r['clinic_id'] ?? 'clinic') as String,
            distanceKm: 0,
            rating: 4.5,
            availableToday: true,
            bio: '—',
            feeIqd: 0,
            timeSlots: const [],
          ),
        )
        .toList();

    if (!availableTodayOnly) return doctors;
    return doctors.where((d) => d.availableToday).toList();
  }

  @override
  Future<List<Appointment>> getAppointments() async {
    final rows = await client
        .from('appointments')
        .select('id,scheduled_at,duration_minutes,status,reason,staff(id,full_name,specialty)')
        .order('scheduled_at', ascending: false);

    return (rows as List).map((r) {
      final doctorJson = r['staff'] as Map<String, dynamic>? ?? <String, dynamic>{};
      final doctor = Doctor(
        id: (doctorJson['id'] ?? 'unknown').toString(),
        fullName: (doctorJson['full_name'] ?? 'طبيب').toString(),
        specialty: (doctorJson['specialty'] ?? 'عام').toString(),
        clinic: 'clinic',
        distanceKm: 0,
        rating: 4.5,
        availableToday: true,
        bio: '—',
        feeIqd: 0,
        timeSlots: const [],
      );

      final statusRaw = (r['status'] ?? 'pending').toString();
      final status = switch (statusRaw) {
        'confirmed' => AppointmentStatus.confirmed,
        'completed' => AppointmentStatus.completed,
        'cancelled' => AppointmentStatus.cancelled,
        'no_show' => AppointmentStatus.noShow,
        _ => AppointmentStatus.pending,
      };

      return Appointment(
        id: r['id'].toString(),
        doctor: doctor,
        scheduledAt: DateTime.parse(r['scheduled_at'] as String),
        durationMinutes: (r['duration_minutes'] as num?)?.toInt() ?? 30,
        status: status,
        reason: r['reason']?.toString(),
      );
    }).toList();
  }

  @override
  Future<List<MedicalRecord>> getMedicalRecords() async {
    final rows = await client
        .from('medical_records')
        .select('id,created_at,notes,attachments,appointments(clinic_id,staff(full_name))')
        .order('created_at', ascending: false);

    return (rows as List).map((r) {
      final appointment = r['appointments'] as Map<String, dynamic>? ?? <String, dynamic>{};
      final staff = appointment['staff'] as Map<String, dynamic>? ?? <String, dynamic>{};
      final rawAttachments = r['attachments'];
      final attachments = rawAttachments is List ? rawAttachments.map((e) => e.toString()).toList() : <String>[];
      return MedicalRecord(
        id: r['id'].toString(),
        date: DateTime.tryParse((r['created_at'] ?? '').toString()) ?? DateTime.now(),
        clinic: (appointment['clinic_id'] ?? 'clinic').toString(),
        doctorName: (staff['full_name'] ?? 'طبيب').toString(),
        summary: (r['notes'] ?? '').toString(),
        attachments: attachments,
      );
    }).toList();
  }

  @override
  Future<void> bookAppointment({
    required String doctorId,
    required String patientId,
    required DateTime scheduledAt,
    required String reason,
  }) async {
    await client.rpc(
      'book_appointment',
      params: {
        'p_staff_id': doctorId,
        'p_patient_id': patientId,
        'p_scheduled_at': scheduledAt.toIso8601String(),
        'p_reason': reason,
      },
    );
  }

  @override
  Future<void> cancelAppointment(String appointmentId) async {
    await client.from('appointments').update({'status': 'cancelled'}).eq('id', appointmentId);
  }
}
