# PP304 COMMAND — เปิดใช้งาน Supabase (5 พ.ย. 2569)

## สถานะปัจจุบัน
- สร้างโปรเจกต์ใหม่สำเร็จ: PP304 COMMAND
- Supabase project ID: `uirolrshzxlmoglfugjt`
- Region: Singapore (`ap-southeast-1`)
- Supabase URL: https://uirolrshzxlmoglfugjt.supabase.co
- แยกโปรเจกต์จาก Smart Meeting AI
- สร้างตารางในฐานข้อมูลจริงแล้ว 7 ตาราง: profiles, personnel, team_assignments, duty_schedules, duty_replacements, post_assignments, leaves
- เปิด RLS ทุกตาราง และตรวจ Security Advisor แล้วไม่พบคำเตือน
- ยังไม่มีบัญชีผู้ใช้/กำลังพลในโปรเจกต์ใหม่ ผู้ใช้ใหม่ถูกปิดสิทธิ์เป็นค่าเริ่มต้น
- ค่าใช้จ่ายที่ระบบ Supabase แจ้งสำหรับสร้างโปรเจกต์ ณ เวลาตรวจ: $0 USD ต่อเดือน (เป็นไปตามข้อจำกัดแผน Free)

## สิ่งที่ต้องทำต่อก่อนใช้งานจริง
1. เปิด https://supabase.com/dashboard/project/uirolrshzxlmoglfugjt/auth/users
2. ใน Authentication > Users กด Add user เพื่อสร้างผู้ดูแลด้วยอีเมลจริงและรหัสผ่านที่ปลอดภัย หรือเชิญผู้ดูแลตามกระบวนการของ Supabase
3. เปิด SQL Editor ของโปรเจกต์ PP304 COMMAND (**อย่าใช้ Smart Meeting AI**) แล้วรัน SQL ด้านล่าง โดยแทน `admin@example.org` ด้วยอีเมลบัญชีที่สร้างแล้ว:

```sql
update public.profiles
set role='admin', enabled=true
where user_id=(select id from auth.users where email='admin@example.org');
```

4. ตรวจว่าแถวใน `profiles` มี `role=admin` และ `enabled=true`
5. อัปโหลด **เฉพาะ** `index.html` และ `config.js` (สองไฟล์นี้วางโฟลเดอร์เดียวกัน) ไปยัง GitHub Pages/โฮสต์ HTTPS ของระบบ
6. ใน Supabase Authentication > URL Configuration ตั้ง Site URL และ Redirect URL ตามโดเมนจริงของเว็บไซต์
7. เปิดเว็บไซต์ ล็อกอินด้วยบัญชีผู้ดูแล แล้วเข้า "ทะเบียนกำลังพล" เพื่อเริ่มเพิ่มรายชื่อ ก่อนใช้งานเมนู "การลา"
8. ทดสอบบันทึกวันลาและปฏิทินด้วยข้อมูลสมมติ แล้วจึงนำข้อมูลจริงมาใช้ (ไม่ควรนำข้อมูลกำลังพลไปวางใน GitHub repository สาธารณะ)

## ความปลอดภัย
- `config.js` ใช้เพียง **publishable key** ซึ่งออกแบบให้ใช้ฝั่งเบราว์เซอร์ ร่วมกับ RLS
- ห้ามใส่ service_role, secret key หรือรหัสผ่านฐานข้อมูลไว้ในหน้าเว็บหรือ GitHub
- บัญชีที่มีอีเมล/รหัสผ่านแต่ยังไม่ได้เปิด `profiles.enabled=true` จะไม่เห็นข้อมูลกำลังพล
- ผู้มี role viewer อ่านได้อย่างเดียว ส่วน editor/admin บันทึกข้อมูลได้
- ควรปิด public signups และจัดการผู้ใช้งานจาก Supabase Dashboard

## การตรวจสอบที่ทำแล้ว
- ตารางทั้งหมดถูกสร้างในฐานข้อมูลจริงและเปิด RLS
- SQL ตรวจพบ anon ไม่มีสิทธิ์ SELECT ตาราง personnel
- ฐานข้อมูลมี constraint ป้องกันการลาซ้ำซ้อนในช่วงวันที่ทับกัน
- หน้าเว็บผ่านการทดสอบ mock เดิม แต่ยังไม่ได้ทดสอบล็อกอิน/บันทึกกับ Supabase จริง เนื่องจากยังไม่มีบัญชีผู้ดูแล

## ลิงก์
- Dashboard: https://supabase.com/dashboard/project/uirolrshzxlmoglfugjt
- Authentication: https://supabase.com/dashboard/project/uirolrshzxlmoglfugjt/auth/users
