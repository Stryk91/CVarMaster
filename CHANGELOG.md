# CVarMaster v2.1.0

## Highlights
- Updated for patch 12.0.7 (Midnight).
- New quick-access launcher: a micro-menu button + Blizzard Addon Compartment entry.
- Re-categorize any CVar yourself — single or in bulk — with overrides that persist.

## New
- Micro-menu button: left-click toggles the manager, right-click opens Theme settings,
  Shift-drag to reposition (saved between sessions); hideable.
- Addon Compartment integration — launch CVarMaster from Blizzard's addon menu.
- User category overrides: "Change Category" from the CVar detail popup, tick rows for
  bulk re-categorization, and "Reset to default" to clear. Overrides take priority over
  the built-in categorization.
- /cvm autoenforce on|off — control whether locked CVars reapply on login/zone.
- /cvm audit — diff your live client CVars against the known list.
- Safety warning: ShaderCacheMode flagged dangerous — setting 0 (cacheless) forces shader
  recompilation every zone load and can cause "Transfer Aborted" errors in arenas/dungeons.

## Updated for 12.0.7
- Interface bumped to 120007.
- Large refresh of the known-CVar database and categorization (new graphics/rendering CVars:
  CMAA2, FSR, ray-tracing client settings, Slug text rendering, M2 instancing/threading,
  GxCompat options; stale entries removed).
- Rewritten CVar descriptions — concise, with performance-impact guidance.

## Changed
- Theme panel reworked around font customization (face, size, outline, shadow). The bundled
  Kanit font is the default; if the SharedMedia_MyMedia font pack is installed, its fonts are
  added to the picker automatically.
- CVar search is now scoped to the selected category.
