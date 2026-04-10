# qb-panicdevice

سكربت **QBCore** كامل لجهاز نداء طوارئ واقعي كـ item داخل الحقيبة.

## المميزات

- Item قابل للاستخدام باسم `panic_device`.
- أنيميشن استخدام قبل الإرسال (`cellphone@ / cellphone_text_read_base`).
- إرسال بلاغ طوارئ لكل الوظائف المسموح بها من `Config.DispatchJobs`.
- محتوى البلاغ: اسم اللاعب، `citizenid`، الإحداثيات، سبب البلاغ.
- نظام قبول البلاغ (E) وتعيين أول عسكري كـ responder.
- تتبع مباشر عبر Blip أحمر يتحدث كل ثانيتين.
- إنهاء تلقائي للبلاغ عند موت صاحب البلاغ أو خروجه.
- دعم صوت تنبيه قابل للتعديل من الكونفيق.
- `install.lua` لإضافة الـ item تلقائياً runtime ومحاولة حقنه في `qb-core/shared/items.lua`.

## الملفات

- `fxmanifest.lua`
- `config.lua`
- `client/main.lua`
- `server/main.lua`
- `install.lua`

## التثبيت

1. ضع المجلد باسم `qb-panicdevice` داخل `resources/[qb]` أو أي مكان مناسب.
2. تأكد أن `qb-core` يبدأ قبل السكربت.
3. أضف في `server.cfg`:
   ```cfg
   ensure qb-panicdevice
   ```
4. شغّل السيرفر. السكربت سيقوم بمحاولة إضافة الـ item تلقائياً.

> ملاحظة: يفضّل دائماً مراجعة `qb-core/shared/items.lua` بعد أول تشغيل للتأكد من إضافة العنصر بالشكل الصحيح.

## تخصيص الوظائف المستقبلة

من `config.lua`:

```lua
Config.DispatchJobs = {
    police = true,
    ambulance = false,
}
```

## دعم صوت مخصص لاحقاً

حالياً يوجد صوت افتراضي عبر:

```lua
Config.Sound = {
    Enabled = true,
    Name = 'TIMER_STOP',
    Set = 'HUD_MINI_GAME_SOUNDSET',
}
```

يمكنك لاحقاً ربطه مع InteractSound / xsound بسهولة بتعديل نقطة `PlayDispatchSound()` في `client/main.lua`.
