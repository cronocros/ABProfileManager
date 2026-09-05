# ABProfileManager Update Notes (2026-09-04)

Version `v1.13.0` / Midnight Season 2 `Curse of Ula'tek` / WoW `12.1.0`

This covers only what changes for you in game.

## What's New

**Mythic+ item previews are back**

Hovering a Mythic+ entry now shows the real Season 2 item level and the real stats
for the Myth 1/6 `318` track. Automatic scoring is on again, so Mythic+ candidates
are ordered by their actual stats.

**Faster and lighter**

- Less stutter in combat, most noticeably in a 20-player raid with the stats overlay
  turned on.
- Memory no longer keeps growing during a long session. Action bar ghost markers,
  cached BIS item info, and toggling window movement on and off were the causes.
- Clicking one checkbox no longer redraws screens you cannot see. The settings window,
  map overlay, BIS list, and profession screen all respond faster.
- Mythic+ preview data was being discarded on every login. It now persists, so
  previews appear immediately from your second login on.

## Fixes

**Profession weekly quests**

Four weekly quest variants were missing from the tracker — one each for Enchanting,
Herbalism, Mining, and Skinning. If your week rolled one of those, it never showed as
complete. All four are in now.

**Stat priority table title**

The values were Season 2, but the title and subtitle still read `Patch 12.0.5`. They
now read `Midnight Season 2` and `Wowhead Season 2 baseline`.

**Log window**

`/abpm log` opened a new window every time. It now reuses a single window and closes
with `ESC`, matching the copy window.

**Copy window**

- The macro example in the instructions could not be pasted as written. It now reads
  `ABPMCopy(text)`.
- The copy window no longer steals typing focus during combat.

**Duplicate prefix**

Seven Warband Bank and copy messages showed `[ABPM]` twice. Fixed.

**Adventure Guide notice**

The two messages shown when a BIS item cannot open the Adventure Guide appeared in
Korean regardless of your language setting. They now follow your language.

## English and Russian

**Russian is complete**

All 143 missing strings are filled in — action bar results, ghost marker messages,
command help, the stat priority table, and the BIS tooltip.

One Russian substitution was also matching inside longer words, so `Critical Strike`
came out mangled. Replacements now only match whole words.

**Status messages**

In Russian, success and failure messages always showed as `Info`. All three languages
now show the correct `Success` or `Failure` label.

**Time remaining**

The `hour` / `minute` / `second` labels were hardcoded in Korean and showed that way
in English and Russian. They now follow your language setting.

## Known Limitations

- Raid, tier, and crafted preview tooltips still fall back to the plain item link. The
  data needed to build exact previews for those has not been confirmed, and showing an
  unverified value would display the wrong item level. Mythic+ previews are confirmed
  and working.
- Delve and Mythic+ item levels come from published guides. They match every source
  that was checked, but they have not been measured in game yet.
- Heroic dungeon Great Vault item level is not confirmed.
- BIS entries are a reference. Always confirm your gear in game.
