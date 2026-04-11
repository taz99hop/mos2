# Resistance Full System (QBCore)

نظام متكامل وخيالي متقدم لفصيل **المقاومة** على FiveM باستخدام:
- `QBCore`
- `qb-target`
- `qb-menu`
- `qb-input`
- ProgressBar + Animations
- تحقق أمني Server-Side

## المزايا المنفذة

- وظيفة سرية باسم `resistance` مع نظام رتب وصلاحيات.
- نقاط تصنيع متعددة عبر `qb-target`:
  - ورشة أسلحة
  - طاولة إلكترونيات
  - مختبر مواد
- نظام صواريخ Gameplay خيالي:
  - تفجيري
  - تشويش
  - دخاني
  - Countdown + Cooldown + Police Blip
- نظام مخازن (stash) بكود دخول وحماية رتبية.
- كراج خاص بالمقاومة مع مركبات حسب الرتبة.
- نظام مناطق وسيطرة (بداية نظام حرب قابل للتوسعة).
- لوحة قائد (إعلانات + بيان سينمائي + الصواريخ).
- نظام "بيان القائد" السينمائي (شاشة سوداء + صورة + نص + صوت).
- نظام إشعارات عامة.
- نظام Heat (منخفض / متوسط / عالي / طوارئ) مع زيادة حسب النشاط.
- أساسيات الأمان: Token validation + rank checks + item checks + anti-abuse.

## الملفات

- `fxmanifest.lua`
- `config.lua`
- `shared/permissions.lua`
- `client/main.lua`
- `client/targets.lua`
- `client/ui.lua`
- `server/main.lua`
- `web/index.html`

## التركيب

1. انسخ المجلد إلى `resources/[local]/resistance_full_system`.
2. تأكد من توفر الموارد:
   - qb-core
   - qb-target
   - qb-menu
   - qb-input
   - oxmysql (اختياري هنا ولكن مضاف في manifest)
3. أضف في `server.cfg`:
   ```cfg
   ensure resistance_full_system
   ```
4. أضف وظيفة المقاومة إلى `qb-core/shared/jobs.lua` أو قاعدة بيانات الوظائف حسب إعداد سيرفرك.

## تعريف الوظيفة (مثال jobs.lua)

> اضبطه حسب إصدار QBCore عندك.

```lua
['resistance'] = {
    label = 'Resistance',
    defaultDuty = true,
    offDutyPay = false,
    grades = {
        ['0'] = { name = 'recruit', payment = 50 },
        ['1'] = { name = 'operative', payment = 80 },
        ['2'] = { name = 'commander', payment = 120 },
        ['3'] = { name = 'leader', payment = 180, isboss = true },
    }
}
```

## أوامر مهمة

- `/resinvite [id]` (القائد فقط)
- `/reskick [id]` (القائد فقط)
- `/resleader` (فتح لوحة القائد)
- `/rescapture [zoneId]` (عنصر+)
- `/resraid [warehouseId]` (الشرطة)
- `/reswanted [citizenid] [reason]` (قائد ميداني+)
- `/resheat` (عرض الحرارة محليًا)

## التخصيص

كل شيء تقريبًا قابل للتعديل من `config.lua`:
- مواقع ونقاط التفاعل
- وصفات التصنيع
- صلاحيات الرتب
- إعدادات الصواريخ
- كود المخازن
- المركبات
- المناطق والبونص
- حدود نظام الحرارة

## ملاحظات الأمان

- لا يوجد إعطاء عناصر/أفعال حساسة من العميل دون تحقق على السيرفر.
- التحقق من الرتبة + الوظيفة + المواد المطلوبة + المسافة + الكولداون.
- استخدام token بسيط للأحداث (يمكن ترقيته إلى نظام توقيع ديناميكي).

## تطوير إضافي مقترح

- ربط مباشر مع نظام الراديو (pma-voice) لتعطيل القنوات فعليًا أثناء التشويش.
- نظام Capture متقدم يعتمد عدد اللاعبين داخل المنطقة مع Progress حي.
- حفظ حالة المناطق والحرارة في قاعدة البيانات.
- سجل أمني (audit log) لكل نشاط قيادي.
