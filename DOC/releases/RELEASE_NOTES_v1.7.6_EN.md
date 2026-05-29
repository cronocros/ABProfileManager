# ABProfileManager v1.7.6

Release date: `2026-05-29`

Hotfix for the Stats Overlay mastery tooltip. Hovering the Mastery row now shows the current specialization's actual Mastery spell tooltip instead of the short generic fallback text.

Direct download: `https://github.com/cronocros/ABProfileManager/releases/download/v1.7.6/ABProfileManager-v1.7.6.zip`
Local package: `dist/ABProfileManager-v1.7.6.zip`

## Changes

- **Mastery tooltip now uses specialization-specific spell data.**
  ABPM resolves the current specialization's Mastery spell ID and renders Blizzard tooltip data into the overlay tooltip.
- **Still uses the addon-owned tooltip.**
  The rendering stays on `ABProfileManagerTooltip`, preserving the existing GameTooltip/MoneyFrame taint-avoidance policy.
- **Existing DR guidance remains.**
  Rating contribution and DR stage text are still appended below the Mastery description.

## In-Game Regression Checklist

- Enable the Stats Overlay and hover the `Mastery` row.
- Swap specializations and confirm the Mastery name/description changes with the spec.
- Confirm Crit/Haste/Versatility/defensive-stat tooltips and DR guidance still show as before.

## Upgrading from a Previous Version

- Saved data is unchanged.
- No settings reset is required.
