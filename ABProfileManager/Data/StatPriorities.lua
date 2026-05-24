local _, ns = ...

-- WoW Midnight Season 1 / Patch 12.0.5 (2026-04-29) 기준.
-- 표 전체(영웅 특성·콘텐츠 분기 포함)는 ns.Data.StatPriorityTable 에서 확인 가능.
-- 오버레이 한 줄 표시는 분기 첫 번째(또는 가장 일반적인 PvE) 우선순위를 기본으로 사용.
ns.Data.StatPriorities = {
    WARRIOR = {
        [1] = { { "crit" }, { "haste" }, { "mastery" }, { "versatility" } }, -- 무기
        [2] = { { "haste" }, { "mastery" }, { "crit" }, { "versatility" } }, -- 분노
        [3] = { { "haste" }, { "crit" }, { "versatility" }, { "mastery" } }, -- 방어
    },
    PALADIN = {
        [1] = { { "mastery" }, { "haste", "crit" }, { "versatility" } }, -- 신성
        [2] = { { "haste" }, { "versatility" }, { "mastery" }, { "crit" } }, -- 보호 (방어 기준)
        [3] = { { "mastery" }, { "crit" }, { "haste" }, { "versatility" } }, -- 징벌
    },
    HUNTER = {
        [1] = { { "mastery" }, { "haste" }, { "crit" }, { "versatility" } }, -- 야수 (단일 기준)
        [2] = { { "crit" }, { "mastery" }, { "versatility" }, { "haste" } }, -- 사격
        [3] = { { "mastery" }, { "crit", "haste" }, { "versatility" } }, -- 생존 (Pack Leader)
    },
    ROGUE = {
        [1] = { { "crit" }, { "haste" }, { "mastery" }, { "versatility" } }, -- 암살
        [2] = { { "haste" }, { "crit" }, { "versatility" }, { "mastery" } }, -- 무법
        [3] = { { "mastery" }, { "haste" }, { "crit" }, { "versatility" } }, -- 잠행 (Deathstalker 단일)
    },
    PRIEST = {
        [1] = { { "haste" }, { "crit" }, { "mastery" }, { "versatility" } }, -- 수양 (레이드)
        [2] = { { "crit" }, { "versatility", "mastery" }, { "haste" } }, -- 신성 (레이드)
        [3] = { { "haste" }, { "mastery" }, { "crit" }, { "versatility" } }, -- 암흑
    },
    DEATHKNIGHT = {
        [1] = { { "haste" }, { "mastery", "crit", "versatility" } }, -- 혈기 (San'layn)
        [2] = { { "crit" }, { "mastery" }, { "haste" }, { "versatility" } }, -- 냉기
        [3] = { { "mastery" }, { "crit" }, { "haste" }, { "versatility" } }, -- 부정
    },
    SHAMAN = {
        [1] = { { "mastery" }, { "haste", "crit" }, { "versatility" } }, -- 정기
        [2] = { { "haste" }, { "mastery", "crit" }, { "versatility" } }, -- 고양 (Stormbringer)
        [3] = { { "crit" }, { "mastery", "versatility" }, { "haste" } }, -- 복원
    },
    MAGE = {
        [1] = { { "mastery" }, { "haste" }, { "crit" }, { "versatility" } }, -- 비전
        [2] = { { "haste" }, { "mastery" }, { "versatility" }, { "crit" } }, -- 화염
        [3] = { { "mastery" }, { "crit" }, { "haste" }, { "versatility" } }, -- 냉기
    },
    WARLOCK = {
        [1] = { { "mastery", "crit" }, { "haste" }, { "versatility" } }, -- 고통
        [2] = { { "haste", "crit" }, { "mastery" }, { "versatility" } }, -- 악마
        [3] = { { "haste" }, { "mastery" }, { "crit" }, { "versatility" } }, -- 파괴
    },
    MONK = {
        [1] = { { "versatility", "crit", "mastery" }, { "haste" } }, -- 양조 (방어 기준)
        [2] = { { "haste" }, { "crit" }, { "versatility" }, { "mastery" } }, -- 운무
        [3] = { { "haste" }, { "crit" }, { "mastery" }, { "versatility" } }, -- 풍운 (빌드 A)
    },
    DRUID = {
        [1] = { { "mastery" }, { "haste", "crit" }, { "versatility" } }, -- 조화 (Keeper of the Grove)
        [2] = { { "mastery" }, { "haste" }, { "crit" }, { "versatility" } }, -- 야성 (Druid of the Claw)
        [3] = { { "haste" }, { "versatility" }, { "crit" }, { "mastery" } }, -- 수호
        [4] = { { "haste" }, { "mastery" }, { "versatility" }, { "crit" } }, -- 회복
    },
    DEMONHUNTER = {
        [1] = { { "crit" }, { "mastery" }, { "haste" }, { "versatility" } }, -- 파멸
        [2] = { { "haste" }, { "crit" }, { "versatility" }, { "mastery" } }, -- 복수 (방어 기준)
        [3] = { { "haste" }, { "mastery" }, { "crit" }, { "versatility" } }, -- 포식 (Devourer, 단일 기준)
    },
    EVOKER = {
        [1] = { { "crit" }, { "haste" }, { "mastery" }, { "versatility" } }, -- 황폐
        [2] = { { "mastery" }, { "crit" }, { "haste" }, { "versatility" } }, -- 보존 (레이드 기준)
        [3] = { { "crit" }, { "haste" }, { "mastery" }, { "versatility" } }, -- 증강
    },
}

-- M+ 우선순위. 표에 "쐐기" 분기가 명시된 전문화만 별도 기재.
-- 그 외는 ns.Data.StatPriorities 의 기본값으로 폴백.
ns.Data.StatPrioritiesMythicPlus = {
    PRIEST = {
        [1] = { { "haste" }, { "crit" }, { "versatility" }, { "mastery" } }, -- 수양 쐐기
        [2] = { { "versatility" }, { "crit" }, { "haste" }, { "mastery" } }, -- 신성 쐐기
    },
    EVOKER = {
        [2] = { { "mastery" }, { "haste" }, { "crit" }, { "versatility" } }, -- 보존 쐐기 일부
    },
}
