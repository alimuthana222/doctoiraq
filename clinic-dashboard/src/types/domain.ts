export type AppointmentStatus = "pending" | "confirmed" | "completed" | "cancelled" | "no_show";

export type DashboardAppointment = {
  id: string;
  patientName: string;
  doctorName: string;
  specialty: string;
  scheduledAt: string;
  status: AppointmentStatus;
};

export type AvailabilityRule = {
  doctorName: string;
  day: string;
  start: string;
  end: string;
  slotDurationMinutes: number;
};

export type StaffMember = {
  id: string;
  name: string;
  role: "doctor" | "receptionist" | "admin";
  specialty?: string;
};
