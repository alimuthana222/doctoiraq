import type { AvailabilityRule, DashboardAppointment, StaffMember } from "@/types/domain";

export const todayAppointments: DashboardAppointment[] = [
  {
    id: "a1",
    patientName: "فاطمة علي",
    doctorName: "د. علي مهدي",
    specialty: "قلبية",
    scheduledAt: "2026-07-22T10:00:00+03:00",
    status: "confirmed",
  },
  {
    id: "a2",
    patientName: "حسن كريم",
    doctorName: "د. زهراء كريم",
    specialty: "أطفال",
    scheduledAt: "2026-07-22T11:30:00+03:00",
    status: "pending",
  },
  {
    id: "a3",
    patientName: "عباس يوسف",
    doctorName: "د. علي مهدي",
    specialty: "قلبية",
    scheduledAt: "2026-07-22T13:00:00+03:00",
    status: "confirmed",
  },
];

export const availabilityRules: AvailabilityRule[] = [
  { doctorName: "د. علي مهدي", day: "الأحد", start: "09:00", end: "15:00", slotDurationMinutes: 30 },
  { doctorName: "د. زهراء كريم", day: "الاثنين", start: "10:00", end: "16:00", slotDurationMinutes: 30 },
  { doctorName: "د. علي مهدي", day: "الثلاثاء", start: "09:00", end: "14:00", slotDurationMinutes: 30 },
];

export const staffMembers: StaffMember[] = [
  { id: "s1", name: "د. علي مهدي", role: "doctor", specialty: "قلبية" },
  { id: "s2", name: "د. زهراء كريم", role: "doctor", specialty: "أطفال" },
  { id: "s3", name: "سارة جواد", role: "receptionist" },
  { id: "s4", name: "أحمد قاسم", role: "admin" },
];
