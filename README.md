# CVarMaster

WoW addon for managing console variables (CVars).

## Install

Copy `CVarMaster/` to `Interface/AddOns/`

## Commands

```
/cvm search <term>       # Find CVars
/cvm get <name>          # Show CVar details
/cvm set <name> <value>  # Change CVar (safety-checked)
/cvm reset <name|all>    # Reset to default
/cvm modified            # List changed CVars
/cvm backup              # Save current state
/cvm restore             # Restore backup
/cvm profile save <n>    # Save profile
/cvm profile load <n>    # Load profile
```

## Safety

- Dangerous CVars flagged and require confirmation
- Protected CVars blocked
- Auto-backup before bulk changes
- Warns when `/reload` needed

## Categories

Graphics, Camera, Nameplates, Combat, Interface, Audio, Network, Performance

60+ CVars mapped with friendly names. Run `/cvm search` to explore.
