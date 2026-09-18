-- যদি আপনি ইতিমধ্যে supabase-schema.sql রান করে থাকেন এবং শুধু ফোন নম্বর কলাম যোগ করতে চান,
-- তাহলে শুধু এই একটি লাইন SQL Editor-এ রান করুন (নতুন ইনস্টলেশনে এটার দরকার নেই,
-- কারণ supabase-schema.sql-এ এটি ইতিমধ্যে যুক্ত আছে):

alter table profiles add column if not exists phone_number text;
