# himars_system

FiveM resource that adds a military-style MLRS strike console for a launcher vehicle.

## Features
- `/mlrs` command opens a retro military UI.
- Fires salvos at the active map waypoint.
- Auto-moves launcher toward a standoff firing position.
- Server-side checks for ACE permission and max range.

## Required model files
Place these in `stream/`:
- `chernobog.yft`
- `chernobog_hi.yft`
- `chernobog.ytd`
- `chernobog_hi.ytd`
- `w_lr_himars.ydr`
- `w_lr_himars.ytd`

## server.cfg
```cfg
ensure himars_system
add_ace group.admin mlrs.use allow
add_principal identifier.fivem:YOUR_FIVEM_ID group.admin
```

## Usage
1. Spawn and drive the launcher vehicle (`chernobog`).
2. Place waypoint on map.
3. Run `/mlrs`.
4. Pick salvo settings and fire.
