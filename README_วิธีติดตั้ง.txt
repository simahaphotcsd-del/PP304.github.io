ระบบออกคำสั่งเวรยามสายตรวจ สภ.ศรีมหาโพธิ
Apps Script Web App Online v15.1 Fast Load

จุดปรับปรุงความเร็ว
- Dashboard เปิดจาก IndexedDB ในเครื่องทันที ไม่รอ Google Sheet
- Google Sheet ซิงก์ต่อหลังหน้าเว็บแสดงแล้ว
- นำข้อมูลลง IndexedDB แบบ batch แทนการเขียนทีละแถว
- SheetJS/Excel โหลดเฉพาะตอนใช้เมนูนำเข้า POLICE 4.0
- Cache ฝั่ง Apps Script 60 วินาที ลดเวลาการเปิดซ้ำหลายเครื่อง

ติดตั้ง/อัปเดต
1) เปิด Google Sheet > Extensions > Apps Script
2) แทน Code.gs ด้วย Code.gs ในชุดนี้
3) แทน index.html ด้วย index.html ในชุดนี้
4) Save
5) Deploy > Manage deployments > Edit (รูปดินสอ) > New version > Deploy
6) URL /exec เดิมใช้ต่อได้

หมายเหตุ
- ถ้าเปิดครั้งแรกของเครื่อง อาจมีการซิงก์ข้อมูลหลัง Dashboard ขึ้นแล้วเล็กน้อย
- ครั้งถัดไป Dashboard จะขึ้นจากแคชในเครื่องก่อน จึงเร็วขึ้นชัดเจน
