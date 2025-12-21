# CVarMaster Installation Guide

## Quick Install (2 Steps)

### 1. Copy Addon
```
Copy the "CVarMaster" folder to:
World of Warcraft\_retail_\Interface\AddOns\
```

### 2. Launch WoW
```
/reload
/cvm help
```

Done! 🎉

---

## Verification

1. **Check addon loaded:**
   - At character select, click "AddOns"
   - Look for "CVarMaster" in the list
   - Ensure it's checked

2. **Test in-game:**
   ```
   /cvm search camera
   ```
   You should see camera-related CVars.

---

## First Time Setup

### Recommended: Create Backup
```
/cvm backup
```
This saves all current CVar values.

### Scan CVars
```
/cvm scan
```
Builds the CVar database (happens automatically on login).

### Explore
```
/cvm search <anything>     # Find CVars
/cvm modified              # See what you've changed
/cvm get <cvar>            # Details on specific CVar
```

---

## Creating Your First Profile

### Example: Performance Profile

1. **Configure settings:**
   ```
   /cvm set graphicsQuality 2
   /cvm set renderScale 0.8
   /cvm set particleDensity 50
   /cvm set maxFPS 60
   ```

2. **Save as profile:**
   ```
   /cvm profile save "Performance"
   ```

3. **Later, load it:**
   ```
   /cvm profile load "Performance"
   ```

---

## Troubleshooting

### Addon not showing in list
- Verify folder name is exactly "CVarMaster"
- Check that `CVarMaster.toc` file exists
- Ensure you're in `_retail_` folder (not `_classic_`)

### Commands not working
- Type `/cvm` (no space) and press Enter
- Check chat log for error messages
- Try `/reload`

### CVars not found
- Run `/cvm scan` to refresh
- Some CVars are protected/hidden
- Check spelling: `/cvm get <exact-name>`

### Can't modify CVar
- CVar may be protected (e.g., `realmList`)
- Check danger level: `/cvm get <cvar>`
- Some require specific game states

---

## Uninstalling

1. Delete `CVarMaster` folder from AddOns
2. (Optional) Delete saved settings:
   - `WTF\Account\<account>\SavedVariables\CVarMaster.lua`
   - `WTF\Account\<account>\<server>\<character>\SavedVariables\CVarMaster.lua`

---

## Next Steps

- Read [README.md](README.md) for full documentation
- Try searching for specific systems: `/cvm search nameplate`
- Save profiles for different scenarios (Raid, PvP, Solo)
- Experiment safely (always `/cvm backup` first!)

---

**Happy CVar tweaking!** 🎮
