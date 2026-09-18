-- যদি আপনি ইতিমধ্যে supabase-schema.sql রান করে থাকেন এবং শুধু "গৃহীত ব্যবস্থা" কলাম যোগ করতে চান,
-- তাহলে শুধু এই একটি লাইন SQL Editor-এ রান করুন (নতুন ইনস্টলেশনে এটার দরকার নেই,
-- কারণ supabase-schema.sql-এ এটি ইতিমধ্যে যুক্ত আছে):

alter table inspection_reports add column if not exists action_taken text;
