# ABProfileManager

ABProfileManager is an all-in-one in-game utility addon for action bars, profession tracking, Midnight map guidance, BIS references, drop item levels, character stats, combat text settings, and Mythic+ record overlays.

It is designed to reduce setup time, cut down weekly checklist fatigue, and keep key progression information visible without opening multiple windows or relying on external notes.

## Why Use ABProfileManager?

- Restore messy action bars after spec swaps.
- Track weekly profession points at a glance.
- Find important Midnight locations faster.
- Check BIS references, reward tracks, and drop sources in-game.
- View drop item levels, crests, and key resources in one compact panel.
- See Mythic+ season-best score info directly in the Group Finder.
- Keep your current character stats and stat priority visible while playing.

## Main Features

### Action Bar Template Management

Save, compare, and restore your action bars with precision.

- Save action bar setups by character and spec.
- Duplicate, compare, partially apply, and undo templates.
- Import and export templates for alts or sharing.
- Confirmation prompts help prevent accidental changes.
- Combat-safe retry and ghost-action cleanup help recover from protected or delayed action states.

### Profession Point Tracking

Keep weekly and one-time profession progress organized automatically.

- Tracks weekly quests, treatises, drops, and knowledge sources.
- Includes one-time treasure progress.
- Shows completed and incomplete progress clearly.
- Provides compact and detailed overlay modes.
- Supports TomTom waypoint creation for unfinished treasures.

### Midnight Map Overlay

Get location help directly on the world map.

- Displays portals, facilities, profession hubs, vendors, dungeons, and delves.
- Covers key Midnight regions including Silvermoon and surrounding zones.
- Filter categories on demand.
- Adjustable text size for better readability.

### BIS Recommendation Overlay

Reference BIS-related gear without leaving the game.

- Organized by equipment slot.
- Supports `Mythic+ / Raid / Crafted / Tier` filters.
- Shows source, content type, reward track, validation state, and filtered priority.
- Recalculates visible `Rank 1 / Rank 2 / Rank 3+` after filtering.
- Supports per-character and per-specialization Favorite / Owned tracking.
- Favorite items move into a top Favorites section.
- Owned items are marked with a strikethrough.
- Mythic+ rows can use verified `Myth 1/6 272` item snapshots.
- Raid and tier rows can use verified seasonal Myth preview tooltips.
- Crafted rows can use verified R5 `285` preview tooltips.
- Falls back to normal Blizzard item tooltips when a seasonal preview is not verified.
- Mythic+ sources can land into the Encounter Journal when supported and when out of combat.

### Drop Item Level Overlay

See reward levels and progression info in one compact view.

- Covers Mythic+, Delves, Raid, Crafted gear, and other reward references.
- Uses a compact reward layout for fast comparison.
- Includes Great Vault information.
- Right-side panels show My Crests and My Keys.
- Helps you check reward structure without tabbing out.

### Mythic+ Season-Best Overlay

See key score information where you need it.

- Displays Score + Dungeon Name directly on Mythic+ dungeon icons.
- Integrated into the Group Finder experience.
- Keeps season-best information visible without extra clicks.

### Character Stats Overlay

Keep important combat stats visible during play.

- Shows Crit, Haste, Mastery, and Versatility.
- Displays current spec stat priority.
- Includes tank defensive stats when relevant.
- Mastery hover uses the current specialization's Blizzard tooltip data.
- Avoids unsafe PaperDoll tooltip setter paths on newer WoW clients.

### Combat Text Mode Control

Manage Midnight combat text behavior more reliably.

- Supports Up / Down / Arc modes.
- Applies settings immediately.
- Reapplies the chosen mode after login or world entry.
- Includes directional variance toggle.

## Recent BIS and Tooltip Improvements

ABProfileManager has received major BIS overlay and tooltip updates after `v1.10.0`.

- Real owned `itemLink` scoring was added for BIS ordering when a valid equipped or bag link is available.
- M+ BIS hover can show verified `Myth 1/6 272` Blizzard item tooltips with real secondary stats.
- Raid, tier, and crafted rows now try validated seasonal preview links before falling back to base item links.
- The BIS item tooltip checkbox is enabled by default while preserving user choice after manual toggles.
- Encounter Journal landing was hardened to avoid protected-function popup warnings during combat.
- Tooltip and `MoneyFrame` paths were adjusted to reduce secret-number taint errors.
- BISOverlay load validation now guards against WoW Lua's main-function local variable limit.

## Built For Players Who Want

- Faster recovery after spec changes.
- Cleaner weekly profession management.
- Better in-game progression visibility.
- Less dependence on external notes or websites.
- Useful overlays with less clutter.
- Safer item tooltip behavior on modern WoW clients.

## In Short

ABProfileManager is built for players who want their UI to do more of the remembering, tracking, and organizing for them.

Instead of juggling multiple tools, windows, and notes, you get one addon focused on the information that matters while you play.
