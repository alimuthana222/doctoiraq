# nabda platform (zero-cost stack)

تنفيذ كامل لأساس منصة **nabda** وفق البرومت داخل المستودع، ويتضمن 3 تطبيقات تشترك بنفس backend على Supabase:

1. **Patient Mobile App (Flutter)** — داخل جذر المشروع (`lib/`)
2. **Clinic Web Dashboard (Next.js)** — `/home/runner/work/doctoiraq/doctoiraq/clinic-dashboard`
3. **Admin Portal (Next.js)** — `/home/runner/work/doctoiraq/doctoiraq/admin-portal`

---

## 1) Patient Mobile App (Flutter)

### الميزات المنفذة (MVP)
- تسجيل دخول OTP
- شاشة رئيسية + بحث سريع + تخصصات + بانر
- بحث الأطباء مع فلتر "متاح اليوم"
- ملف الطبيب + اختيار وقت + تأكيد الحجز
- مواعيدي (قادمة/سابقة) + إلغاء
- السجل الطبي
- حسابي
- RTL-first + ألوان nabda

### تشغيل التطبيق
```bash
cd /home/runner/work/doctoiraq/doctoiraq
flutter pub get
flutter run
```

### ربط Supabase الحقيقي
مرّر القيم عبر `--dart-define`:
```bash
flutter run \
  --dart-define=SUPABASE_URL=YOUR_URL \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

> بدون هذه القيم، التطبيق يعمل تلقائياً على `MockNabdaRepository` لعرض التدفق كاملاً.

---

## 2) Clinic Web Dashboard (Next.js)

المسار:
- `/home/runner/work/doctoiraq/doctoiraq/clinic-dashboard`

### ميزات الواجهة المنفذة
- لوحة جانبية بالموديولات الأساسية
- تقويم مواعيد اليوم
- إدارة أوقات عمل الأطباء
- إدارة الموظفين
- KPI cards
- Arabic RTL + ألوان nabda

### التشغيل
```bash
cd /home/runner/work/doctoiraq/doctoiraq/clinic-dashboard
npm install
npm run dev
```

---

## 3) Admin Portal (Next.js)

المسار:
- `/home/runner/work/doctoiraq/doctoiraq/admin-portal`

### ميزات الواجهة المنفذة
- إدارة العيادات (tenants)
- مراقبة عامة للنظام (alerts)
- KPI cards
- بنية جاهزة للدعم الفني المركزي
- Arabic RTL + ألوان nabda

### التشغيل
```bash
cd /home/runner/work/doctoiraq/doctoiraq/admin-portal
npm install
npm run dev
```

---

## 4) Supabase backend

### SQL schema + RLS + RPC
المسار:
- `/home/runner/work/doctoiraq/doctoiraq/supabase/schema.sql`

يتضمن:
- الجداول الأساسية: `clinics`, `staff`, `patients`, `doctor_availability`, `appointments`, `medical_records`, `payments`
- جدول `audit_logs`
- RLS على كل الجداول مع clinic isolation
- unique active slot index لمنع تعارض الحجز
- دالة `book_appointment(...)` atomic مع locking
- دالة `log_audit_event(...)`

### Edge Function (placeholder)
المسار:
- `/home/runner/work/doctoiraq/doctoiraq/supabase/functions/send-reminder/index.ts`

وظيفتها الحالية: جلب مواعيد تحتاج تذكير قبل 24 ساعة وتجهيز نقطة ربط FCM.

---

## 5) بيئة الويب (Clinic/Admin)

أنشئ `.env.local` في كل تطبيق Next.js:

```env
NEXT_PUBLIC_SUPABASE_URL=YOUR_URL
NEXT_PUBLIC_SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

بدون القيم أعلاه، كلا التطبيقين يعرضان بيانات تجريبية جاهزة.
