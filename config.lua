Config = {}

Config.ItemName = 'panic_device'
Config.UseDurationMs = 2500
Config.UpdateIntervalMs = 2000
Config.AcceptKey = 38 -- E
Config.AcceptTimeoutMs = 15000
Config.AutoCancelOnDeath = true
Config.Debug = false

Config.AlertReason = 'Panic Alert / نداء طوارئ'
Config.SendingMessage = 'جاري إرسال إشارة الطوارئ...'
Config.NewAlertMessage = '🚨 نداء طوارئ جديد - اضغط E للقبول'
Config.AcceptedByMessage = 'تم استلام نداء الطوارئ من قبل %s'
Config.YouAcceptedMessage = 'تم قبول نداء الطوارئ، تم تفعيل التتبع المباشر.'
Config.AlertClosedMessage = 'تم إنهاء نداء الطوارئ.'

Config.DispatchJobs = {
    police = true,
    ambulance = false,
}

Config.Blip = {
    Sprite = 161,
    Color = 1,
    Scale = 1.1,
    Label = 'Panic Alert',
    RouteColor = 1,
    Flash = true,
}

Config.UseAnim = {
    Dict = 'cellphone@',
    Name = 'cellphone_text_read_base',
    Flag = 49,
}

Config.Sound = {
    Enabled = true,
    Name = 'TIMER_STOP',
    Set = 'HUD_MINI_GAME_SOUNDSET',
}
