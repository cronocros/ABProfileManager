# ABProfileManager v1.13.0 Local Patch

Patch baseline date: `2026-09-04`

These notes describe the local patch package.

- Local package: `dist/ABProfileManager-v1.13.0.zip`
- Target client: WoW `12.1.0` / TOC `## Interface: 120100` / Midnight Season 2 (`Curse of Ula'tek`)
- Latest public GitHub release: `v1.11.0`
- Public GitHub direct download: `https://github.com/cronocros/ABProfileManager/releases/download/v1.11.0/ABProfileManager-v1.11.0.zip`

This release brings the addon to Midnight Season 2. It fixes the defects found during in-game QA, revalidates the seasonal data against Wowhead and the game's own client database, and cleans up English display.

## Season 2 Data

- **Item level table replaced with Season 2 values.**
  Upgrade track caps are `Adventurer 282`, `Veteran 295`, `Champion 308`, `Hero 321`, and `Myth 334`. Season 2 has no Explorer track, so that row is gone.
- **Mistcrest currencies.**
  The `My Crests` panel tracks the five Season 2 Mistcrest currencies: Adventurer, Veteran, Champion, Hero, and Myth.
- **Season 2 Mythic+ dungeon pool.**
  Altar of Fangs, Den of Nalorakk, Murder Row, The Blinding Vale, Voidscar Arena, Kings' Rest, Ruby Life Pools, and Temple of Sethraliss.
- **BIS catalog rebuilt for Season 2.**
  The catalog holds `657` rows (`raid 393`, `mythicplus 107`, `tier 79`, `crafted 78`). Every row is a Season 2 item, sourced only from verified data, so each entry is something you can actually obtain this season.
- **Stat priorities rechecked for all 40 specializations.**
  Values were compared against Wowhead's per-specialization stat priority pages. Thirty-one already matched. Restoration Shaman was updated, and Outlaw Rogue was corrected: its stored order had Haste in last place, which came from an old parsing bug, while the current source lists Haste first.
- **Profession knowledge updated for patch 12.1.**
  The new `Demystifyin': <Profession>` renown books from Zul'jarra's Forces are now tracked for all 11 professions, 10 points each. Each profession's renown reward total goes from 10 to 20 points.
- **Korean names verified against the client database.**
  Dungeon names, raid boss names, tier set names, and map aliases were all checked and already matched.

## Fixes From In-Game QA

- **Mythic+ record overlay failed to load.**
  A stray carriage return inside a string literal broke the whole file with an `unfinished string` error. The overlay module was effectively disabled.
- **Mythic+ record overlay showed nothing.**
  Season best data requires `C_MythicPlus.RequestMapInfo()` first, which the addon never called, so every lookup returned `nil`. The addon now requests the data, subscribes to the arrival events, and retries if it arrives late. Dungeon names are always shown; the score is appended when a record exists.
- **Adventure Guide navigation did not reach the boss.**
  Clicking a BIS item now opens the correct dungeon or raid and selects the encounter. Boss names are resolved from the Adventure Guide loot tables and cached in your SavedVariables, so after the first scan they appear instantly on later logins.
- **Item level window overlap.**
  The crest and key strip at the bottom overlapped the table rows on every tab. This was an anchor problem that made the content frame taller than the window.
- **BIS list showed too few candidates.**
  Slots now show up to three ranks (four for rings and trinkets), instead of silently dropping the third rank.
- **Map overlay updated for Season 2.**
  Dungeon, raid, and Delve entrances are queried from the client at runtime instead of using hardcoded coordinates. Locations that cannot be confirmed are not drawn.
- **Bountiful Delve of the day.**
  The item level window now shows today's Bountiful Delve name directly in the bottom strip instead of only in a tooltip.
- **Larger text in the item level window.**
  Row labels, values, and headers were all increased, and the window was widened to fit.

## English Display

If you run the addon in English, these strings used to appear in Korean regardless of your language setting:

- `/abpm help` entries for the Warband Bank commands
- The `/abpm copy` window title, usage text, and the log window button
- Warband Bank chat messages
- The default template name and the suffix used when duplicating a template
- Profession objective names in the profession overlay and cards
- Status message prefixes (`Info` / `Success` / `Failure`)
- The message shown when Adventure Guide navigation is blocked in combat or by a season mismatch

All of these now follow the selected language. Thirty-four new strings were added in English, Korean, and Russian.

Two related bugs were fixed along the way:

- Status messages lost their success and failure distinction in every language and always showed as `Info`.
- The stat priority window still said `Patch 12.0.5` in its title even though the table itself had been updated to Season 2 values.

## Other Fixes

- The `/abpm log` window created a new frame every time it was opened. It is now reused and closes with `Esc`.
- The copy window no longer steals keyboard focus while you are in combat.
- The macro example in the copy window used a non-ASCII placeholder that failed if you pasted it. It now reads `/run ABPMCopy(text)`.
- Chat messages no longer show the addon name twice.

## Distribution Boundary

- Local distribution stops after creating `dist/ABProfileManager-v1.13.0.zip` inside the workspace.
- The latest public GitHub release and direct download remain `v1.11.0`.

## Known Limitations

- Automatic Mythic+ item scoring and the exact seasonal item level in preview tooltips are still disabled. The Season 2 preview selector has not been confirmed in-game, and showing an unverified value would display the wrong item level. Lists, ordering, and Adventure Guide navigation work normally.
- Delve and Mythic+ item levels in the table come from published guides rather than in-game measurement. They match every published table that was checked, but they are marked as unverified in the repository until confirmed in-game.
- Heroic dungeon Great Vault item level is still unconfirmed.
- Weekly profession quest and treatise quest IDs have not been reverified for patch 12.1.

## In-Game Regression Checklist

- Confirm the addon loads with no Lua errors after `/reload`.
- Confirm the Mythic+ tab of the group finder shows dungeon names and the score overlay. If not, run `/abpm debug mplus`.
- Confirm clicking a BIS dungeon or raid item opens the Adventure Guide at the correct boss.
- Confirm none of the five tabs in the item level window overlap the bottom strip.
- Confirm Frost Death Knight shows chest armor, not a helm, in the `Chest` row.
- Confirm Outlaw Rogue's stat line starts with Haste and Restoration Shaman reads `Critical Strike > Haste = Versatility > Mastery`.
- Confirm each profession now shows 20 points available from renown books.
- Switch the addon language to English and confirm the main window, overlays, `/abpm help`, `/abpm copy`, and Warband Bank messages are all in English.
