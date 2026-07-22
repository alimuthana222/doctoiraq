import type { PlatformAlert, TenantClinic } from "@/types/domain";

export const tenantClinics: TenantClinic[] = [
  {
    id: "c1",
    name: "عيادة النبض التخصصية",
    subdomain: "nabd-heart",
    subscriptionTier: "free",
    appointmentsToday: 18,
    activeDoctors: 4,
  },
  {
    id: "c2",
    name: "مركز الرافدين الطبي",
    subdomain: "rafidain-care",
    subscriptionTier: "pro",
    appointmentsToday: 34,
    activeDoctors: 9,
  },
  {
    id: "c3",
    name: "عيادة أطفال بغداد",
    subdomain: "kids-baghdad",
    subscriptionTier: "free",
    appointmentsToday: 12,
    activeDoctors: 3,
  },
];

export const platformAlerts: PlatformAlert[] = [
  {
    id: "al1",
    type: "warning",
    message: "ارتفاع معدل إلغاء المواعيد في آخر 24 ساعة",
    source: "Booking Analytics",
  },
  {
    id: "al2",
    type: "info",
    message: "نجاح تنفيذ تذكيرات FCM لدفعة مواعيد الغد",
    source: "Reminder Worker",
  },
  {
    id: "al3",
    type: "error",
    message: "فشل RPC book_appointment في إحدى العيادات (محاولة تعارض)",
    source: "Database Logs",
  },
];
