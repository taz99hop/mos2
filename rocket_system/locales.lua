Locales = {
    ar = {
        menu_title = '🎯 منصة الإطلاق',
        menu_raise_arm = '⚙️ رفع الذراع',
        menu_set_angle = '📐 ضبط الزاوية',
        menu_fire = '🚀 إطلاق صاروخ',
        menu_refill = '⛽ إعادة تعبئة',
        menu_close = '❌ إغلاق',
        menu_angle_title = '📐 اختيار الزاوية',
        angle_short = '15° - مدى قصير',
        angle_medium = '30° - مدى متوسط',
        angle_optimal = '45° - مدى أقصى (مثالي)',
        angle_far = '60° - مدى بعيد',
        angle_very_far = '75° - مدى أبعد',
        not_enough_fuel = '⛔ الوقود غير كافي',
        not_enough_ammo = '⛔ لا توجد ذخيرة',
        cooldown_active = '⏳ انتظر %s ثانية قبل الإطلاق مجدداً',
        rocket_fired = '✅ تم الإطلاق بنجاح',
        pad_created = '✅ تم إنشاء منصة إطلاق برقم %s',
        pad_removed = '✅ تم حذف منصة الإطلاق %s',
        no_pad_found = '❌ لم يتم العثور على منصة بهذا الرقم',
        no_permission = '❌ ليس لديك صلاحية هذا الأمر',
        reloaded = '✅ تمت إعادة التعبئة (وقود + ذخيرة)',
        status_title = 'Rocket System Status'
    },
    en = {
        menu_title = '🎯 Launch Platform',
        menu_raise_arm = '⚙️ Raise Arm',
        menu_set_angle = '📐 Set Angle',
        menu_fire = '🚀 Fire Rocket',
        menu_refill = '⛽ Refill',
        menu_close = '❌ Close',
        menu_angle_title = '📐 Select Angle',
        angle_short = '15° - Short range',
        angle_medium = '30° - Medium range',
        angle_optimal = '45° - Max range (optimal)',
        angle_far = '60° - Far range',
        angle_very_far = '75° - Very far range',
        not_enough_fuel = '⛔ Not enough fuel',
        not_enough_ammo = '⛔ Out of ammo',
        cooldown_active = '⏳ Wait %s seconds before firing again',
        rocket_fired = '✅ Rocket launched',
        pad_created = '✅ Launch pad created with ID %s',
        pad_removed = '✅ Launch pad %s removed',
        no_pad_found = '❌ Launch pad not found',
        no_permission = '❌ You do not have permission',
        reloaded = '✅ Refill completed (fuel + ammo)',
        status_title = 'Rocket System Status'
    }
}

Config = {}

Config.Locale = 'ar'
Config.AdminPermission = 'admin'

Config.Models = {
    base = `prop_mil_crate_01`,
    arm = `prop_rub_cont_04b`,
    launcher = `prop_missile_01`
}

Config.Explosion = {
    MaxScale = 8.0,
    FireDuration = 15000,
    SmokeDuration = 20000,
    DebrisCount = 40,
    ShockwaveRadius = 60.0,
    FireParticles = 50,
    SmokeParticles = 80
}

Config.Rocket = {
    Speed = 80.0,
    Gravity = 0.8,
    Cooldown = 30,
    ExplosionRadius = 25.0,
    DamageRadius = 15.0
}

Config.PadDefaults = {
    fuel = 100,
    ammo = 5,
    armAngle = 15,
    raised = false
}

Config.Angles = { 15, 30, 45, 60, 75 }

Config.Fire = {
    FuelPerShot = 20,
    LaunchOffset = vec3(0.0, 1.5, 1.3)
}

function _L(key, ...)
    local locale = Locales[Config.Locale] or Locales.en
    local phrase = locale[key] or key
    if select('#', ...) > 0 then
        return phrase:format(...)
    end
    return phrase
end
