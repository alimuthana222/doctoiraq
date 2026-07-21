# برومت بناء منصة "nabda" — Clinic Booking Platform (بنمط Doctolib)

انسخ هذا كامل واعطيه لأي AI coding assistant (Claude Code, Cursor, إلخ) عشان يبدأ يبني المشروع فعليًا.

---

## 1. نظرة عامة على المشروع

ابنيلي منصة **nabda** — منصة SaaS متعددة العيادات (Multi-tenant) تربط المرضى بالأطباء والعيادات لحجز المواعيد بسهولة، على غرار Doctolib. المنصة تتكون من 3 تطبيقات تشترك بنفس الـ backend:

1. **تطبيق المريض** (Mobile App) — Flutter، Android/iOS
2. **لوحة تحكم العيادة** (Clinic Web Dashboard) — Next.js، للأطباء والسكرتارية
3. **لوحة تحكم الأدمن** (Admin Portal) — Next.js، لإدارة كل العيادات على المنصة

السوق المستهدف: العراق (عملة IQD، دفع عبر ZainCash/Qi Card)، مع بنية قابلة للتوسع دوليًا لاحقًا (يدعم Stripe لاحقًا).

---

## 2. هوية العلامة التجارية (Design System)

اسم المنصة **nabda** (تكتب بأحرف صغيرة دائمًا) والشعار **"Healthcare begins here"**. الشعار مبني من شكل نبضة قلب (heartbeat pulse line) مدمجة بشكل يرمز لإنسان/مريض، بنقطة صغيرة فوقه ترمز للدقة والرعاية.

### الألوان (استخدمها كمتغيرات CSS / design tokens بالضبط)
| الاسم | الكود | الاستخدام |
|---|---|---|
| Primary | `#0B6E6E` | الأزرار الأساسية، الروابط، العناصر التفاعلية |
| Dark | `#102A43` | العناوين، شريط التنقل الداكن، النصوص الرئيسية |
| Accent | `#4DD3C2` | تدرجات، تمييز ثانوي، حالات "متاح" |
| Success | `#2BB673` | حالات النجاح/التأكيد |
| Light | `#F8FAFC` | خلفية عامة للتطبيق |

Gradient أساسي: من `#0B6E6E` إلى `#4DD3C2` (135deg) — يُستخدم بالبانرات الترويجية وشاشة onboarding.

### الطباعة
- الخط الأساسي (لاتيني): **Plus Jakarta Sans** بأوزان Light/Regular/Medium/SemiBold/Bold/ExtraBold.
- بما إن المحتوى بالغالب عربي (السوق عراقي)، استخدم خط عربي حديث بنفس الروح الهندسية مثل **Tajawal** أو **IBM Plex Sans Arabic** للنصوص العربية، وخلي الواجهة تدعم RTL كامل.

### نظام الأيقونات
أيقونات خطية (line icons, stroke-based) بنفس أسلوب lucide/feather: Home, Appointments (calendar), Doctors, Clinics, Calendar, Messages, Search, Notification, Profile, Medical Record, Payment.

### نبرة الصوت (Voice & Tone)
واضحة، مطمئنة، مباشرة. لغة المستخدم النهائي (مريض عادي)، مو لغة تقنية. الأخطاء تُشرح بوضوح مع حل، وليس اعتذار مبهم.

---

## 3. المعمارية التقنية (Architecture)

### مبدأ التصميم: Monolith Modular أولًا، مو Microservices من اليوم الأول
هذا مشروع لمطور/فريق صغير، فالبداية الصحيحة هي **Monolith واحد مقسم داخليًا لوحدات واضحة** (`auth/`, `booking/`, `notifications/`, `payments/`)، وكل module له حدوده الواضحة (ما تتخلط الـ queries بين الموديولات). تُفصل أي وحدة لخدمة مستقلة فقط لما تحتاج scaling فعلي مستقل — نفس الطريقة اللي بدأت فيها شركات مثل Doctolib.

### الـ Stack المطلوب
| الطبقة | التقنية | السبب |
|---|---|---|
| Patient Mobile App | **Flutter** | codebase واحد لـ Android/iOS |
| Clinic Web Dashboard | **Next.js 14 (App Router) + TypeScript** | SSR للسرعة و SEO لصفحات هبوط العيادات |
| Admin Portal | **Next.js 14 + TypeScript** | نفس تقنية لوحة العيادة |
| Backend API | **NestJS** (Node.js) | بنية enterprise واضحة: DI, modules, guards |
| Database | **PostgreSQL** (Supabase/RDS) | علاقات معقدة بين مرضى/مواعيد/أطباء/عيادات |
| Cache/Queue | **Redis** | rate limiting، جدولة، session cache |
| Realtime | **Supabase Realtime / WebSockets** | تحديث فوري لحالة الموعد (confirmed/cancelled) |
| Auth | **Supabase Auth** (أو Auth0) | لا تبني auth من الصفر |
| Payments | **ZainCash / Qi Card** (+ Stripe لاحقًا للتوسع الدولي) | السوق المحلي أولًا |
| Notifications | **Firebase Cloud Messaging + WhatsApp Business API** | تذكير المواعيد يقلل no-show |
| File Storage | **Supabase Storage / S3** | صور الأشعة، التقارير الطبية |
| Infra | **Docker + GitHub Actions (CI/CD)** | حتى لو المشروع صغير، يوفر وجع راس لاحقًا |

### High-level Components
```
Patient Mobile App (Flutter)  Clinic Web (Next.js)  Admin Portal (Next.js)
              \                     |                    /
               \                    |                   /
                  API Gateway (Kong/Nginx)
              - Rate limiting - JWT auth - Routing
                        /        |         \
             Auth Service  Booking Service  Notification Service  Payment Service
                        \        |         /        /
                     PostgreSQL (Supabase/RDS) + Redis
```

---

## 4. Database Schema (الجداول الأساسية)

ابنِ الجداول التالية بالضبط، مع كل الحقول المذكورة:

```sql
-- كل عيادة = tenant (Multi-tenancy)
clinics (
  id UUID PK,
  name TEXT,
  subdomain TEXT UNIQUE, -- clinicname.yourapp.com
  address TEXT,
  phone TEXT,
  subscription_tier TEXT, -- free/pro/enterprise
  created_at TIMESTAMPTZ
)

-- نظام موحد للأطباء والسكرتارية
staff (
  id UUID PK,
  clinic_id UUID FK -> clinics,
  role TEXT, -- 'doctor' | 'receptionist' | 'admin'
  full_name TEXT,
  specialty TEXT,
  auth_user_id UUID FK -> auth.users
)

-- المرضى (عابرين لكل العيادات، منفصلين عن staff)
patients (
  id UUID PK,
  auth_user_id UUID FK -> auth.users,
  full_name TEXT,
  phone TEXT UNIQUE,
  date_of_birth DATE,
  national_id TEXT NULLABLE
)

-- أوقات العمل المتاحة لكل طبيب
doctor_availability (
  id UUID PK,
  staff_id UUID FK -> staff,
  day_of_week INT,
  start_time TIME,
  end_time TIME,
  slot_duration_minutes INT DEFAULT 30
)

-- المواعيد (الجدول الأهم بالنظام)
appointments (
  id UUID PK,
  clinic_id UUID FK -> clinics,
  patient_id UUID FK -> patients,
  staff_id UUID FK -> staff,
  scheduled_at TIMESTAMPTZ,
  duration_minutes INT,
  status TEXT, -- pending | confirmed | completed | cancelled | no_show
  reason TEXT,
  created_at TIMESTAMPTZ,
  cancelled_reason TEXT NULLABLE
)

-- السجل الطبي (EHR مبسط)
medical_records (
  id UUID PK,
  patient_id UUID FK -> patients,
  appointment_id UUID FK -> appointments,
  notes TEXT,
  attachments JSONB, -- روابط الملفات بالـ storage
  created_by UUID FK -> staff
)

-- المدفوعات
payments (
  id UUID PK,
  appointment_id UUID FK -> appointments,
  amount_iqd NUMERIC,
  provider TEXT, -- zaincash | qicard | cash
  status TEXT, -- pending | paid | failed | refunded
  transaction_ref TEXT
)
```

### قرار معماري حرج: Row-Level Security (RLS)
كل query لازم يكون معزول بـ `clinic_id` عشان عيادة ما توصل لبيانات عيادة ثانية بالغلط. طبّق:
```sql
CREATE POLICY clinic_isolation ON appointments
USING (clinic_id = current_setting('app.current_clinic_id')::uuid);
```
هذا خط الدفاع الأول ضد data leaks بين العيادات — لا تتجاهله.

---

## 5. منطق الحجز (Booking Logic) — أهم جزء تقني

لازم تمنع الـ race condition اللي يصير لما مريضين يحاولون يحجزون نفس الـ slot بنفس الثانية:

```sql
-- Unique constraint يمنع التكرار
ALTER TABLE appointments
ADD CONSTRAINT unique_slot UNIQUE (staff_id, scheduled_at)
WHERE status != 'cancelled';

-- + Database transaction مع SELECT ... FOR UPDATE
BEGIN;
SELECT * FROM appointments
WHERE staff_id = $1 AND scheduled_at = $2
FOR UPDATE;
-- لو ما لكى صف، اعمل insert
COMMIT;
```
لا تعتمد فقط على فحص "الموعد فاضي ثم احجزه" من طرف التطبيق (application-level check) — لازم الـ database نفسه يمنع الـ duplicate.

---

## 6. تصميم الـ API (REST)

```
POST   /api/v1/auth/register
POST   /api/v1/auth/login
GET    /api/v1/clinics/:id/doctors
GET    /api/v1/doctors/:id/availability?date=2026-07-20
POST   /api/v1/appointments                    # حجز موعد
GET    /api/v1/appointments/:id
PATCH  /api/v1/appointments/:id/cancel
PATCH  /api/v1/appointments/:id/confirm         # من طرف العيادة
GET    /api/v1/patients/:id/history
POST   /api/v1/payments/initiate
POST   /api/v1/webhooks/zaincash               # callback من مزود الدفع
```

نقاط مهمة:
- **Versioning** (`/v1/`) من اول يوم — أكيد راح تغيّر الـ API لاحقًا وما تريد تكسر التطبيق القديم.
- **Idempotency keys** على endpoints الدفع والحجز، عشان لو انقطع النت وأعاد المستخدم الطلب ما يصير حجز أو دفع مكرر.

---

## 7. الأمان (Security) — نقطة حرجة بالمجال الطبي

1. **التشفير**: بيانات المرضى الحساسة (`national_id`, `medical_records.notes`) لازم تُشفّر at-rest (pgcrypto أو application-level encryption).
2. **Audit log**: أي وصول لسجل مريض لازم يتسجل (مين شاف شنو ومتى) — قانوني بأغلب الأنظمة الصحية (تشبه HIPAA بأمريكا وموازيها بمناطق أخرى)، وتوقعه ينزل بأي تدقيق مستقبلي.
3. **RBAC واضح**: دكتور يشوف مرضاه بس، سكرتيرة تشوف الجدول بدون التفاصيل الطبية، admin العيادة يشوف الكل.
4. **Rate limiting** على endpoints الحساسة (`login`, `booking`) لمنع abuse.

---

## 8. ميزات تطبيق المريض (Flutter) — الشاشات المطلوبة

1. تسجيل دخول / إنشاء حساب (رقم هاتف + OTP)
2. الرئيسية: بحث سريع، تخصصات، بانر حجز، أفضل الأطباء القريبين
3. بحث عن طبيب: فلاتر (الأقرب / متاح اليوم / التخصص)
4. الملف الشخصي للطبيب: نبذة، تقييمات، اختيار يوم ووقت الحجز (calendar + time slots)
5. تأكيد الحجز: ملخص الموعد، طريقة الدفع (ZainCash/Qi Card/نقدًا)، إجمالي السعر
6. مواعيدي: قادمة/سابقة، بحالة كل موعد (مؤكد/قيد الانتظار/ملغى/مكتمل)، إمكانية الإلغاء
7. السجل الطبي: عرض التقارير والمرفقات من زياراته السابقة
8. حسابي: البيانات الشخصية، طرق الدفع، الإشعارات، اللغة، الدعم الفني

## 9. ميزات لوحة تحكم العيادة (Next.js)

1. تقويم مواعيد اليوم/الأسبوع لكل طبيب
2. إدارة أوقات العمل والإجازات لكل طبيب (`doctor_availability`)
3. تأكيد/رفض/إعادة جدولة موعد
4. ملفات المرضى وسجلاتهم الطبية (حسب الصلاحية)
5. تقارير: معدل الحضور، الإيرادات، أكثر الأطباء طلبًا
6. إدارة الموظفين (إضافة طبيب/سكرتيرة وصلاحياتهم)

## 10. ميزات لوحة الأدمن

1. إدارة العيادات المسجلة على المنصة (tenants) وباقاتها (`subscription_tier`)
2. مراقبة عامة للنظام (usage, errors, payments)
3. دعم فني مركزي للعيادات

---

## 11. خطة التنفيذ المرحلية (Roadmap)

**Phase 1 — MVP (شهرين تقريبًا)**
- Auth (patient + clinic staff)
- CRUD للعيادات والأطباء
- الحجز الأساسي (بدون race condition handling متقدم)
- تطبيق موبايل بسيط: تصفح عيادات → حجز → إشعار تأكيد

**Phase 2 — Production-ready**
- Row-level security كامل
- نظام الدفع (ZainCash/Qi Card)
- تذكيرات WhatsApp/SMS قبل الموعد بـ24 ساعة (يقلل no-show بشكل كبير)
- Web dashboard كامل للعيادة (تقويم، تقارير، إدارة الموظفين)

**Phase 3 — Scale & Differentiate**
- سجل طبي إلكتروني مبسط (EHR)
- تحليلات للعيادة (معدل الحضور، الإيرادات، أكثر الأطباء طلبًا)
- دعم multi-branch للعيادات الكبيرة
- API عام لو تريد تكامل مع أنظمة ثالثة

---

## 12. تعليمات نهائية للـ AI

- ابدأ بـ **Monolith Modular + Postgres + RLS**. لا تفكر بـ microservices, Kubernetes, أو event-driven architecture من اليوم الأول — هذا تعقيد ما تحتاجه إلا لو عندك آلاف العيادات فعلًا.
- التزم بألوان وخط nabda بالضبط بكل الواجهات (Flutter و Next.js).
- كل شاشة أو API لازم تُبنى بالعربي أولًا (RTL) مع دعم لاحق للإنجليزية.
- طبّق الـ unique constraint + transaction locking على الحجز من أول commit، مو كـ "تحسين لاحق".
- ابدأ بـ Phase 1 من الـ roadmap فقط، ولا تبني ميزات من Phase 2/3 قبل ما يخلص Phase 1 ويشتغل end-to-end.
