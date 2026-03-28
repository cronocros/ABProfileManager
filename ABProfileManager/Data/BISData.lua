local _, ns = ...

-- BIS 아이템 드랍 위치 데이터 (Midnight 시즌 1 쐐기 던전)
--
-- 키: specID (GetSpecializationInfo 반환값, 글로벌 고유)
-- 값: { dungeon, boss, itemID, slot, note } 배열
--
-- specID 참조:
--   전사:   71=무기, 72=분노, 73=방어
--   성기사: 65=신성, 66=방어, 70=징벌
--   사냥꾼: 253=야수, 254=사격, 255=생존
--   도적:   259=암살, 260=무법, 261=잠행
--   사제:   256=수양, 257=신성, 258=암흑
--   죽기:   250=혈기, 251=냉기, 252=부정
--   주술:   262=정기, 263=고양, 264=복원
--   마법사: 62=비전, 63=화염, 64=냉기
--   흑마:   265=고통, 266=악마, 267=파괴
--   수도사: 268=양조, 269=풍운, 270=운무
--   드루:   102=조화, 103=야성, 104=수호, 105=회복
--   악사:   577=파멸, 581=복수
--   용기:   1467=황폐, 1468=보존, 1473=증강
--
-- 던전 목록 (시즌 1):
--   마법학자의 정원 (Magisters' Terrace)
--   마이사라 동굴 (Maisara Caverns)
--   공결점 제나스 (Nexus-Point Xenas)
--   윈드러너 첨탑 (Windrunner Spire)
--   알게타르 아카데미 (Algeth'ar Academy)
--   삼두정의 권좌 (Seat of the Triumvirate)
--   하늘탑 (Skyreach)
--   사론의 구덩이 (Pit of Saron)
--
-- itemID 는 WoW 아이템 ID (wowhead.com 에서 확인)
-- note: "BIS" / "대체재" / "2순위" 등
--
-- 데이터 갱신 시 해당 specID 의 배열만 교체하면 됨
-- 빈 배열 {} 이면 "데이터 없음" 메시지 표시

ns.Data = ns.Data or {}
ns.Data.BISItems = {

    -- ============================================================
    -- 전사 (Warrior)
    -- ============================================================

    -- 무기 전사 (Arms) — 71
    [71] = {
        { dungeon = "공결점 제나스",     boss = "로스라시온",       itemID = 250241, slot = "장신구", note = "BIS" },
        { dungeon = "윈드러너 첨탑",     boss = "안식 없는 심장",   itemID = 250256, slot = "장신구", note = "BIS" },
        { dungeon = "알게타르 아카데미", boss = "도라고사의 메아리", itemID = 193701, slot = "장신구", note = "대체재" },
        { dungeon = "삼두정의 권좌",     boss = "사프리시",         itemID = 151307, slot = "장신구", note = "대체재" },
        { dungeon = "마법학자의 정원",   boss = "데젠트리우스",     itemID = 251117, slot = "무기",   note = "BIS" },
        { dungeon = "마법학자의 정원",   boss = "세라넬 선래시",   itemID = 260312, slot = "망토",   note = "BIS" },
        { dungeon = "마법학자의 정원",   boss = "데젠트리우스",     itemID = 251118, slot = "다리",   note = "대체재" },
        { dungeon = "윈드러너 첨탑",     boss = "크롤룩 사령관",   itemID = 251091, slot = "발",     note = "대체재" },
    },

    -- 분노 전사 (Fury) — 72
    [72] = {
        { dungeon = "공결점 제나스",     boss = "로스라시온",       itemID = 250241, slot = "장신구", note = "BIS" },
        { dungeon = "윈드러너 첨탑",     boss = "안식 없는 심장",   itemID = 250256, slot = "장신구", note = "BIS" },
        { dungeon = "삼두정의 권좌",     boss = "사프리시",         itemID = 151307, slot = "장신구", note = "대체재" },
        { dungeon = "알게타르 아카데미", boss = "도라고사의 메아리", itemID = 193701, slot = "장신구", note = "대체재" },
        { dungeon = "마이사라 동굴",     boss = "락툴",             itemID = 251168, slot = "무기",   note = "BIS" },
        { dungeon = "마법학자의 정원",   boss = "세라넬 선래시",   itemID = 260312, slot = "망토",   note = "BIS" },
        { dungeon = "마법학자의 정원",   boss = "데젠트리우스",     itemID = 251122, slot = "무기",   note = "대체재" },
    },

    -- 방어 전사 (Protection) — 73
    [73] = {
        { dungeon = "마법학자의 정원",   boss = "게멜루스",         itemID = 250242, slot = "장신구", note = "BIS" },
        { dungeon = "하늘탑",             boss = "아라크나스",       itemID = 252418, slot = "장신구", note = "BIS" },
        { dungeon = "사론의 구덩이",     boss = "이크와 크릭",     itemID = 252421, slot = "장신구", note = "대체재" },
        { dungeon = "삼두정의 권좌",     boss = "루라",             itemID = 151312, slot = "장신구", note = "대체재" },
        { dungeon = "마법학자의 정원",   boss = "세라넬 선래시",   itemID = 251105, slot = "방패",   note = "BIS" },
        { dungeon = "윈드러너 첨탑",     boss = "크롤룩 사령관",   itemID = 251091, slot = "발",     note = "BIS" },
        { dungeon = "마법학자의 정원",   boss = "게멜루스",         itemID = 251112, slot = "허리",   note = "대체재" },
    },

    -- ============================================================
    -- 성기사 (Paladin)
    -- ============================================================

    -- 신성 성기사 (Holy) — 65
    [65] = {
        { dungeon = "마법학자의 정원",   boss = "아르카노트론 쿠스토스", itemID = 250246, slot = "장신구", note = "BIS" },
        { dungeon = "공결점 제나스",     boss = "코어수호자 니사라",     itemID = 250253, slot = "장신구", note = "BIS" },
        { dungeon = "알게타르 아카데미", boss = "크로스",               itemID = 193718, slot = "장신구", note = "대체재" },
        { dungeon = "삼두정의 권좌",     boss = "루라",                 itemID = 151340, slot = "장신구", note = "대체재" },
        { dungeon = "알게타르 아카데미", boss = "벡사무스",             itemID = 193710, slot = "무기",   note = "BIS" },
        { dungeon = "알게타르 아카데미", boss = "크로스",               itemID = 258531, slot = "방패",   note = "BIS" },
        { dungeon = "마이사라 동굴",     boss = "락툴",                 itemID = 251164, slot = "어깨",   note = "BIS" },
        { dungeon = "마이사라 동굴",     boss = "무로진과 네크락스",   itemID = 263193, slot = "손목",   note = "BIS" },
    },

    -- 방어 성기사 (Protection) — 66
    [66] = {
        { dungeon = "마법학자의 정원",   boss = "게멜루스",         itemID = 250242, slot = "장신구", note = "BIS" },
        { dungeon = "하늘탑",             boss = "아라크나스",       itemID = 252418, slot = "장신구", note = "BIS" },
        { dungeon = "삼두정의 권좌",     boss = "루라",             itemID = 151312, slot = "장신구", note = "대체재" },
        { dungeon = "사론의 구덩이",     boss = "이크와 크릭",     itemID = 252421, slot = "장신구", note = "대체재" },
        { dungeon = "마법학자의 정원",   boss = "세라넬 선래시",   itemID = 251105, slot = "방패",   note = "BIS" },
        { dungeon = "마법학자의 정원",   boss = "세라넬 선래시",   itemID = 260312, slot = "망토",   note = "BIS" },
        { dungeon = "윈드러너 첨탑",     boss = "크롤룩 사령관",   itemID = 251091, slot = "발",     note = "BIS" },
    },

    -- 징벌 성기사 (Retribution) — 70
    [70] = {
        { dungeon = "공결점 제나스",     boss = "로스라시온",       itemID = 250241, slot = "장신구", note = "BIS" },
        { dungeon = "윈드러너 첨탑",     boss = "안식 없는 심장",   itemID = 250256, slot = "장신구", note = "BIS" },
        { dungeon = "알게타르 아카데미", boss = "도라고사의 메아리", itemID = 193701, slot = "장신구", note = "대체재" },
        { dungeon = "삼두정의 권좌",     boss = "사프리시",         itemID = 151307, slot = "장신구", note = "대체재" },
        { dungeon = "마법학자의 정원",   boss = "세라넬 선래시",   itemID = 260312, slot = "망토",   note = "BIS" },
        { dungeon = "공결점 제나스",     boss = "로스라시온",       itemID = 251217, slot = "반지",   note = "BIS" },
        { dungeon = "마법학자의 정원",   boss = "데젠트리우스",     itemID = 251118, slot = "다리",   note = "대체재" },
    },

    -- ============================================================
    -- 사냥꾼 (Hunter)
    -- ============================================================

    -- 야수 사냥꾼 (Beast Mastery) — 253
    [253] = {
        { dungeon = "윈드러너 첨탑",     boss = "엠버던",           itemID = 250144, slot = "장신구", note = "BIS" },
        { dungeon = "알게타르 아카데미", boss = "도라고사의 메아리", itemID = 193701, slot = "장신구", note = "BIS" },
        { dungeon = "삼두정의 권좌",     boss = "사프리시",         itemID = 151307, slot = "장신구", note = "대체재" },
        { dungeon = "하늘탑",             boss = "대현자 비릭스",   itemID = 252420, slot = "장신구", note = "대체재" },
        { dungeon = "윈드러너 첨탑",     boss = "안식 없는 심장",   itemID = 251095, slot = "무기",   note = "BIS" },
        { dungeon = "마이사라 동굴",     boss = "무로진과 네크락스", itemID = 251174, slot = "무기",   note = "대체재" },
        { dungeon = "마이사라 동굴",     boss = "무로진과 네크락스", itemID = 251110, slot = "허리",   note = "대체재" },
    },

    -- 사격 사냥꾼 (Marksmanship) — 254
    [254] = {
        { dungeon = "윈드러너 첨탑",     boss = "엠버던",           itemID = 250144, slot = "장신구", note = "BIS" },
        { dungeon = "알게타르 아카데미", boss = "도라고사의 메아리", itemID = 193701, slot = "장신구", note = "BIS" },
        { dungeon = "삼두정의 권좌",     boss = "사프리시",         itemID = 151307, slot = "장신구", note = "대체재" },
        { dungeon = "하늘탑",             boss = "대현자 비릭스",   itemID = 252420, slot = "장신구", note = "대체재" },
        { dungeon = "윈드러너 첨탑",     boss = "안식 없는 심장",   itemID = 251095, slot = "무기",   note = "BIS" },
        { dungeon = "마이사라 동굴",     boss = "무로진과 네크락스", itemID = 251174, slot = "무기",   note = "대체재" },
        { dungeon = "윈드러너 첨탑",     boss = "안식 없는 심장",   itemID = 251097, slot = "어깨",   note = "대체재" },
    },

    -- 생존 사냥꾼 (Survival) — 255
    [255] = {
        { dungeon = "윈드러너 첨탑",     boss = "엠버던",           itemID = 250144, slot = "장신구", note = "BIS" },
        { dungeon = "알게타르 아카데미", boss = "도라고사의 메아리", itemID = 193701, slot = "장신구", note = "BIS" },
        { dungeon = "삼두정의 권좌",     boss = "사프리시",         itemID = 151307, slot = "장신구", note = "대체재" },
        { dungeon = "하늘탑",             boss = "대현자 비릭스",   itemID = 252420, slot = "장신구", note = "대체재" },
        { dungeon = "마이사라 동굴",     boss = "무로진과 네크락스", itemID = 251162, slot = "무기",   note = "BIS" },
        { dungeon = "하늘탑",             boss = "대현자 비릭스",   itemID = 258484, slot = "무기",   note = "대체재" },
        { dungeon = "마이사라 동굴",     boss = "락툴",             itemID = 251163, slot = "손",     note = "대체재" },
    },

    -- ============================================================
    -- 도적 (Rogue)
    -- ============================================================

    -- 암살 도적 (Assassination) — 259
    [259] = {
        { dungeon = "윈드러너 첨탑",     boss = "엠버던",           itemID = 250144, slot = "장신구", note = "BIS" },
        { dungeon = "알게타르 아카데미", boss = "도라고사의 메아리", itemID = 193701, slot = "장신구", note = "BIS" },
        { dungeon = "삼두정의 권좌",     boss = "사프리시",         itemID = 151307, slot = "장신구", note = "대체재" },
        { dungeon = "윈드러너 첨탑",     boss = "잔해 듀오",       itemID = 250226, slot = "장신구", note = "대체재" },
        { dungeon = "공결점 제나스",     boss = "로스라시온",       itemID = 251212, slot = "무기",   note = "BIS" },
        { dungeon = "마이사라 동굴",     boss = "보르다자",         itemID = 251178, slot = "무기",   note = "대체재" },
        { dungeon = "마법학자의 정원",   boss = "게멜루스",         itemID = 251111, slot = "무기",   note = "대체재" },
    },

    -- 무법 도적 (Outlaw) — 260
    [260] = {
        { dungeon = "윈드러너 첨탑",     boss = "엠버던",           itemID = 250144, slot = "장신구", note = "BIS" },
        { dungeon = "알게타르 아카데미", boss = "도라고사의 메아리", itemID = 193701, slot = "장신구", note = "BIS" },
        { dungeon = "삼두정의 권좌",     boss = "사프리시",         itemID = 151307, slot = "장신구", note = "대체재" },
        { dungeon = "윈드러너 첨탑",     boss = "잔해 듀오",       itemID = 250226, slot = "장신구", note = "대체재" },
        { dungeon = "마법학자의 정원",   boss = "데젠트리우스",     itemID = 251122, slot = "무기",   note = "BIS" },
        { dungeon = "윈드러너 첨탑",     boss = "크롤룩 사령관",   itemID = 251088, slot = "무기",   note = "대체재" },
        { dungeon = "마이사라 동굴",     boss = "락툴",             itemID = 251175, slot = "무기",   note = "대체재" },
    },

    -- 잠행 도적 (Subtlety) — 261
    [261] = {
        { dungeon = "윈드러너 첨탑",     boss = "엠버던",           itemID = 250144, slot = "장신구", note = "BIS" },
        { dungeon = "알게타르 아카데미", boss = "도라고사의 메아리", itemID = 193701, slot = "장신구", note = "BIS" },
        { dungeon = "삼두정의 권좌",     boss = "사프리시",         itemID = 151307, slot = "장신구", note = "대체재" },
        { dungeon = "윈드러너 첨탑",     boss = "잔해 듀오",       itemID = 250226, slot = "장신구", note = "대체재" },
        { dungeon = "공결점 제나스",     boss = "로스라시온",       itemID = 251212, slot = "무기",   note = "BIS" },
        { dungeon = "마법학자의 정원",   boss = "게멜루스",         itemID = 251111, slot = "무기",   note = "대체재" },
        { dungeon = "마이사라 동굴",     boss = "보르다자",         itemID = 251178, slot = "무기",   note = "대체재" },
    },

    -- ============================================================
    -- 사제 (Priest)
    -- ============================================================

    -- 수양 사제 (Discipline) — 256
    [256] = {
        { dungeon = "마법학자의 정원",   boss = "아르카노트론 쿠스토스", itemID = 250246, slot = "장신구", note = "BIS" },
        { dungeon = "공결점 제나스",     boss = "코어수호자 니사라",     itemID = 250253, slot = "장신구", note = "BIS" },
        { dungeon = "하늘탑",             boss = "루크란",               itemID = 252411, slot = "장신구", note = "대체재" },
        { dungeon = "삼두정의 권좌",     boss = "루라",                 itemID = 151340, slot = "장신구", note = "대체재" },
        { dungeon = "공결점 제나스",     boss = "코어수호자 니사라",     itemID = 251213, slot = "어깨",   note = "대체재" },
        { dungeon = "마법학자의 정원",   boss = "데젠트리우스",         itemID = 251120, slot = "가슴",   note = "대체재" },
    },

    -- 신성 사제 (Holy) — 257
    [257] = {
        { dungeon = "마법학자의 정원",   boss = "아르카노트론 쿠스토스", itemID = 250246, slot = "장신구", note = "BIS" },
        { dungeon = "공결점 제나스",     boss = "코어수호자 니사라",     itemID = 250253, slot = "장신구", note = "BIS" },
        { dungeon = "알게타르 아카데미", boss = "크로스",               itemID = 193718, slot = "장신구", note = "대체재" },
        { dungeon = "하늘탑",             boss = "루크란",               itemID = 252411, slot = "장신구", note = "대체재" },
        { dungeon = "공결점 제나스",     boss = "코어수호자 니사라",     itemID = 251213, slot = "어깨",   note = "대체재" },
        { dungeon = "마법학자의 정원",   boss = "데젠트리우스",         itemID = 251120, slot = "가슴",   note = "대체재" },
    },

    -- 암흑 사제 (Shadow) — 258
    [258] = {
        { dungeon = "마이사라 동굴",     boss = "보르다자",         itemID = 250223, slot = "장신구", note = "BIS" },
        { dungeon = "마법학자의 정원",   boss = "데젠트리우스",     itemID = 250257, slot = "장신구", note = "BIS" },
        { dungeon = "삼두정의 권좌",     boss = "부왕 네즈하르",   itemID = 151310, slot = "장신구", note = "대체재" },
        { dungeon = "사론의 구덩이",     boss = "이크와 크릭",     itemID = 50259,  slot = "장신구", note = "대체재" },
        { dungeon = "공결점 제나스",     boss = "코어수호자 니사라", itemID = 251093, slot = "반지",   note = "BIS" },
        { dungeon = "마이사라 동굴",     boss = "보르다자",         itemID = 251172, slot = "손",     note = "BIS" },
        { dungeon = "하늘탑",             boss = "대현자 비릭스",   itemID = 258584, slot = "발",     note = "BIS" },
    },

    -- ============================================================
    -- 죽음의 기사 (Death Knight)
    -- ============================================================

    -- 혈기 죽기 (Blood) — 250
    [250] = {
        { dungeon = "마법학자의 정원",   boss = "게멜루스",         itemID = 250242, slot = "장신구", note = "BIS" },
        { dungeon = "하늘탑",             boss = "아라크나스",       itemID = 252418, slot = "장신구", note = "BIS" },
        { dungeon = "사론의 구덩이",     boss = "이크와 크릭",     itemID = 252421, slot = "장신구", note = "대체재" },
        { dungeon = "삼두정의 권좌",     boss = "루라",             itemID = 151312, slot = "장신구", note = "대체재" },
        { dungeon = "마법학자의 정원",   boss = "데젠트리우스",     itemID = 251117, slot = "무기",   note = "BIS" },
        { dungeon = "마법학자의 정원",   boss = "데젠트리우스",     itemID = 251118, slot = "다리",   note = "대체재" },
        { dungeon = "공결점 제나스",     boss = "로스라시온",       itemID = 251157, slot = "어깨",   note = "대체재" },
    },

    -- 냉기 죽기 (Frost) — 251
    [251] = {
        { dungeon = "공결점 제나스",     boss = "로스라시온",       itemID = 250241, slot = "장신구", note = "BIS" },
        { dungeon = "윈드러너 첨탑",     boss = "안식 없는 심장",   itemID = 250256, slot = "장신구", note = "BIS" },
        { dungeon = "삼두정의 권좌",     boss = "사프리시",         itemID = 151307, slot = "장신구", note = "대체재" },
        { dungeon = "알게타르 아카데미", boss = "도라고사의 메아리", itemID = 193701, slot = "장신구", note = "대체재" },
        { dungeon = "마법학자의 정원",   boss = "데젠트리우스",     itemID = 251122, slot = "무기",   note = "BIS" },
        { dungeon = "윈드러너 첨탑",     boss = "크롤룩 사령관",   itemID = 251088, slot = "무기",   note = "대체재" },
    },

    -- 부정 죽기 (Unholy) — 252
    [252] = {
        { dungeon = "공결점 제나스",     boss = "로스라시온",       itemID = 250241, slot = "장신구", note = "BIS" },
        { dungeon = "윈드러너 첨탑",     boss = "안식 없는 심장",   itemID = 250256, slot = "장신구", note = "BIS" },
        { dungeon = "알게타르 아카데미", boss = "도라고사의 메아리", itemID = 193701, slot = "장신구", note = "대체재" },
        { dungeon = "삼두정의 권좌",     boss = "사프리시",         itemID = 151307, slot = "장신구", note = "대체재" },
        { dungeon = "마법학자의 정원",   boss = "데젠트리우스",     itemID = 251117, slot = "무기",   note = "BIS" },
        { dungeon = "마법학자의 정원",   boss = "데젠트리우스",     itemID = 251118, slot = "다리",   note = "대체재" },
    },

    -- ============================================================
    -- 주술사 (Shaman)
    -- ============================================================

    -- 정기 주술사 (Elemental) — 262
    [262] = {
        { dungeon = "마이사라 동굴",     boss = "보르다자",         itemID = 250223, slot = "장신구", note = "BIS" },
        { dungeon = "마법학자의 정원",   boss = "데젠트리우스",     itemID = 250257, slot = "장신구", note = "BIS" },
        { dungeon = "삼두정의 권좌",     boss = "부왕 네즈하르",   itemID = 151310, slot = "장신구", note = "대체재" },
        { dungeon = "사론의 구덩이",     boss = "이크와 크릭",     itemID = 50259,  slot = "장신구", note = "대체재" },
        { dungeon = "마법학자의 정원",   boss = "세라넬 선래시",   itemID = 251105, slot = "방패",   note = "BIS" },
        { dungeon = "공결점 제나스",     boss = "코어수호자 니사라", itemID = 251093, slot = "반지",   note = "BIS" },
        { dungeon = "공결점 제나스",     boss = "코어수호자 니사라", itemID = 251207, slot = "무기",   note = "대체재" },
    },

    -- 고양 주술사 (Enhancement) — 263
    [263] = {
        { dungeon = "윈드러너 첨탑",     boss = "엠버던",           itemID = 250144, slot = "장신구", note = "BIS" },
        { dungeon = "알게타르 아카데미", boss = "도라고사의 메아리", itemID = 193701, slot = "장신구", note = "BIS" },
        { dungeon = "삼두정의 권좌",     boss = "사프리시",         itemID = 151307, slot = "장신구", note = "대체재" },
        { dungeon = "하늘탑",             boss = "대현자 비릭스",   itemID = 252420, slot = "장신구", note = "대체재" },
        { dungeon = "윈드러너 첨탑",     boss = "크롤룩 사령관",   itemID = 251088, slot = "무기",   note = "BIS" },
        { dungeon = "마이사라 동굴",     boss = "락툴",             itemID = 251175, slot = "무기",   note = "대체재" },
        { dungeon = "마이사라 동굴",     boss = "락툴",             itemID = 251163, slot = "손",     note = "대체재" },
    },

    -- 복원 주술사 (Restoration) — 264
    [264] = {
        { dungeon = "마법학자의 정원",   boss = "아르카노트론 쿠스토스", itemID = 250246, slot = "장신구", note = "BIS" },
        { dungeon = "공결점 제나스",     boss = "코어수호자 니사라",     itemID = 250253, slot = "장신구", note = "BIS" },
        { dungeon = "하늘탑",             boss = "루크란",               itemID = 252411, slot = "장신구", note = "대체재" },
        { dungeon = "알게타르 아카데미", boss = "크로스",               itemID = 193718, slot = "장신구", note = "대체재" },
        { dungeon = "윈드러너 첨탑",     boss = "안식 없는 심장",       itemID = 250256, slot = "장신구", note = "대체재" },
        { dungeon = "마이사라 동굴",     boss = "보르다자",             itemID = 251170, slot = "다리",   note = "대체재" },
    },

    -- ============================================================
    -- 마법사 (Mage)
    -- ============================================================

    -- 비전 마법사 (Arcane) — 62
    [62] = {
        { dungeon = "마이사라 동굴",     boss = "보르다자",         itemID = 250223, slot = "장신구", note = "BIS" },
        { dungeon = "마법학자의 정원",   boss = "데젠트리우스",     itemID = 250257, slot = "장신구", note = "BIS" },
        { dungeon = "삼두정의 권좌",     boss = "부왕 네즈하르",   itemID = 151310, slot = "장신구", note = "대체재" },
        { dungeon = "사론의 구덩이",     boss = "이크와 크릭",     itemID = 50259,  slot = "장신구", note = "대체재" },
        { dungeon = "윈드러너 첨탑",     boss = "크롤룩 사령관",   itemID = 251090, slot = "다리",   note = "BIS" },
        { dungeon = "하늘탑",             boss = "란지트",           itemID = 258575, slot = "망토",   note = "BIS" },
        { dungeon = "공결점 제나스",     boss = "코어수호자 니사라", itemID = 251093, slot = "반지",   note = "대체재" },
    },

    -- 화염 마법사 (Fire) — 63
    [63] = {
        { dungeon = "마이사라 동굴",     boss = "보르다자",         itemID = 250223, slot = "장신구", note = "BIS" },
        { dungeon = "마법학자의 정원",   boss = "데젠트리우스",     itemID = 250257, slot = "장신구", note = "BIS" },
        { dungeon = "삼두정의 권좌",     boss = "부왕 네즈하르",   itemID = 151310, slot = "장신구", note = "대체재" },
        { dungeon = "사론의 구덩이",     boss = "이크와 크릭",     itemID = 50259,  slot = "장신구", note = "대체재" },
        { dungeon = "마법학자의 정원",   boss = "데젠트리우스",     itemID = 251120, slot = "가슴",   note = "대체재" },
        { dungeon = "공결점 제나스",     boss = "코어수호자 니사라", itemID = 251093, slot = "반지",   note = "대체재" },
    },

    -- 냉기 마법사 (Frost) — 64
    [64] = {
        { dungeon = "마이사라 동굴",     boss = "보르다자",         itemID = 250223, slot = "장신구", note = "BIS" },
        { dungeon = "마법학자의 정원",   boss = "데젠트리우스",     itemID = 250257, slot = "장신구", note = "BIS" },
        { dungeon = "삼두정의 권좌",     boss = "부왕 네즈하르",   itemID = 151310, slot = "장신구", note = "대체재" },
        { dungeon = "사론의 구덩이",     boss = "이크와 크릭",     itemID = 50259,  slot = "장신구", note = "대체재" },
        { dungeon = "공결점 제나스",     boss = "로스라시온",       itemID = 251211, slot = "손",     note = "대체재" },
        { dungeon = "마법학자의 정원",   boss = "데젠트리우스",     itemID = 251120, slot = "가슴",   note = "대체재" },
    },

    -- ============================================================
    -- 흑마법사 (Warlock)
    -- ============================================================

    -- 고통 흑마법사 (Affliction) — 265
    [265] = {
        { dungeon = "마이사라 동굴",     boss = "보르다자",         itemID = 250223, slot = "장신구", note = "BIS" },
        { dungeon = "마법학자의 정원",   boss = "데젠트리우스",     itemID = 250257, slot = "장신구", note = "BIS" },
        { dungeon = "삼두정의 권좌",     boss = "부왕 네즈하르",   itemID = 151310, slot = "장신구", note = "대체재" },
        { dungeon = "사론의 구덩이",     boss = "이크와 크릭",     itemID = 50259,  slot = "장신구", note = "대체재" },
        { dungeon = "공결점 제나스",     boss = "코어수호자 니사라", itemID = 251093, slot = "반지",   note = "BIS" },
        { dungeon = "마법학자의 정원",   boss = "데젠트리우스",     itemID = 251120, slot = "가슴",   note = "대체재" },
    },

    -- 악마 흑마법사 (Demonology) — 266
    [266] = {
        { dungeon = "마이사라 동굴",     boss = "보르다자",         itemID = 250223, slot = "장신구", note = "BIS" },
        { dungeon = "마법학자의 정원",   boss = "데젠트리우스",     itemID = 250257, slot = "장신구", note = "BIS" },
        { dungeon = "삼두정의 권좌",     boss = "부왕 네즈하르",   itemID = 151310, slot = "장신구", note = "대체재" },
        { dungeon = "사론의 구덩이",     boss = "이크와 크릭",     itemID = 50259,  slot = "장신구", note = "대체재" },
        { dungeon = "공결점 제나스",     boss = "코어수호자 니사라", itemID = 251093, slot = "반지",   note = "대체재" },
        { dungeon = "윈드러너 첨탑",     boss = "크롤룩 사령관",   itemID = 251090, slot = "다리",   note = "대체재" },
    },

    -- 파괴 흑마법사 (Destruction) — 267
    [267] = {
        { dungeon = "마이사라 동굴",     boss = "보르다자",         itemID = 250223, slot = "장신구", note = "BIS" },
        { dungeon = "마법학자의 정원",   boss = "데젠트리우스",     itemID = 250257, slot = "장신구", note = "BIS" },
        { dungeon = "삼두정의 권좌",     boss = "부왕 네즈하르",   itemID = 151310, slot = "장신구", note = "대체재" },
        { dungeon = "사론의 구덩이",     boss = "이크와 크릭",     itemID = 50259,  slot = "장신구", note = "대체재" },
        { dungeon = "하늘탑",             boss = "란지트",           itemID = 258575, slot = "망토",   note = "BIS" },
        { dungeon = "공결점 제나스",     boss = "코어수호자 니사라", itemID = 251093, slot = "반지",   note = "BIS" },
    },

    -- ============================================================
    -- 수도사 (Monk)
    -- ============================================================

    -- 양조 수도사 (Brewmaster) — 268
    [268] = {
        { dungeon = "마법학자의 정원",   boss = "게멜루스",         itemID = 250242, slot = "장신구", note = "BIS" },
        { dungeon = "하늘탑",             boss = "아라크나스",       itemID = 252418, slot = "장신구", note = "BIS" },
        { dungeon = "사론의 구덩이",     boss = "이크와 크릭",     itemID = 252421, slot = "장신구", note = "대체재" },
        { dungeon = "삼두정의 권좌",     boss = "루라",             itemID = 151312, slot = "장신구", note = "대체재" },
        { dungeon = "알게타르 아카데미", boss = "크로스",           itemID = 193723, slot = "무기",   note = "BIS" },
        { dungeon = "마이사라 동굴",     boss = "무로진과 네크락스", itemID = 251166, slot = "허리",   note = "대체재" },
        { dungeon = "마법학자의 정원",   boss = "데젠트리우스",     itemID = 251121, slot = "발",     note = "대체재" },
    },

    -- 풍운 수도사 (Windwalker) — 269
    [269] = {
        { dungeon = "윈드러너 첨탑",     boss = "엠버던",           itemID = 250144, slot = "장신구", note = "BIS" },
        { dungeon = "알게타르 아카데미", boss = "도라고사의 메아리", itemID = 193701, slot = "장신구", note = "BIS" },
        { dungeon = "삼두정의 권좌",     boss = "사프리시",         itemID = 151307, slot = "장신구", note = "대체재" },
        { dungeon = "윈드러너 첨탑",     boss = "잔해 듀오",       itemID = 250226, slot = "장신구", note = "대체재" },
        { dungeon = "윈드러너 첨탑",     boss = "잔해 듀오",       itemID = 251083, slot = "무기",   note = "BIS" },
        { dungeon = "마이사라 동굴",     boss = "보르다자",         itemID = 251161, slot = "머리",   note = "대체재" },
        { dungeon = "마법학자의 정원",   boss = "게멜루스",         itemID = 251113, slot = "손",     note = "대체재" },
    },

    -- 운무 수도사 (Mistweaver) — 270
    [270] = {
        { dungeon = "마법학자의 정원",   boss = "아르카노트론 쿠스토스", itemID = 250246, slot = "장신구", note = "BIS" },
        { dungeon = "공결점 제나스",     boss = "코어수호자 니사라",     itemID = 250253, slot = "장신구", note = "BIS" },
        { dungeon = "하늘탑",             boss = "루크란",               itemID = 252411, slot = "장신구", note = "대체재" },
        { dungeon = "삼두정의 권좌",     boss = "루라",                 itemID = 151340, slot = "장신구", note = "대체재" },
        { dungeon = "공결점 제나스",     boss = "로스라시온",           itemID = 251216, slot = "가슴",   note = "대체재" },
        { dungeon = "공결점 제나스",     boss = "코어수호자 니사라",     itemID = 251210, slot = "발",     note = "대체재" },
    },

    -- ============================================================
    -- 드루이드 (Druid)
    -- ============================================================

    -- 조화 드루이드 (Balance) — 102
    [102] = {
        { dungeon = "마이사라 동굴",     boss = "보르다자",         itemID = 250223, slot = "장신구", note = "BIS" },
        { dungeon = "마법학자의 정원",   boss = "데젠트리우스",     itemID = 250257, slot = "장신구", note = "BIS" },
        { dungeon = "삼두정의 권좌",     boss = "부왕 네즈하르",   itemID = 151310, slot = "장신구", note = "대체재" },
        { dungeon = "사론의 구덩이",     boss = "이크와 크릭",     itemID = 50259,  slot = "장신구", note = "대체재" },
        { dungeon = "공결점 제나스",     boss = "코어수호자 니사라", itemID = 251093, slot = "반지",   note = "BIS" },
        { dungeon = "공결점 제나스",     boss = "로스라시온",       itemID = 251217, slot = "반지",   note = "BIS" },
        { dungeon = "윈드러너 첨탑",     boss = "엠버던",           itemID = 251077, slot = "무기",   note = "대체재" },
    },

    -- 야성 드루이드 (Feral) — 103
    [103] = {
        { dungeon = "윈드러너 첨탑",     boss = "엠버던",           itemID = 250144, slot = "장신구", note = "BIS" },
        { dungeon = "알게타르 아카데미", boss = "도라고사의 메아리", itemID = 193701, slot = "장신구", note = "BIS" },
        { dungeon = "삼두정의 권좌",     boss = "사프리시",         itemID = 151307, slot = "장신구", note = "대체재" },
        { dungeon = "윈드러너 첨탑",     boss = "잔해 듀오",       itemID = 250226, slot = "장신구", note = "대체재" },
        { dungeon = "알게타르 아카데미", boss = "벡사무스",         itemID = 193717, slot = "무기",   note = "BIS" },
        { dungeon = "마이사라 동굴",     boss = "무로진과 네크락스", itemID = 251166, slot = "허리",   note = "대체재" },
        { dungeon = "마법학자의 정원",   boss = "게멜루스",         itemID = 251113, slot = "손",     note = "대체재" },
    },

    -- 수호 드루이드 (Guardian) — 104
    [104] = {
        -- 마법학자의 정원
        { dungeon = "마법학자의 정원",   boss = "게멜루스",           itemID = 250242, slot = "장신구", note = "BIS" },
        { dungeon = "마법학자의 정원",   boss = "세라넬 선래시",     itemID = 260312, slot = "망토",   note = "대체재" },
        { dungeon = "마법학자의 정원",   boss = "데젠트리우스",       itemID = 251121, slot = "발",     note = "대체재" },
        -- 마이사라 동굴
        { dungeon = "마이사라 동굴",     boss = "보르다자",           itemID = 251161, slot = "머리",   note = "대체재" },
        { dungeon = "마이사라 동굴",     boss = "무로진과 네크락스", itemID = 251166, slot = "허리",   note = "BIS" },
        -- 공결점 제나스
        { dungeon = "공결점 제나스",     boss = "로스라시온",         itemID = 251217, slot = "반지",   note = "BIS" },
        { dungeon = "공결점 제나스",     boss = "코어수호자 니사라", itemID = 251093, slot = "반지",   note = "대체재" },
        -- 윈드러너 첨탑
        { dungeon = "윈드러너 첨탑",     boss = "잔해 듀오",         itemID = 251087, slot = "다리",   note = "BIS" },
        { dungeon = "윈드러너 첨탑",     boss = "안식 없는 심장",   itemID = 251099, slot = "가슴",   note = "대체재" },
        -- 알게타르 아카데미
        { dungeon = "알게타르 아카데미", boss = "벡사무스",           itemID = 193712, slot = "망토",   note = "BIS" },
        { dungeon = "알게타르 아카데미", boss = "도라고사의 메아리", itemID = 193701, slot = "장신구", note = "대체재" },
        -- 삼두정의 권좌
        { dungeon = "삼두정의 권좌",     boss = "루라",               itemID = 151312, slot = "장신구", note = "대체재" },
        -- 하늘탑
        { dungeon = "하늘탑",             boss = "아라크나스",         itemID = 252418, slot = "장신구", note = "BIS" },
        -- 사론의 구덩이
        { dungeon = "사론의 구덩이",     boss = "이크와 크릭",       itemID = 252421, slot = "장신구", note = "대체재" },
    },

    -- 회복 드루이드 (Restoration) — 105
    [105] = {
        { dungeon = "마법학자의 정원",   boss = "아르카노트론 쿠스토스", itemID = 250246, slot = "장신구", note = "BIS" },
        { dungeon = "공결점 제나스",     boss = "코어수호자 니사라",     itemID = 250253, slot = "장신구", note = "BIS" },
        { dungeon = "하늘탑",             boss = "루크란",               itemID = 252411, slot = "장신구", note = "대체재" },
        { dungeon = "삼두정의 권좌",     boss = "루라",                 itemID = 151340, slot = "장신구", note = "대체재" },
        { dungeon = "공결점 제나스",     boss = "로스라시온",           itemID = 251216, slot = "가슴",   note = "대체재" },
        { dungeon = "공결점 제나스",     boss = "코어수호자 니사라",     itemID = 251210, slot = "발",     note = "대체재" },
    },

    -- ============================================================
    -- 악마사냥꾼 (Demon Hunter)
    -- ============================================================

    -- 파멸 악사 (Havoc / Devourer) — 577
    [577] = {
        { dungeon = "윈드러너 첨탑",     boss = "엠버던",           itemID = 250144, slot = "장신구", note = "BIS" },
        { dungeon = "알게타르 아카데미", boss = "도라고사의 메아리", itemID = 193701, slot = "장신구", note = "BIS" },
        { dungeon = "삼두정의 권좌",     boss = "사프리시",         itemID = 151307, slot = "장신구", note = "대체재" },
        { dungeon = "윈드러너 첨탑",     boss = "잔해 듀오",       itemID = 250226, slot = "장신구", note = "대체재" },
        { dungeon = "마법학자의 정원",   boss = "세라넬 선래시",   itemID = 251106, slot = "무기",   note = "BIS" },
        { dungeon = "윈드러너 첨탑",     boss = "안식 없는 심장",   itemID = 251099, slot = "가슴",   note = "대체재" },
        { dungeon = "마법학자의 정원",   boss = "데젠트리우스",     itemID = 251121, slot = "발",     note = "대체재" },
    },

    -- 복수 악사 (Vengeance) — 581
    [581] = {
        { dungeon = "마법학자의 정원",   boss = "게멜루스",         itemID = 250242, slot = "장신구", note = "BIS" },
        { dungeon = "하늘탑",             boss = "아라크나스",       itemID = 252418, slot = "장신구", note = "BIS" },
        { dungeon = "사론의 구덩이",     boss = "이크와 크릭",     itemID = 252421, slot = "장신구", note = "대체재" },
        { dungeon = "삼두정의 권좌",     boss = "루라",             itemID = 151312, slot = "장신구", note = "대체재" },
        { dungeon = "마법학자의 정원",   boss = "세라넬 선래시",   itemID = 251106, slot = "무기",   note = "BIS" },
        { dungeon = "마이사라 동굴",     boss = "보르다자",         itemID = 251161, slot = "머리",   note = "대체재" },
        { dungeon = "마법학자의 정원",   boss = "게멜루스",         itemID = 251113, slot = "손",     note = "대체재" },
    },

    -- ============================================================
    -- 기원사 (Evoker)
    -- ============================================================

    -- 황폐 기원사 (Devastation) — 1467
    [1467] = {
        { dungeon = "마이사라 동굴",     boss = "보르다자",         itemID = 250223, slot = "장신구", note = "BIS" },
        { dungeon = "마법학자의 정원",   boss = "데젠트리우스",     itemID = 250257, slot = "장신구", note = "BIS" },
        { dungeon = "삼두정의 권좌",     boss = "부왕 네즈하르",   itemID = 151310, slot = "장신구", note = "대체재" },
        { dungeon = "하늘탑",             boss = "대현자 비릭스",   itemID = 252420, slot = "장신구", note = "대체재" },
        { dungeon = "공결점 제나스",     boss = "코어수호자 니사라", itemID = 251209, slot = "손목",   note = "대체재" },
        { dungeon = "마이사라 동굴",     boss = "보르다자",         itemID = 251170, slot = "다리",   note = "대체재" },
    },

    -- 보존 기원사 (Preservation) — 1468
    [1468] = {
        { dungeon = "마법학자의 정원",   boss = "아르카노트론 쿠스토스", itemID = 250246, slot = "장신구", note = "BIS" },
        { dungeon = "공결점 제나스",     boss = "코어수호자 니사라",     itemID = 250253, slot = "장신구", note = "BIS" },
        { dungeon = "하늘탑",             boss = "루크란",               itemID = 252411, slot = "장신구", note = "대체재" },
        { dungeon = "알게타르 아카데미", boss = "크로스",               itemID = 193718, slot = "장신구", note = "대체재" },
        { dungeon = "마이사라 동굴",     boss = "보르다자",             itemID = 251170, slot = "다리",   note = "대체재" },
        { dungeon = "공결점 제나스",     boss = "코어수호자 니사라",     itemID = 251209, slot = "손목",   note = "대체재" },
    },

    -- 증강 기원사 (Augmentation) — 1473
    [1473] = {
        { dungeon = "마이사라 동굴",     boss = "보르다자",         itemID = 250223, slot = "장신구", note = "BIS" },
        { dungeon = "마법학자의 정원",   boss = "데젠트리우스",     itemID = 250257, slot = "장신구", note = "BIS" },
        { dungeon = "삼두정의 권좌",     boss = "부왕 네즈하르",   itemID = 151310, slot = "장신구", note = "대체재" },
        { dungeon = "하늘탑",             boss = "대현자 비릭스",   itemID = 252420, slot = "장신구", note = "대체재" },
        { dungeon = "마이사라 동굴",     boss = "락툴",             itemID = 251163, slot = "손",     note = "대체재" },
        { dungeon = "공결점 제나스",     boss = "코어수호자 니사라", itemID = 251209, slot = "손목",   note = "대체재" },
    },
}
