create extension if not exists pgcrypto;

create table if not exists clinics (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  subdomain text unique not null,
  address text,
  phone text,
  subscription_tier text not null default 'free',
  created_at timestamptz not null default now()
);

create table if not exists staff (
  id uuid primary key default gen_random_uuid(),
  clinic_id uuid not null references clinics(id) on delete cascade,
  role text not null check (role in ('doctor', 'receptionist', 'admin')),
  full_name text not null,
  specialty text,
  auth_user_id uuid references auth.users(id)
);

create table if not exists patients (
  id uuid primary key default gen_random_uuid(),
  auth_user_id uuid references auth.users(id),
  full_name text not null,
  phone text unique not null,
  date_of_birth date,
  national_id text
);

create table if not exists doctor_availability (
  id uuid primary key default gen_random_uuid(),
  staff_id uuid not null references staff(id) on delete cascade,
  day_of_week int not null check (day_of_week between 0 and 6),
  start_time time not null,
  end_time time not null,
  slot_duration_minutes int not null default 30 check (slot_duration_minutes > 0)
);

create table if not exists appointments (
  id uuid primary key default gen_random_uuid(),
  clinic_id uuid not null references clinics(id) on delete cascade,
  patient_id uuid not null references patients(id) on delete cascade,
  staff_id uuid not null references staff(id) on delete cascade,
  scheduled_at timestamptz not null,
  duration_minutes int not null,
  status text not null check (status in ('pending', 'confirmed', 'completed', 'cancelled', 'no_show')),
  reason text,
  created_at timestamptz not null default now(),
  cancelled_reason text
);

create unique index if not exists unique_active_slot
  on appointments(staff_id, scheduled_at)
  where status <> 'cancelled';

create table if not exists medical_records (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references patients(id) on delete cascade,
  appointment_id uuid not null references appointments(id) on delete cascade,
  notes text,
  attachments jsonb not null default '[]'::jsonb,
  created_by uuid references staff(id)
);

create table if not exists payments (
  id uuid primary key default gen_random_uuid(),
  appointment_id uuid not null references appointments(id) on delete cascade,
  amount_iqd numeric not null check (amount_iqd >= 0),
  provider text not null check (provider in ('zaincash', 'qicard', 'cash')),
  status text not null check (status in ('pending', 'paid', 'failed', 'refunded')),
  transaction_ref text
);

alter table clinics enable row level security;
alter table staff enable row level security;
alter table patients enable row level security;
alter table doctor_availability enable row level security;
alter table appointments enable row level security;
alter table medical_records enable row level security;
alter table payments enable row level security;

create policy clinic_isolation_appointments on appointments
for all
using (clinic_id = current_setting('app.current_clinic_id', true)::uuid)
with check (clinic_id = current_setting('app.current_clinic_id', true)::uuid);

create or replace function book_appointment(
  p_staff_id uuid,
  p_patient_id uuid,
  p_scheduled_at timestamptz,
  p_reason text default null,
  p_duration_minutes int default 30
)
returns appointments
language plpgsql
security definer
as $$
declare
  v_clinic_id uuid;
  v_existing appointments;
  v_new appointments;
begin
  select clinic_id into v_clinic_id from staff where id = p_staff_id and role = 'doctor';
  if v_clinic_id is null then
    raise exception 'Doctor not found';
  end if;

  select * into v_existing
  from appointments
  where staff_id = p_staff_id
    and scheduled_at = p_scheduled_at
    and status <> 'cancelled'
  for update;

  if found then
    raise exception 'Slot already booked';
  end if;

  insert into appointments (
    clinic_id, patient_id, staff_id, scheduled_at, duration_minutes, status, reason
  )
  values (
    v_clinic_id, p_patient_id, p_staff_id, p_scheduled_at, p_duration_minutes, 'pending', p_reason
  )
  returning * into v_new;

  return v_new;
end;
$$;
