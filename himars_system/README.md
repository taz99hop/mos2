# himars_system

ريسوورس FiveM يضيف نظام قصف صاروخي بعيد المدى (MLRS) بواجهة عسكرية قديمة.

## المميزات
- أمر `/mlrs` لفتح لوحة التحكم.
- استهداف مباشر على نقطة الـ Waypoint الموجودة بالخريطة.
- تحريك القاذفة تلقائيًا إلى نقطة تمركز قبل الإطلاق.
- تحقق من صلاحية اللاعب على السيرفر عبر ACE.
- حد أقصى للمدى لتقليل الاستخدام العشوائي.

## الملفات المطلوبة للموديل
ضع الملفات التالية داخل مجلد `stream/`:
- `chernobog.yft`
- `chernobog_hi.yft`
- `chernobog.ytd`
- `chernobog_hi.ytd`
- `w_lr_himars.ydr`
- `w_lr_himars.ytd`

## الإعداد في `server.cfg`
```cfg
ensure himars_system
add_ace group.admin mlrs.use allow
add_principal identifier.fivem:YOUR_FIVEM_ID group.admin
```

> بدّل `YOUR_FIVEM_ID` بمعرفك الحقيقي.

## طريقة الاستخدام
1. سباون القاذفة (حاليًا الموديل المعتمد `chernobog`).
2. اجلس بمقعد السائق.
3. حط Waypoint على الخريطة.
4. اكتب `/mlrs`.
5. اختر:
   - عدد الصواريخ
   - مقدار الانتشار (Spread)
   - الفاصل بين الصواريخ (Interval)
6. اضغط `FIRE AT WAYPOINT`.

## ملاحظات
- إذا ما ظهرت الضربة، تأكد أن اللاعب عنده صلاحية `mlrs.use`.
- إذا كانت النقطة بعيدة جدًا عن الحد المسموح، السيرفر سيرفض الطلب.
- إذا غيرت اسم موديل المركبة، عدّل `launcherModel` داخل `client.lua`.
