-- ============================================================
-- NGO কর্মপরিকল্পনা ও দৈনিক প্রতিবেদন সিস্টেম - ডেটাবেজ স্ট্রাকচার
-- এই পুরো ফাইলটি Supabase SQL Editor-এ পেস্ট করে Run করুন
-- ============================================================

-- ১. ইউজার প্রোফাইল টেবিল (auth.users এর সাথে যুক্ত)
create table profiles (
  id uuid references auth.users on delete cascade primary key,
  employee_code text unique not null,        -- ইউজার আইডি (লগইনের জন্য)
  full_name text not null,
  designation text not null check (designation in ('branch_manager','area_manager','other')),
  branch_or_area text,                        -- শাখা/এরিয়ার নাম
  phone_number text,                          -- SMS নোটিফিকেশনের জন্য (যেমন: 01712345678)
  supervisor_id uuid references profiles(id), -- কার কাছে রিপোর্ট করবে
  is_admin boolean default false,
  is_active boolean default true,
  created_at timestamptz default now()
);

-- ২. মাসিক কর্মপরিকল্পনা
create table monthly_plans (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references profiles(id) not null,
  plan_month int not null,      -- ১-১২
  plan_year int not null,
  status text default 'pending' check (status in ('pending','approved','rejected')),
  reviewed_by uuid references profiles(id),
  review_note text,
  submitted_at timestamptz default now(),
  reviewed_at timestamptz,
  unique(user_id, plan_month, plan_year)
);

-- ৩. পরিকল্পনার প্রতিটি কাজ (একটি মাসিক পরিকল্পনায় একাধিক কাজ থাকবে)
create table plan_tasks (
  id uuid default gen_random_uuid() primary key,
  plan_id uuid references monthly_plans(id) on delete cascade not null,
  task_title text not null,
  task_detail text,
  target_week int,   -- ১-৫ (মাসের কোন সপ্তাহে করার পরিকল্পনা)
  created_at timestamptz default now()
);

-- ৪. দৈনিক কাজের এন্ট্রি
create table daily_entries (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references profiles(id) not null,
  entry_date date not null,
  plan_task_id uuid references plan_tasks(id),  -- পরিকল্পনার সাথে ম্যাচ হলে (ঐচ্ছিক)
  task_title text not null,        -- পরিকল্পনায় না থাকলেও স্বাধীনভাবে লেখা যাবে
  task_description text,
  status text default 'completed' check (status in ('completed','partial','pending')),
  created_at timestamptz default now()
);

-- ৫. শাখা পরিদর্শন প্রতিবেদন
create table inspection_reports (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references profiles(id) not null,   -- কে পরিদর্শন করেছেন
  branch_name text not null,
  inspection_date date not null,
  observations text not null,
  problems_found text,
  action_taken text,      -- গৃহীত ব্যবস্থা
  recommendations text,
  follow_up_needed boolean default false,
  created_at timestamptz default now()
);

-- ============================================================
-- Row Level Security (RLS) চালু করা
-- ============================================================
alter table profiles enable row level security;
alter table monthly_plans enable row level security;
alter table plan_tasks enable row level security;
alter table daily_entries enable row level security;
alter table inspection_reports enable row level security;

-- সবাই নিজের প্রোফাইল দেখতে পারবে, অ্যাডমিন সবার প্রোফাইল দেখতে পারবে
create policy "নিজের প্রোফাইল দেখা" on profiles for select using (
  id = auth.uid()
  or supervisor_id = auth.uid()
  or exists (select 1 from profiles p where p.id = auth.uid() and p.is_admin = true)
);
create policy "অ্যাডমিন প্রোফাইল তৈরি করবে" on profiles for insert with check (
  exists (select 1 from profiles p where p.id = auth.uid() and p.is_admin = true)
);
create policy "অ্যাডমিন প্রোফাইল আপডেট করবে" on profiles for update using (
  exists (select 1 from profiles p where p.id = auth.uid() and p.is_admin = true)
  or id = auth.uid()
);

-- মাসিক পরিকল্পনা: নিজেরটা + সুপিরিয়র নিজের অধীনস্থদেরটা দেখবে
create policy "পরিকল্পনা দেখা" on monthly_plans for select using (
  user_id = auth.uid()
  or exists (select 1 from profiles p where p.id = user_id and p.supervisor_id = auth.uid())
  or exists (select 1 from profiles p where p.id = auth.uid() and p.is_admin = true)
);
create policy "নিজের পরিকল্পনা জমা দেওয়া" on monthly_plans for insert with check (user_id = auth.uid());
create policy "পরিকল্পনা আপডেট (সুপিরিয়র approve/reject)" on monthly_plans for update using (
  user_id = auth.uid()
  or exists (select 1 from profiles p where p.id = user_id and p.supervisor_id = auth.uid())
);

-- পরিকল্পনার কাজ
create policy "প্ল্যান টাস্ক দেখা" on plan_tasks for select using (
  exists (select 1 from monthly_plans mp where mp.id = plan_id and (
    mp.user_id = auth.uid()
    or exists (select 1 from profiles p where p.id = mp.user_id and p.supervisor_id = auth.uid())
  ))
);
create policy "প্ল্যান টাস্ক তৈরি" on plan_tasks for insert with check (
  exists (select 1 from monthly_plans mp where mp.id = plan_id and mp.user_id = auth.uid())
);

-- দৈনিক এন্ট্রি
create policy "দৈনিক এন্ট্রি দেখা" on daily_entries for select using (
  user_id = auth.uid()
  or exists (select 1 from profiles p where p.id = user_id and p.supervisor_id = auth.uid())
  or exists (select 1 from profiles p where p.id = auth.uid() and p.is_admin = true)
);
create policy "দৈনিক এন্ট্রি তৈরি" on daily_entries for insert with check (user_id = auth.uid());

-- পরিদর্শন প্রতিবেদন
create policy "পরিদর্শন দেখা" on inspection_reports for select using (
  user_id = auth.uid()
  or exists (select 1 from profiles p where p.id = user_id and p.supervisor_id = auth.uid())
  or exists (select 1 from profiles p where p.id = auth.uid() and p.is_admin = true)
);
create policy "পরিদর্শন তৈরি" on inspection_reports for insert with check (user_id = auth.uid());

-- ============================================================
-- প্রথম অ্যাডমিন অ্যাকাউন্ট তৈরি করার পর এই লাইনটি চালান
-- (নিচের ইমেইল/আইডি আপনার নিজের অ্যাডমিন অ্যাকাউন্টের জন্য বদলে দিন)
-- ============================================================
-- update profiles set is_admin = true where employee_code = 'ADMIN001';
