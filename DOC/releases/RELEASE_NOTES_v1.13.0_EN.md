# ABProfileManager v1.13.0

Midnight Season 2 update — `Curse of Ula'tek`, WoW patch `12.1.0`.

Everything in the addon that depended on the season has been updated: item levels, crests, the Mythic+ dungeon list, BIS recommendations, stat priorities, profession knowledge, and the map overlay.

## What's New

**Season 2 item levels**

The drop item level window now uses Season 2 values throughout. Upgrade track caps are Adventurer `282`, Veteran `295`, Champion `308`, Hero `321`, and Myth `334`. Season 2 has no Explorer track, so that row is gone.

**Mistcrests**

The `My Crests` panel tracks the five Season 2 crest currencies and shows how many you hold of each.

**Season 2 Mythic+ dungeons**

Altar of Fangs, Den of Nalorakk, Murder Row, The Blinding Vale, Voidscar Arena, Kings' Rest, Ruby Life Pools, and Temple of Sethraliss.

**BIS recommendations rebuilt**

The BIS list was rebuilt from scratch for Season 2. Every entry is a Season 2 item, so nothing in the list is unobtainable this season. The list is shorter than before because only verified data is used.

Each slot now shows up to three ranked candidates — four for rings and trinkets — instead of cutting the list short.

**Stat priorities refreshed**

All 40 specializations were rechecked against the current Season 2 guides. Outlaw Rogue and Restoration Shaman were corrected.

**Profession knowledge**

The new patch 12.1 renown books from Zul'jarra's Forces are now tracked for all 11 professions. Each profession's renown reward total goes from 10 to 20 points, and the tracker counts them automatically once you use the book.

**Map overlay**

Season 2 dungeon, raid, and Delve entrances now appear on the world map, including on the older zone maps.

**Mythic+ item previews are back**

Hovering a Mythic+ entry now shows the real Season 2 item level and the real stats for the Myth 1/6 `318` track, not just a label. The selector this needs was confirmed in game, so automatic scoring is on again and the list orders Mythic+ candidates by their actual stats.

**Faster and lighter**

A full memory pass went through the addon. Several paths that only ever grew are now bounded, and the busiest paths allocate far less.

- Action bar ghost markers, the BIS item cache, and the window-move hooks used to accumulate for as long as you stayed logged in.
- Combat-time work dropped: unit events are now filtered at the source, and the stats overlay stopped rebuilding the same tables dozens of times per refresh.
- The map overlay, the BIS list, and the profession screen no longer recompute the same values on every redraw.

## Fixes

**Mythic+ season record overlay**

The overlay is working again. Dungeon names now always appear on the group finder's Mythic+ tab, with your `+level score` added when you have a record for that dungeon.

**Adventure Guide navigation**

Clicking a BIS item now opens the Adventure Guide at the right dungeon or raid and jumps to the boss that drops it. Source labels read `Dungeon · Boss`. After the first time you open the BIS window, boss names appear instantly on later logins.

**Drop item level window**

The crest and key strip at the bottom no longer overlaps the table on any tab. Body text is larger, the window is wider to match, and today's Bountiful Delve name is shown directly at the bottom instead of only in a tooltip.

**Tooltip reference step**

The BIS tooltip has a step selector in its header — Myth 1/6, Myth 6/6, Hero 6/6, and Champion 6/6. Changing it updates the reference line in the tooltip. Crafted items show their crafting range instead.

**Profession weekly quests**

Four weekly quest variants were missing from the tracker — one each for Enchanting, Herbalism, Mining, and Skinning. If your week rolled one of those, the tracker never marked it complete. All four are in now.

**World event data**

The world event names, zones, and timings were still Season 1 values and were all wrong for Season 2. They have been corrected. This overlay is still turned off, so nothing changes on screen yet.

## English and Russian

If you use the addon in English or Russian, several messages used to appear in Korean no matter which language you picked. They now follow your language setting:

- Command help, the copy window, and the log window
- Warband Bank messages
- Default template names
- Profession objective names
- Status message prefixes (`Info` / `Success` / `Failure`)

Status messages also show the correct `Success` or `Failure` label again instead of always saying `Info`.

**Russian is complete**

The Russian translation had 143 missing strings. They are all filled in — action bar results, ghost marker messages, command help, the stat priority table, and the BIS tooltip.

One Russian substitution was also matching inside longer words, so `Critical Strike` came out mangled. Replacements now only match whole words.

## Known Limitations

- Raid, tier, and crafted preview tooltips still fall back to the plain item link. The data needed to build exact previews for those three has not been confirmed yet, and showing an unverified value would display the wrong item level. Mythic+ previews are confirmed and working.
- Delve and Mythic+ item levels come from published guides. They match every source that was checked, but they have not been measured in game yet.
- Heroic dungeon Great Vault item level is not confirmed.
- The world event overlay is still turned off. Its data is correct now, but the event timings have not been measured in game.
- BIS entries are a reference. Always confirm your gear in game.

## Installing

Extract the package so the folder lands here:

```text
World of Warcraft\_retail_\Interface\AddOns\ABProfileManager\
```

Type `/abpm` in game to open the main window.
