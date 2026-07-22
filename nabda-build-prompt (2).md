# برومت بناء منصة "nabda" — Clinic Booking Platform (بنمط Doctolib)

انسخ هذا كامل واعطيه لأي AI coding assistant (Claude Code, Cursor, إلخ) عشان يبدأ يبني المشروع فعليًا.

---

## 1. نظرة عامة على المشروع

ابنيلي منصة **nabda** — منصة SaaS متعددة العيادات (Multi-tenant) تربط المرضى بالأطباء والعيادات لحجز المواعيد بسهولة، على غرار Doctolib. المنصة تتكون من 3 تطبيقات تشترك بنفس الـ backend:

1. **تطبيق المريض** (Mobile App) — Flutter، Android/iOS
2. **لوحة تحكم العيادة** (Clinic Web Dashboard) — Next.js، للأطباء والسكرتارية
3. **لوحة تحكم الأدمن** (Admin Portal) — Next.js، لإدارة كل العيادات على المنصة

السوق المستهدف: العراق (عملة IQD). المشروع بمرحلته الحالية **صفر تكلفة (Zero-cost stack)** — كل التقنيات المستخدمة لازم تكون على باقات مجانية (Free Tier)، بدون أي خدمة مدفوعة أو تحتاج بطاقة ائتمان.

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

### الـ Stack المطلوب — Supabase-first، صفر تكلفة
**لا تبني backend API منفصل بـ NestJS.** استخدم **Supabase** كـ Backend-as-a-Service كامل: قاعدة البيانات + Auth + Storage + Realtime + منطق السيرفر كله عبر Supabase مباشرة، وهذا يغطي الباقة المجانية (Free Tier) بدون بطاقة ائتمان.

| الطبقة | التقنية | السبب |
|---|---|---|
| Patient Mobile App | **Flutter** + حزمة `supabase_flutter` | يتصل بـ Supabase مباشرة، بدون backend وسيط |
| Clinic Web Dashboard | **Next.js 14 + TypeScript** + `@supabase/supabase-js` | مستضاف مجانًا على Vercel Free Tier |
| Admin Portal | **Next.js 14 + TypeScript** + `@supabase/supabase-js` | نفس الشي |
| Database | **Supabase Postgres** (Free Tier: 500MB) | علاقات معقدة بين مرضى/مواعيد/أطباء/عيادات |
| Backend Logic | **Supabase Edge Functions** (Deno، مجانية لحد 500K استدعاء/شهر) | بدل NestJS — تُستخدم فقط للمنطق اللي ما تقدر تسويه بـ RLS/Postgres Function مباشرة (مثل منع تعارض الحجز، أو webhook مستقبلي) |
| Auth | **Supabase Auth** (مجاني، يدعم OTP بالهاتف) | لا تبني auth من الصفر، ولا تحتاج Auth0 المدفوع |
| Realtime | **Supabase Realtime** (مُضمّن مجانًا) | تحديث فوري لحالة الموعد (confirmed/cancelled) |
| File Storage | **Supabase Storage** (Free Tier: 1GB) | صور الأشعة، التقارير الطبية |
| Notifications | **Firebase Cloud Messaging** (مجاني بالكامل) | تذكير المواعيد؛ لا تستخدم WhatsApp Business API حاليًا لأنها مدفوعة — أجّلها لمرحلة لاحقة لما يكون فيه دخل |
| Payments | **الدفع نقدًا بالعيادة فقط بالـ MVP** (حقل `provider = 'cash'`) | ربط ZainCash/Qi Card يحتاج حساب تاجر واعتماد رسمي — أجّله لحد ما المنصة تثبت نفسها |
| Infra/Hosting | **بدون Docker بهذي المرحلة** — Supabase مُدار بالكامل (managed)، و Next.js يُنشر مباشرة عبر Vercel Free Tier | يوفر عليك وقت DevOps بمرحلة MVP |
| CI/CD | **GitHub Actions** (مجاني لمستودعات عامة/محدود للخاصة) | اختياري بالبداية، تقدر تأجله لما يكبر الفريق |

> ملاحظة: Redis والـ API Gateway (Kong/Nginx) **محذوفون بهذي المرحلة** — Supabase توفر rate limiting أساسي و connection pooling (PgBouncer) built-in، وهذا كافي لـ MVP. أضفهم فقط لو صار عندك حمل فعلي كبير.

### High-level Components (Supabase-first)
```
Patient Mobile App (Flutter)   Clinic Web (Next.js)   Admin Portal (Next.js)
              \                        |                        /
               \                       |                       /
                        Supabase (كل شي مُدار بمكان واحد)
        ┌─────────────┬─────────────┬─────────────┬─────────────┐
        │   Auth      │  Postgres   │   Storage   │   Realtime  │
        │ (OTP/JWT)   │  + RLS      │  (ملفات)    │ (WebSocket) │
        └─────────────┴─────────────┴─────────────┴─────────────┘
                              │
                    Edge Functions (Deno)
              منطق حجز، تعارض المواعيد، تذكيرات FCM
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

بما إننا نستخدم Supabase بدون backend منفصل، لف هذا المنطق داخل **Postgres Function (RPC)** باسم `book_appointment(...)` واستدعيه من Flutter مباشرة عبر `supabase.rpc('book_appointment', params: {...})`. هذا يضمن إن الـ transaction تصير كاملة داخل قاعدة البيانات نفسها، وما تحتاج backend وسيط.

---

## 6. طبقة الوصول للبيانات (بدون REST API مخصص)

Supabase تولّد تلقائيًا REST API + client library من قاعدة البيانات نفسها، فما تحتاج تكتب endpoints يدويًا لعمليات CRUD البسيطة. استخدم الأنماط التالية من Flutter/Next.js مباشرة:

```dart
// تسجيل دخول بالـ OTP
supabase.auth.signInWithOtp(phone: phone);

// جلب أطباء عيادة معينة
supabase.from('staff').select().eq('clinic_id', clinicId).eq('role', 'doctor');

// جلب الأوقات المتاحة ليوم معين
supabase.from('doctor_availability').select().eq('staff_id', doctorId);

// حجز موعد (عبر RPC function تمنع التعارض — راجع القسم 5)
supabase.rpc('book_appointment', params: {
  'p_staff_id': doctorId, 'p_scheduled_at': slot, 'p_patient_id': patientId,
});

// إلغاء موعد
supabase.from('appointments').update({'status': 'cancelled'}).eq('id', appointmentId);
```

استخدم **Edge Functions** فقط للحالات اللي تحتاج منطق معقد أو سري (secret keys) ما ينحط بالـ client، مثل:
- `book-appointment` (لو تفضل تحطها Edge Function بدل Postgres RPC)
- `send-reminder` (استدعاء FCM لإرسال تذكير قبل الموعد بـ24 ساعة، عبر Supabase Cron/`pg_cron`)

نقاط مهمة:
- ما تحتاج API versioning يدوي بهذي المرحلة لأن Supabase تدير هذا.
- لعمليات الحجز، استخدم RPC function واحدة ذرية (atomic) بدل عدة استدعاءات متتالية، عشان تضمن الـ idempotency وتمنع الحجز المكرر لو انقطع النت.

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
5. تأكيد الحجز: ملخص الموعد، إجمالي السعر، **الدفع نقدًا بالعيادة فقط بالـ MVP** (اترك مكان بالتصميم لإضافة ZainCash/Qi Card لاحقًا بدون إعادة بناء الشاشة)
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

**Phase 1 — MVP (شهرين تقريبًا) — كله على Supabase Free Tier**
- Auth بالـ Supabase (patient + clinic staff) عبر OTP
- CRUD للعيادات والأطباء مباشرة على Postgres
- الحجز عبر RPC function واحدة تمنع تعارض المواعيد من أول commit (القسم 5)
- الدفع نقدًا بالعيادة فقط (بدون بوابة دفع)
- تطبيق موبايل بسيط: تصفح عيادات → حجز → إشعار تأكيد (FCM المجاني)

**Phase 2 — Production-ready (لسا مجاني)**
- Row-level security كامل على كل الجداول
- تذكيرات FCM قبل الموعد بـ24 ساعة عبر `pg_cron` + Edge Function (يقلل no-show، بدون تكلفة)
- Web dashboard كامل للعيادة (تقويم، تقارير، إدارة الموظفين) على Vercel Free Tier
- Audit log للوصول لسجلات المرضى

**Phase 3 — أول ما يصير فيه دخل فعلي من العيادات**
- ربط ZainCash/Qi Card (يحتاج حساب تاجر — أول تكلفة حقيقية بالمشروع)
- تذكيرات WhatsApp Business API (مدفوعة)
- سجل طبي إلكتروني مبسط (EHR) وتحليلات متقدمة
- دعم multi-branch للعيادات الكبيرة، وترقية لـ Supabase Pro لو تجاوزت حدود الـ Free Tier (500MB DB / 1GB storage / 50K مستخدم نشط شهريًا)

---

## 12. تعليمات نهائية للـ AI

- **الشرط الأهم: صفر تكلفة.** استخدم Supabase فقط (Free Tier) كـ backend كامل — لا NestJS، لا Redis، لا Docker، لا أي خدمة تحتاج بطاقة ائتمان أو اشتراك مدفوع. لو احتجت أي بديل مدفوع، اذكره كـ "خيار مستقبلي" بس ولا تبنيه فعليًا.
- ابدأ بـ **Postgres + RLS + RPC functions**. لا تفكر بـ microservices, Kubernetes, أو event-driven architecture من اليوم الأول.
- الدفع بالـ MVP نقدًا بالعيادة فقط — لا تربط ZainCash/Qi Card قبل ما تنتهي من باقي المنصة.
- التزم بألوان وخط nabda بالضبط بكل الواجهات (Flutter و Next.js).
- كل شاشة أو API لازم تُبنى بالعربي أولًا (RTL) مع دعم لاحق للإنجليزية.
- طبّق الـ unique constraint + transaction locking على الحجز من أول commit عبر Postgres RPC function، مو كـ "تحسين لاحق".
- ابدأ بـ Phase 1 من الـ roadmap فقط، ولا تبني ميزات من Phase 2/3 قبل ما يخلص Phase 1 ويشتغل end-to-end.
