local addonName, ns = ...

ns.Data = ns.Data or {}

-- Midnight Season 1 current-season Encounter Journal landing data.
-- Keep JournalInstanceID values here. MapID values are not valid EJ_SelectInstance inputs.
ns.Data.BISEncounterJournal = {
    verifiedDB2Build = "12.0.1.66838",
    currentSeasonJournalTierID = 505,
    currentSeasonTierIndex = 13,
    instanceIDsByDungeon = {
        ["마법학자의 정원"] = 1300,
        ["마이사라 동굴"] = 1315,
        ["제나스 지점"] = 1316,
        ["공결점 제나스"] = 1316,
        ["공결탑 제나스"] = 1316,
        ["윈드러너 첨탑"] = 1299,
        ["알게타르 아카데미"] = 1201,
        ["알게타르 대학"] = 1201,
        ["삼두정의 권좌"] = 945,
        ["하늘탑"] = 476,
        ["사론의 구덩이"] = 278,
    },
}
