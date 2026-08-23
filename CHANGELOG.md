# CVarMaster v2.2.0

## Highlights
- Updated for patch 12.1.0 "Curse of Ula'tek" (Interface 120100).
- New "Diagnostic Scripts" panel: one-click presets, toggles, params and readout widgets.
- Full 12.1 CVar catalog: 21 new CVars added with descriptions, 4 removed CVars purged.

## New
- Scripts panel (main window): PvP Performance preset, live Movement Speed and
  Disease Crit readout widgets, camera/view-distance/screenshot params, nameplate
  and chat toggles, plus utility/debug one-clicks — all safety-checked.
- "New in 12.1" category: screen narrator accessibility settings, Discord
  integration, six new nameplate CVars, ping/raid-frame options, world map
  coordinates, tooltip aura spell IDs.
- /cvm locked prune — clean up locks on CVars removed from the client.
- /cvm enforce now reports applied / not-registered counts.
- Search understands shorthand: gfx, fps, aa, np, sfx, vfx and more.

## Fixed
- Profile share/import: values or names containing ; | = no longer corrupt the
  export string round-trip; truncated paste strings are rejected instead of
  importing garbage.
- Micro-button no longer teleports off-screen after a drag without Shift.
- "Reset Font" no longer poisons the default font settings for the session.
- Protected-CVar safety check actually blocks edits now (was never firing).
- Locked CVars are no longer silently deleted when the client registers a CVar
  late (12.1 lazy registration); they're kept and flagged in /cvm locked.
- Editing a CVar no longer flips its category to "Other" until the next rescan.
- Fixed duplicate RenderScale entry appearing twice in lists.
- Chat Timestamps toggle now sets a real HH:MM format.
- Font settings fall back to the bundled font if a saved font's addon was removed.
- ESC now closes the CVar description popup.
- Combat-protection warnings updated for the renamed friendly-nameplate CVars.

## Changed
- Auto-enforce hardening: stays silent on login paths, re-checks risky context
  right before applying, and retries after combat instead of skipping the session.
- Scripts window content now adapts to window resizing.
