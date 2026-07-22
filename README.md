# nabda Flutter MVP

تطبيق مريض (Flutter) لمنصة **nabda** مع دعم عربي/RTL وشاشات MVP الأساسية:
- OTP Login
- الرئيسية + البحث عن طبيب
- ملف الطبيب + اختيار وقت + تأكيد الحجز
- مواعيدي (قادمة/سابقة + إلغاء)
- السجل الطبي
- حسابي

## تشغيل المشروع
1. ثبّت Flutter SDK.
2. نفّذ:
   ```bash
   flutter pub get
   flutter run
   ```

## Supabase
- ملف SQL الأساسي موجود في:
  - `/home/runner/work/doctoiraq/doctoiraq/supabase/schema.sql`
- يحتوي الجداول المطلوبة + RLS + دالة RPC:
  - `book_appointment(...)`

## الربط الحقيقي
التطبيق يعمل افتراضياً بـ `MockNabdaRepository` لعرض التدفق كامل بدون backend.
للربط الحقيقي:
1. هيئ Supabase في `main.dart` عبر `Supabase.initialize(...)`.
2. استبدل `MockNabdaRepository()` بـ `SupabaseNabdaRepository(Supabase.instance.client)`.
