import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'core/repository.dart';
import 'core/theme.dart';
import 'models/domain.dart';

class NabdaApp extends StatelessWidget {
  const NabdaApp({super.key});

  @override
  Widget build(BuildContext context) {
    Intl.defaultLocale = 'ar';
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'nabda',
      theme: NabdaTheme.light(),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: NabdaRoot(repository: MockNabdaRepository()),
      ),
    );
  }
}

class NabdaRoot extends StatefulWidget {
  const NabdaRoot({super.key, required this.repository});

  final NabdaRepository repository;

  @override
  State<NabdaRoot> createState() => _NabdaRootState();
}

class _NabdaRootState extends State<NabdaRoot> {
  bool _authenticated = false;

  @override
  Widget build(BuildContext context) {
    if (!_authenticated) {
      return AuthScreen(
        repository: widget.repository,
        onAuthenticated: () => setState(() => _authenticated = true),
      );
    }
    return MainShell(repository: widget.repository);
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    required this.repository,
    required this.onAuthenticated,
  });

  final NabdaRepository repository;
  final VoidCallback onAuthenticated;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _otpSent = false;
  bool _busy = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    setState(() => _busy = true);
    try {
      await widget.repository.requestOtp(_phoneController.text.trim());
      if (!mounted) return;
      setState(() => _otpSent = true);
      _toast('تم إرسال رمز التحقق');
    } catch (e) {
      _toast('تعذر إرسال الرمز: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verifyOtp() async {
    setState(() => _busy = true);
    try {
      await widget.repository.verifyOtp(
        phone: _phoneController.text.trim(),
        token: _otpController.text.trim(),
      );
      widget.onAuthenticated();
    } catch (e) {
      _toast('رمز غير صحيح: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Text('nabda', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              const Text('Healthcare begins here'),
              const SizedBox(height: 28),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'رقم الهاتف',
                  hintText: '07xxxxxxxxx',
                ),
              ),
              const SizedBox(height: 12),
              if (_otpSent)
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'رمز OTP'),
                ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: _busy ? null : (_otpSent ? _verifyOtp : _requestOtp),
                child: Text(_otpSent ? 'تأكيد الدخول' : 'إرسال الرمز'),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.repository});

  final NabdaRepository repository;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  Doctor? _selectedDoctor;

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(
        repository: widget.repository,
        onOpenDoctor: _openDoctor,
        onSearch: () => setState(() => _currentIndex = 1),
      ),
      SearchDoctorsScreen(repository: widget.repository, onOpenDoctor: _openDoctor),
      AppointmentsScreen(repository: widget.repository),
      RecordsScreen(repository: widget.repository),
      const ProfileScreen(),
    ];

    final body = _selectedDoctor == null
        ? pages[_currentIndex]
        : DoctorDetailsScreen(
            doctor: _selectedDoctor!,
            repository: widget.repository,
            onBack: () => setState(() => _selectedDoctor = null),
          );

    return Scaffold(
      body: body,
      bottomNavigationBar: _selectedDoctor != null
          ? null
          : NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) => setState(() => _currentIndex = index),
              destinations: const [
                NavigationDestination(icon: Icon(Icons.home_outlined), label: 'الرئيسية'),
                NavigationDestination(icon: Icon(Icons.search), label: 'بحث'),
                NavigationDestination(icon: Icon(Icons.calendar_month_outlined), label: 'مواعيدي'),
                NavigationDestination(icon: Icon(Icons.medical_information_outlined), label: 'السجل'),
                NavigationDestination(icon: Icon(Icons.person_outline), label: 'حسابي'),
              ],
            ),
    );
  }

  void _openDoctor(Doctor doctor) => setState(() => _selectedDoctor = doctor);
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.repository,
    required this.onOpenDoctor,
    required this.onSearch,
  });

  final NabdaRepository repository;
  final ValueChanged<Doctor> onOpenDoctor;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<List<Doctor>>(
        future: repository.getDoctors(),
        builder: (context, snapshot) {
          final doctors = snapshot.data ?? const <Doctor>[];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('أهلاً بك، احجز موعدك بسهولة', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                readOnly: true,
                onTap: onSearch,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'ابحث عن طبيب أو تخصص',
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: NabdaTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('احجز خلال دقيقة', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 6),
                    Text('أفضل الأطباء الأقرب إليك، والدفع نقداً داخل العيادة.', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Wrap(
                spacing: 8,
                children: [
                  Chip(label: Text('باطنية')),
                  Chip(label: Text('أطفال')),
                  Chip(label: Text('قلبية')),
                  Chip(label: Text('جلدية')),
                ],
              ),
              const SizedBox(height: 18),
              const Text('أفضل الأطباء القريبين', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
              const SizedBox(height: 10),
              ...doctors.map(
                (doctor) => Card(
                  color: Colors.white,
                  child: ListTile(
                    onTap: () => onOpenDoctor(doctor),
                    title: Text(doctor.fullName),
                    subtitle: Text('${doctor.specialty} • ${doctor.distanceKm} كم'),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class SearchDoctorsScreen extends StatefulWidget {
  const SearchDoctorsScreen({
    super.key,
    required this.repository,
    required this.onOpenDoctor,
  });

  final NabdaRepository repository;
  final ValueChanged<Doctor> onOpenDoctor;

  @override
  State<SearchDoctorsScreen> createState() => _SearchDoctorsScreenState();
}

class _SearchDoctorsScreenState extends State<SearchDoctorsScreen> {
  String _specialty = '';
  bool _availableToday = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              onChanged: (value) => setState(() => _specialty = value),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'التخصص (مثل: قلبية)',
              ),
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              value: _availableToday,
              title: const Text('متاح اليوم فقط'),
              onChanged: (value) => setState(() => _availableToday = value),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: FutureBuilder<List<Doctor>>(
                future: widget.repository.getDoctors(
                  specialty: _specialty,
                  availableTodayOnly: _availableToday,
                ),
                builder: (context, snapshot) {
                  final doctors = snapshot.data ?? const <Doctor>[];
                  if (doctors.isEmpty) return const Center(child: Text('لا توجد نتائج مطابقة')); 
                  return ListView.builder(
                    itemCount: doctors.length,
                    itemBuilder: (context, index) {
                      final doctor = doctors[index];
                      return Card(
                        color: Colors.white,
                        child: ListTile(
                          onTap: () => widget.onOpenDoctor(doctor),
                          title: Text(doctor.fullName),
                          subtitle: Text('${doctor.specialty} • ${doctor.clinic}'),
                          trailing: Text('⭐ ${doctor.rating.toStringAsFixed(1)}'),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DoctorDetailsScreen extends StatefulWidget {
  const DoctorDetailsScreen({
    super.key,
    required this.doctor,
    required this.repository,
    required this.onBack,
  });

  final Doctor doctor;
  final NabdaRepository repository;
  final VoidCallback onBack;

  @override
  State<DoctorDetailsScreen> createState() => _DoctorDetailsScreenState();
}

class _DoctorDetailsScreenState extends State<DoctorDetailsScreen> {
  DateTime? _slot;
  final _reasonController = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _confirmBooking() async {
    if (_slot == null) {
      _show('اختر موعداً أولاً');
      return;
    }

    setState(() => _busy = true);
    try {
      await widget.repository.bookAppointment(
        doctorId: widget.doctor.id,
        patientId: 'mock-patient',
        scheduledAt: _slot!,
        reason: _reasonController.text.trim(),
      );
      if (!mounted) return;
      _show('تم إرسال طلب الحجز بنجاح');
      widget.onBack();
    } catch (e) {
      _show(e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _show(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final doctor = widget.doctor;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              IconButton(onPressed: widget.onBack, icon: const Icon(Icons.arrow_back)),
              const SizedBox(width: 8),
              const Text('ملف الطبيب', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          Card(
            color: Colors.white,
            child: ListTile(
              title: Text(doctor.fullName),
              subtitle: Text('${doctor.specialty} • ${doctor.clinic}\n${doctor.bio}'),
              isThreeLine: true,
              trailing: Text('⭐ ${doctor.rating.toStringAsFixed(1)}'),
            ),
          ),
          const SizedBox(height: 12),
          const Text('اختر الوقت', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: doctor.timeSlots
                .map(
                  (slot) => ChoiceChip(
                    selected: _slot == slot,
                    label: Text(DateFormat('E dd/MM • HH:mm', 'ar').format(slot)),
                    onSelected: (_) => setState(() => _slot = slot),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _reasonController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'سبب الزيارة',
              hintText: 'اكتب وصفاً مختصراً للحالة',
            ),
          ),
          const SizedBox(height: 12),
          Card(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('تأكيد الحجز', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text('سعر الكشف: ${doctor.feeIqd} IQD'),
                  const SizedBox(height: 6),
                  const Text('طريقة الدفع الحالية: نقداً داخل العيادة (MVP)'),
                  const SizedBox(height: 6),
                  const Text('سيتم إضافة ZainCash و Qi Card لاحقاً.'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _busy ? null : _confirmBooking,
            child: const Text('تأكيد الموعد'),
          ),
        ],
      ),
    );
  }
}

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key, required this.repository});

  final NabdaRepository repository;

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  Future<void> _cancel(Appointment appointment) async {
    await widget.repository.cancelAppointment(appointment.id);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<List<Appointment>>(
        future: widget.repository.getAppointments(),
        builder: (context, snapshot) {
          final appointments = snapshot.data ?? const <Appointment>[];
          final upcoming = appointments.where((a) => a.isUpcoming).toList();
          final history = appointments.where((a) => !a.isUpcoming).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('مواعيدي', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text('قادمة'),
              ...upcoming.map(
                (a) => Card(
                  color: Colors.white,
                  child: ListTile(
                    title: Text(a.doctor.fullName),
                    subtitle: Text(DateFormat('yyyy/MM/dd - HH:mm', 'ar').format(a.scheduledAt)),
                    trailing: TextButton(onPressed: () => _cancel(a), child: const Text('إلغاء')),
                  ),
                ),
              ),
              if (upcoming.isEmpty)
                const Card(color: Colors.white, child: Padding(padding: EdgeInsets.all(12), child: Text('لا توجد مواعيد قادمة'))),
              const SizedBox(height: 10),
              const Text('سابقة'),
              ...history.map(
                (a) => Card(
                  color: Colors.white,
                  child: ListTile(
                    title: Text(a.doctor.fullName),
                    subtitle: Text(DateFormat('yyyy/MM/dd - HH:mm', 'ar').format(a.scheduledAt)),
                    trailing: Text(_statusLabel(a.status)),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _statusLabel(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return 'قيد الانتظار';
      case AppointmentStatus.confirmed:
        return 'مؤكد';
      case AppointmentStatus.completed:
        return 'مكتمل';
      case AppointmentStatus.cancelled:
        return 'ملغي';
      case AppointmentStatus.noShow:
        return 'لم يحضر';
    }
  }
}

class RecordsScreen extends StatelessWidget {
  const RecordsScreen({super.key, required this.repository});

  final NabdaRepository repository;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<List<MedicalRecord>>(
        future: repository.getMedicalRecords(),
        builder: (context, snapshot) {
          final records = snapshot.data ?? const <MedicalRecord>[];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('السجل الطبي', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...records.map(
                (record) => Card(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(record.clinic, style: const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text('${record.doctorName} • ${DateFormat('yyyy/MM/dd', 'ar').format(record.date)}'),
                        const SizedBox(height: 8),
                        Text(record.summary),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: record.attachments
                              .map((a) => Chip(label: Text(a), avatar: const Icon(Icons.attach_file, size: 16)))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Text('حسابي', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          ListTile(tileColor: Colors.white, leading: Icon(Icons.person_outline), title: Text('البيانات الشخصية')),
          SizedBox(height: 8),
          ListTile(tileColor: Colors.white, leading: Icon(Icons.payments_outlined), title: Text('طرق الدفع')),
          SizedBox(height: 8),
          ListTile(tileColor: Colors.white, leading: Icon(Icons.notifications_outlined), title: Text('الإشعارات')),
          SizedBox(height: 8),
          ListTile(tileColor: Colors.white, leading: Icon(Icons.language_outlined), title: Text('اللغة')),
          SizedBox(height: 8),
          ListTile(tileColor: Colors.white, leading: Icon(Icons.support_agent_outlined), title: Text('الدعم الفني')),
        ],
      ),
    );
  }
}
