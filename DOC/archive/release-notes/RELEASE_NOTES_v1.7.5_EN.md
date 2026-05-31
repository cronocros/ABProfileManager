# ABProfileManager v1.7.5

Release date: `2026-05-29`

Stability release for Blizzard window movement and compact ABPM error handling. This update reduces overlap between Blizzard UIPanel windows such as the bank/warband bank, character frame, and talent frame, and records ABPM-caught errors into a session log instead of letting protected addon callbacks surface as repeated Lua popups.

Direct download: `https://github.com/cronocros/ABProfileManager/releases/download/v1.7.5/ABProfileManager-v1.7.5.zip`
Local package: `dist/ABProfileManager-v1.7.5.zip`

## Changes

### Blizzard Window Movement

- **UIPanel windows without saved positions now stay under Blizzard layout control.**
  Enabling movable Blizzard frames no longer immediately marks default UIPanel windows as user-placed.
- **Bank/warband bank frame is handled as a UIPanel frame.**
  Opening the character frame, talent frame, or another Blizzard panel while the bank is open should no longer pull the bank into the same centered stack unexpectedly.
- **Runtime UIPanel detection added.**
  Frames registered in `UIPanelWindows` use the safer UIPanel behavior even if a manual flag is missing.
- **Legacy saved positions are reset once.**
  The Blizzard frame position store moves to `layoutVersion=2` and clears old saved coordinates that may have captured bad overlapping center positions.
- **Reset behavior no longer forces UIPanel frames to center.**
  Resets clear `UserPlaced` and hand layout back to Blizzard instead.

### Error Display

- **Added a caught ABPM error log.**
  `SafeCall`, module initialization, event dispatch, settings-tab controls, and main-window tab callbacks now record caught errors into a bounded session log.
- **Use `/abpm log` or `/abpm errors`.**
  The log popup shows debug entries and caught ABPM errors. Repeated identical errors are compacted with a count.
- **Included the targeted PrivateAuras guard.**
  The guard suppresses only the known private-dispel/public-buff collision assertion path.
- **No global Lua-error suppression.**
  ABPM does not change the global `scriptErrors` CVar, so unrelated Blizzard or third-party addon errors are not hidden.

## In-Game Regression Checklist

- Enable Blizzard frame movement, then open bank/warband bank and character/talent/profession windows together.
- Drag a Blizzard frame after the one-time position reset and confirm the saved position is restored.
- Confirm the Config tab shows the caught ABPM error count.
- Confirm `/abpm log` and `/abpm errors` show debug and caught-error logs.
- Re-check any scenario that previously spammed the PrivateAuras Lua error popup.

## Upgrading from a Previous Version

- Existing action-bar templates, profession progress, and overlay settings are preserved.
- Only saved Blizzard default-window positions are reset once for layout stability.
- No settings reset is required.
