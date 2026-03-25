local _, ns = ...

-- 한밤 (Midnight) 시즌 1 주간 이벤트 스케줄
-- GetServerTime() UTC 기반 계산
-- x/y: 0-100 퍼센티지 좌표 (TomTom 웨이포인트용, 인게임 실측 후 수정 필요)
ns.Data.WorldEventSchedule = {
    events = {
        {
            -- 살데릴의 궁정: 실버문 지역, 매 60분 주기, 15분 지속
            key         = "saldeerylsCourt",
            labelKey    = "world_event_saldeerylsCourt",
            locationKey = "world_event_loc_saldeerylsCourt",
            interval    = 60,
            duration    = 15,
            offset      = 0,
            mapID       = 2395,
            x           = 55.0,   -- ※ 인게임 실측 후 수정
            y           = 42.0,
            color       = { 1.00, 0.82, 0.40 },
        },
        {
            -- 스토마리온 공격: 공허폭풍 지역, 매 120분 주기, 30분 지속
            key         = "stomarionAttack",
            labelKey    = "world_event_stomarionAttack",
            locationKey = "world_event_loc_stomarionAttack",
            interval    = 120,
            duration    = 30,
            offset      = 30,
            mapID       = 2444,
            x           = 50.0,   -- ※ 인게임 실측 후 수정
            y           = 50.0,
            color       = { 0.70, 0.55, 1.00 },
        },
        {
            -- 풍요: 에버송 숲, 매 60분 주기, 15분 지속
            key         = "abundance",
            labelKey    = "world_event_abundance",
            locationKey = "world_event_loc_abundance",
            interval    = 60,
            duration    = 15,
            offset      = 30,
            mapID       = 2393,
            x           = 48.0,   -- ※ 인게임 실측 후 수정
            y           = 58.0,
            color       = { 0.55, 1.00, 0.70 },
        },
        {
            -- 하라니르의 전설: 하란다르, 매 60분 주기, 15분 지속
            key         = "haranyrLegend",
            labelKey    = "world_event_haranyrLegend",
            locationKey = "world_event_loc_haranyrLegend",
            interval    = 60,
            duration    = 15,
            offset      = 0,
            mapID       = 2413,
            x           = 50.0,   -- ※ 인게임 실측 후 수정
            y           = 50.0,
            color       = { 1.00, 0.78, 0.55 },
        },
    },
}
