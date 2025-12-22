# CVarMaster Changelog

## [1.1.0] - 2025-12-23

### Added
- Human-readable display names for all 893 CVars
- CVars now show friendly names like "Camera FOV Smooth Speed" instead of raw syntax
- Complete tooltip descriptions for all CVars

### Improved
- Alphabetically sorted CVar entries for easier maintenance
- Better acronym handling (FOV, SSAO, NPC, etc.)

# Changelog

## [1.0.1] - 2024-12-22

### Bug Fixes
- **Fixed category override bug** - CVarMappings category assignments now properly apply to CVars that were already cached from KnownCVars. Previously, explicit category mappings were being ignored for CVars discovered during the initial scan.

### Improvements
- **FFX CVars categorized to Graphics** - ffxGlow, ffxNether, ffxDeath, ffxAntiAliasingMode, ffxRectangle now correctly appear in the Graphics tab
- **Network CVars expanded** - Added explicit mappings for useIPv6, disableServerNagle, disableAutoRealmSelect, gxFixLag, gxMaxFrameLatency, initialRealmListTimeout, serverAlert
- **gxMaxFrameLatency moved to Graphics** - Frame latency is a graphics setting, not network
- **Improved pattern matching** - Network category patterns expanded for better auto-detection of future CVars

## [1.0.0] - 2024-12-21

### Initial Release
- Full CVar scanning and categorization
- Basic and Advanced viewing modes
- Profile management (save/load CVar configurations)
- Search and filtering
- Modified CVar highlighting
- Danger level warnings
- Combat protection detection
