# himars_system

ريسوورس FiveM يضيف نظام HIMARS/MLRS بواجهة عسكرية، مع مسار صاروخ فعلي (Arc) من القاذفة إلى الهدف.

## المميزات
- أمر `/mlrs` لفتح لوحة التحكم.
- استهداف نقطة الـ Waypoint على الخريطة.
- تحريك القاذفة تلقائيًا إلى نقطة تمركز قبل الإطلاق.
- **Countdown** قبل بدء الرشقة مع Marker على الهدف.
- **مسار صاروخ حقيقي** (Bezier Arc) يظهر وهو يطلع لفوق وينزل على الهدف.
- **Cooldown / إعادة تلقيم** بعد كل ضربة (افتراضي 90 ثانية).
- تحقق صلاحيات `ACE` عبر `mlrs.use` + حد أقصى للمدى.

## الملفات المطلوبة للموديل
ضع الملفات التالية داخل مجلد `stream/`:
- `chernobog.yft`
- `chernobog_hi.yft`
- `chernobog.ytd`
- `chernobog_hi.ytd`
- `w_lr_himars.ydr`
- `w_lr_himars.ytd`

> موديل الصاروخ المستخدم في السكربت هو: `w_lr_himars`.

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
7. راقب العد التنازلي والـMarker ثم انطلاق الصواريخ.

## إعدادات مهمة (Server)
داخل `server.lua` تقدر تعدل:
- `COUNTDOWN_MS` مدة العد التنازلي.
- `COOLDOWN_SEC` مدة إعادة التلقيم.
- `MAX_RANGE` أقصى مدى مسموح.
- `MIN_FLIGHT_MS` و `MAX_FLIGHT_MS` وقت طيران الصاروخ.

## ملاحظات
- إذا ما ظهرت الضربة، تأكد أن اللاعب عنده صلاحية `mlrs.use`.
- إذا كانت النقطة بعيدة جدًا عن الحد المسموح، السيرفر سيرفض الطلب.
- إذا غيرت اسم موديل المركبة، عدّل `launcherModel` داخل `client.lua`.
- إذا غيرت موديل الصاروخ، عدّل `missileModel` داخل `client.lua`.

## مكان وضع موديل الصاروخ (مهم)
ضع ملفات الموديل داخل هذا المسار بالضبط:

```
himars_system/stream/
```

مثال:
- `himars_system/stream/w_lr_himars.ydr`
- `himars_system/stream/w_lr_himars.ytd`

إذا ما كان مجلد `stream` موجود، تم إضافته الآن داخل الريسورس.
