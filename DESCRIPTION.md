# CVarMaster

## The Definitive Console Variable Management Tool for World of Warcraft

CVarMaster gives you **complete control** over every accessible console variable (CVar) in World of Warcraft. No more hunting through obscure slash commands or guessing at hidden settings—CVarMaster exposes the full breadth of WoW's configuration system through an intuitive interface with built-in safety features.

---

## Why CVarMaster?

World of Warcraft has **hundreds of CVars** controlling everything from camera behavior to network timing, graphics fidelity to nameplate distances. Most players never touch them. Power users dig through forums and wikis, copy-pasting console commands and hoping nothing breaks.

CVarMaster changes that:

- **Complete Enumeration**: Scans and catalogs every accessible CVar—not just the ones Blizzard documents
- **Human-Readable Names**: Transforms cryptic names like `cameraDistanceMaxZoomFactor` into "Max Camera Distance"
- **Smart Categorization**: Organizes 500+ CVars into logical groups (Graphics, Camera, Combat, Nameplates, Audio, Network, etc.)
- **Safety First**: Danger levels, protection for critical CVars, automatic backups, and reload detection
- **Profile System**: Save configurations as named profiles, switch between "Raid", "PvP", "Performance" with one command

---

## Core Features

### Complete CVar Database
- **511+ documented CVars** with descriptions, categories, and safety flags
- **Intelligent pattern matching** auto-categorizes undocumented CVars
- **Full metadata**: Current value, default value, data type, danger level
- **Reload detection**: Flags CVars that require `/reload` to take effect

### Safety System

Not all CVars are created equal. Some adjust minor preferences. Others can crash your game.

| Danger Level | Color | Description |
|--------------|-------|-------------|
| **Safe** | White | No known issues. Freely adjustable. |
| **Caution** | Orange | May cause minor visual/audio issues. Warning shown. |
| **Dangerous** | Red | Can break functionality. Confirmation required. |
| **Critical** | Dark Red | Can crash the game. Strong warning + explicit confirmation. |

**Protected CVars** (server connection, account info) are completely blocked from modification.

### Profile Management

Save your entire CVar configuration as a named profile:

```
/cvm profile save "Mythic Raid"
/cvm profile save "World PvP"  
/cvm profile save "Performance Mode"
```

Switch between them instantly:

```
/cvm profile load "Mythic Raid"
→ Loaded profile 'Mythic Raid' - 47 CVars applied
```

Profiles support:
- Per-character or account-wide storage
- Export to shareable strings (architecture ready)
- Automatic backup before bulk changes

### Backup & Recovery

Made a mistake? CVarMaster has your back:

```
/cvm backup              # Snapshot all current values
/cvm restore             # Revert to snapshot
/cvm reset <cvar>        # Reset single CVar to default
/cvm reset all           # Nuclear option: reset everything
```

---

## Commands

```
/cvarmaster (or /cvm) <command>

SEARCH & INFORMATION
  /cvm search <term>      Search CVars by name or description
  /cvm get <cvar>         Show detailed CVar information
  /cvm modified           List all CVars changed from default

MODIFICATION
  /cvm set <cvar> <val>   Set CVar value (with safety checks)
  /cvm reset <cvar>       Reset single CVar to default
  /cvm reset <category>   Reset entire category
  /cvm reset all          Reset all modified CVars

BACKUP & RESTORE
  /cvm backup             Snapshot current CVar state
  /cvm restore            Revert to snapshot

PROFILES
  /cvm profile save <n>   Save configuration as named profile
  /cvm profile load <n>   Load saved profile
  /cvm profile delete <n> Delete profile
  /cvm profile list       Show all saved profiles

UTILITY
  /cvm scan               Refresh CVar cache
  /cvm debug              Toggle debug output
  /cvm help               Show command reference
```

---

## Usage Examples

### Find All Camera Settings
```
/cvm search camera
```
```
Max Camera Distance (cameraDistanceMaxZoomFactor) = 2.6
Camera Horizontal Speed (cameraYawMoveSpeed) = 0.015
Camera Vertical Speed (cameraPitchMoveSpeed) = 0.015
Camera Water Collision (cameraWaterCollision) = 1
Action Camera Mode (ActionCam) = 0
... and more
```

### Inspect a Specific CVar
```
/cvm get nameplateMaxDistance
```
```
Nameplate View Distance
  Current: 41
  Default: 41
  Type: integer
  Range: 1-60 (estimated)
  Category: Nameplates
  Danger: Safe
  Description: Maximum distance at which nameplates are visible
```

### Optimize for Raid Performance
```
/cvm set RAIDgraphicsQuality 1
/cvm set RAIDparticleDensity 10
/cvm set nameplateMotion 0
/cvm set SpellQueueWindow 400
/cvm profile save "Raid Mode"
```

### See What You've Changed
```
/cvm modified
```
```
nameplateMaxDistance = 60 (default: 41)
cameraDistanceMaxZoomFactor = 2.6 (default: 1.9)
SpellQueueWindow = 400 (default: 400)
RAIDgraphicsQuality = 1 (default: 5)

Total modified CVars: 4
```

---

## Categories

CVarMaster organizes CVars into these categories:

- **Graphics** — Textures, shadows, particles, effects, render scale
- **Camera** — Distance, rotation speed, collision, action cam
- **Nameplates** — Distance, scaling, stacking, visibility
- **Combat** — Floating text, auto-loot, self-cast, targeting
- **Interface** — UI scale, unit frames, buff display
- **Audio** — Master, music, SFX, ambience, voice
- **Network** — Spell queue window, lag tolerance, bandwidth
- **Performance** — FPS limits, raid graphics, background FPS
- **Accessibility** — Colorblind modes, cursor size, motion reduction
- **Tooltips** — Comparison, detail level, anchor position
- **Chat** — Timestamps, filters, bubble behavior
- **Social** — Guild, friends, communities
- **Targeting** — Tab-targeting behavior, assist
- **World** — Minimap, map opacity, quest tracking
- **Controls** — Mouse sensitivity, keybind behavior

---

## Technical Details

### File Structure
```
CVarMaster/
├── Core/
│   ├── Constants.lua      # Enums and configuration
│   ├── Utils.lua          # Helper functions
│   └── Database.lua       # SavedVariables interface
├── Data/
│   ├── CVarMappings.lua   # Friendly names + widget hints
│   ├── CVarCategories.lua # Category patterns
│   ├── CVarDescriptions.lua # 511+ descriptions
│   ├── DangerousCVars.lua # Safety database
│   └── CombatProtected.lua # Combat lockdown protection
├── Modules/
│   ├── CVarScanner.lua    # Enumeration engine
│   ├── CVarManager.lua    # Get/Set/Reset operations
│   ├── ProfileManager.lua # Profile save/load
│   └── SafetyManager.lua  # Danger level enforcement
├── GUI/
│   └── (Framework ready for visual interface)
├── CVarMaster.lua         # Addon entry point
└── CVarMaster.toc         # Table of contents
```

### Performance
- **Lazy Loading**: CVars scanned on first use, not at login
- **5-Minute Cache**: Reduces repeated enumeration overhead
- **Batch Operations**: Efficient bulk changes
- **Minimal Memory**: ~2-3MB runtime footprint

### API for Other Addons
```lua
-- Check if CVar is dangerous
local level = CVarMaster.SafetyManager:GetDangerLevel("gxApi")

-- Set CVar with safety checks
local success, msg = CVarMaster.CVarManager:SetCVar("nameplateMaxDistance", 60)

-- Get CVar metadata
local info = CVarMaster.CVarScanner:GetCVarInfo("cameraDistanceMaxZoomFactor")
```

---

## Requirements

- World of Warcraft Retail (11.0+)
- No dependencies

---

## Installation

1. Download and extract to `World of Warcraft\_retail_\Interface\AddOns\`
2. Ensure folder is named exactly `CVarMaster`
3. Restart WoW or `/reload`
4. Type `/cvm help` to verify

---

## FAQ

**Q: Can this break my game?**  
A: CVarMaster has extensive safety systems. Critical CVars require confirmation, and you can always `/cvm restore` from backup. That said, some CVars can cause visual glitches or require a client restart—the addon warns you.

**Q: Do changes persist across sessions?**  
A: Most CVars persist automatically (WoW saves them). Some require `/reload` to fully apply. The addon tells you which.

**Q: Can I share my settings with friends?**  
A: Profile export is architecturally supported. Use `/cvm profile export <name>` for a shareable string.

**Q: Why can't I modify some CVars?**  
A: Certain CVars are protected by Blizzard (account security, server connection). CVarMaster respects these restrictions.

**Q: How many CVars does WoW have?**  
A: Varies by patch, but typically 600-900+. Many are developer-only or have no visible effect. CVarMaster documents 511+ user-relevant CVars.

---

## Roadmap

**v1.1** — Visual GUI (browse, search, edit without slash commands)  
**v1.2** — Profile import/export improvements, undo history  
**v2.0** — In-game CVar inspector, addon integration API

---

## Support

Found a bug? Have a suggestion? Open an issue on GitHub or leave a comment on CurseForge.

---

**Master your CVars. Master your game.**
