# Emergency Button (QBCore + qb-target)

## Features
- Emergency wall button for police cells using `qb-target`.
- Option visibility and usage restricted to police by default.
- Global cooldown to prevent repeated spam.
- Sends alert to all online police with temporary map blip.
- Locks configured doors via `qb-doorlock`.
- Starts alarm sound for configured duration.

## Installation
1. Put folder `emergency_button` inside your resources.
2. Ensure dependencies are running:
   - `qb-core`
   - `qb-target`
   - `qb-doorlock` (optional but required for door locking)
   - `InteractSound` (optional if `Config.Alarm.UseInteractSound = true`)
3. Add to `server.cfg`:
   ```cfg
   ensure emergency_button
   ```

## Configuration
Edit `config.lua`:
- `Config.CooldownSeconds`: cooldown between presses.
- `Config.AllowPrisoners`: allow non-police to use the button.
- `Config.TargetModels`: models that act as alarm button.
- `Config.TargetZones`: fixed coordinates for button zones.
- `Config.DoorsToLock`: qb-doorlock IDs to lock on trigger.
- `Config.Alarm.*`: sound behavior.
- `Config.Blip.*`: police alert blip settings.

## Notes
- If your `qb-doorlock` version has a different state-update event/export, update `lockDoors()` in `server.lua` to match your framework version.
