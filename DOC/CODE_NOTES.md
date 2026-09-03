# CODE_NOTES

## 목적

소스 Lua에서 주석을 전부 제거했다. 제거한 주석 중 "지우면 나중에 사고가 나는 것"만 골라 이 문서에 남긴다.

**소스에는 주석이 없으므로 코드 제약은 여기서 확인한다.** 값을 바꾸거나 구조를 손대기 전에 해당 파일 절을 먼저 읽는다.

여기 없는 내용은 자명한 설명이거나 함수명으로 드러나는 내용이라 버린 것이다. 코드와 이 문서가 어긋나면 코드가 사실이고, 이 문서를 고친다.

기준: v1.12.0 / Interface 120100 / WoW 12.1.0.

주석 제거는 `scripts/strip_lua_comments.py`가 담당하며, 동결 파일 10개와 `Data/ItemLevelTable.lua`의 `BISRewardProfiles` 블록은 제외 대상이다.

---

## Utils.lua

- `safeNumber`는 WoW 12.0.5+ 의 secret number 보호 플래그를 벗기는 함수다. 플래그가 붙은 값에 `*`나 `math.floor` 같은 산술을 직접 걸면 `execution tainted by '<addon>'` 오류가 난다. `C_UnitAuras` 등 외부 API 결과에 산술이나 포맷을 적용하기 직전에 반드시 통과시킨다.
- 변환은 `tostring` → `tonumber`다. 실패하면 원본이 아니라 **0을 돌려준다.** 원본 secret number를 그대로 반환하면 오염된 값이 이후 산술·렌더 경로로 다시 퍼진다.
- `tostring` 호출 자체가 taint 오류를 내는 극단 케이스가 있어 전체를 `pcall`로 감싼다. 이 `pcall`을 최적화로 걷어내지 않는다.

## UI/ItemLevelOverlay.lua

- 문장/열쇠 패널은 우측 세로 컬럼이 아니라 창 하단 가로 스트립이다(`CREST_STRIP_H`). 표가 창 폭을 다 쓰도록 A안 정돈에서 옮겼다. 되돌릴 때는 `tableArea`의 `BOTTOM` 앵커와 `contentHeight` 합산식을 함께 고쳐야 한다.
- `contentHeight`는 표 높이와 스트립 높이를 **더한다**. 패널이 표 옆에 있던 시절에는 `math.max`였다. 앵커 방향을 바꾸면 이 식도 같이 바꾼다.
- 풍요로운 구렁 이름 4종은 스트립에 넣기엔 길어서 패널 hover tooltip으로 옮겼다. `frame._keyDetailLines`에 담기고 `getMyKeyLines()`가 원본을 만든다.
- `DELVE_MAP_IDS`에 똬리의 섬 `2512`가 들어 있어야 시즌 2 풍요로운 구렁 이름 조회가 동작한다.
- `CREST_ID_BY_GRADE`는 시즌마다 바뀐다. 시즌 2는 안개문장 `3442~3446`이고 복원 열쇠 `3028`은 시즌 1 값이 그대로 유효하다.

## UI/MythicPlusRecordOverlay.lua

- `ChallengesFrame.DungeonIcons`가 없으면 프레임 자식 중 `mapID`를 가진 것을 모아 쓴다. Blizzard가 필드 이름을 바꾸면 오버레이가 조용히 사라지던 구조라 넣은 fallback이다.
- `DUNGEON_NAME_OVERRIDES`는 던전명 줄바꿈 위치를 잡는 표다. 시즌이 바뀌면 함께 갱신하지 않으면 이름이 한 줄로 넘쳐 잘린다.
- 이 오버레이는 기본값이 꺼짐이다. 표시가 안 된다는 보고를 받으면 설정부터 확인한다.

## Utils.lua

- 여러 파일에서 같은 본문으로 중복되던 헬퍼를 여기로 모았다. `Clamp`, `GetAverageItemLevel`, `IsKoreanLanguageSelected`, `SafeTooltipString`, `Colorize`, `FormatOffsetValue`, `IsEmptyRecord`, `BuildRecordSignature`다.
- 소비 파일은 원래 정의 자리에 `local name = ns.Utils.Name` 한 줄만 남긴다. 호출부를 건드리지 않아 회귀 범위가 좁고, `Utils.lua`가 TOC 13번째로 모든 소비자보다 먼저 로드되므로 별칭이 안전하다.
- `BuildRecordSignature`는 `ActionBarApplier`와 `TemplateSyncManager`가 함께 쓴다. 두 곳이 어긋나면 템플릿 비교가 조용히 틀어지므로 반드시 한 곳에서만 고친다.
- 아직 통합하지 않은 중복이 있다. `makeBtnText`는 파일마다 다른 `FONT_PATH`와 `FONT_FLAGS` 상위 지역변수를 참조해 그대로 옮기면 깨진다. `setStatus`와 `setTooltip`은 패널 구조에 묶여 있고, `safeHandler`는 `ns.Utils.SafeHandler` 부재를 대비한 방어 껍데기라 그대로 둔다.

## Data/StatPriorities.lua · StatPriorityTable.lua · MidnightS1MPlusDB.lua

- 세 파일 모두 생성물이다. 손으로 고치지 않는다. `DOC/MidnightS1_MPlus_Addon_DB_v1.7.lua`를 고치고 `scripts/build_bis_runtime_scoring.py`를 돌린다.
- 스탯 우선순위는 2026-08-30 와우헤드 전문화별 stat-priority 전용 페이지 기준이다. 2026-09-03에 `scripts/refresh_wowhead_stat_priority.py --review`로 40개를 전수 재대조해 31개가 일치함을 확인했다.
- 재대조에서 복원 주술사만 값이 달라 수집값(`치명타 및 극대화 > 가속 = 유연성 > 특화`)으로 갱신했다.
- 무법 도적은 `source="USER_SELECTED"`인데도 값을 정정했다. 저장된 값이 `가속`을 꼴찌로 두고 있었는데, 이는 구형 개요 페이지 수집기가 조건이 붙은 1순위 스탯을 버리던 버그의 결과와 같은 형태다. 전용 페이지 `[ol]` 목록과 `DOC/TODO.md`의 인게임 확인 항목이 모두 `가속` 1순위여서 `가속 > 치명타 및 극대화 > 유연성 > 특화`로 고치고 표식은 남겼다.
- 나머지 `USER_SELECTED` 7개는 수집값과 동률 표기만 달라 수동값을 유지한다. 표식이 붙은 항목을 수집 결과로 자동 덮지 않는 규칙은 그대로다.
- 가중치는 문장에서 기계적으로 만든다. 첫 스탯 100에서 시작해 `=` 0, `>=` 5, `>` 15, `>>` 25, `>>>` 35씩 낮추고 하한은 30이다. 문장에 네 스탯이 다 없으면 빠진 스탯을 최하위로 채운다. 이 규칙은 `scripts/refresh_wowhead_stat_priority.py`에 있다.
- `build_bis_runtime_scoring.py`는 `Data/BISCatalog.lua`의 `BISSpecPolicies` 블록과 각 행의 `statPrioritySummary`도 함께 고친다. 스탯 우선순위를 갱신하면 카탈로그 해시도 바뀌므로 `scripts/validate_season2_scope.py`의 기준 해시를 같이 올린다.

## Data/ItemLevelTable.lua

- `sources` 표는 각 구간 값의 근거다. `dump`는 라이브 API, `tooltip`은 인게임 툴팁 실측, `guide`는 외부 자료다. `guide`가 남아 있으면 `scripts/run_season2_validation.ps1 -Strict`가 릴리스를 막는다. **값을 바꿀 때 태그도 함께 올린다.** 값만 고치고 태그를 두거나 그 반대로 하면 검증기가 잡지 못한다.
- 랭크 사다리는 기준값에 `+0, +3, +6, +10, +13, +16`을 더한 6단계다. 제작 품질 사다리는 `+0, +3, +6, +9, +13`의 5단계로 다르다.
- 시즌 2 등급 상한: `adv 282 / vet 295 / chmp 308 / hero 321 / myth 334`. 탐험가(`expl`) 트랙은 시즌 2에 대응 문장이 없어 제거했다.
- 레이드는 2026-08-28 모험 안내서 전리품 목록으로 네 난이도를 모두 확인했다. 공격대 찾기 `279/282/285/289`, 일반 `292/295/298/302`, 영웅 `305/308/311/315`, 신화 `318/321/324/344`. 보스 순서로 1보스, 2~3보스, 4~6보스, 7~8보스가 트랙 1/6, 2/6, 3/6 값을 받고 신화 마지막 두 보스만 344다. 표에는 일반 이상만 담는다.
- PvP 장비는 별도 체계가 아니라 PvE 업그레이드 트랙을 그대로 쓴다. 인게임 상인 툴팁 실측: 명예 지원자 `263`(강화 트랙 없음), 전쟁모드 전투사 `289`(노련가 4/6, 상한 295), 정복 검투사 `292`(챔피언 1/6, 상한 308). 노련가 5/6과 챔피언 1/6이 둘 다 `292`라 판매 목록만으로는 구분되지 않으므로 툴팁으로 확인해야 한다.
- PvP 장비는 투기장·전장·전쟁 모드에서 아이템 레벨이 올라간다. 지원자와 전투사는 `331`, 검투사는 `344`다. 표 스키마에 해당 필드가 없어 값만 여기 남긴다.
- 쐐기 금고 열은 `C_MythicPlus.GetRewardLevelForDifficultyLevel`로 11개 중 10개가 표와 일치함을 확인했다. `+8`만 API가 `305`를 돌려주는데 앞뒤가 모두 `315`라 단조증가가 깨진다. API 이상값으로 판단해 표는 `315`를 유지한다. 같은 API의 던전 종료 값은 12.1에서 `0`으로만 나와 쓸 수 없다.
- 파일 하단 `ns.Data.BISRewardProfiles` 블록은 주석까지 포함해 sha256으로 고정돼 있다. `scripts/strip_lua_comments.py`가 이 블록을 건드리지 않으며, 값을 바꾸면 `scripts/validate_season2_scope.py`의 기준 해시도 함께 갱신해야 한다.
- **이 파일에는 주석이 없다.** 주석을 앵커로 문자열 치환을 하면 조용히 실패한다. 값 자체를 앵커로 쓰고 치환 결과를 반드시 확인한다.

## Core.lua

- `SafeCall`이 모듈 호출을 `pcall`로 감싸는 이유는 secret number taint 같은 일시적 오류가 사용자 화면에 Lua 오류로 노출되지 않고 다음 frame에서 자연히 회복되게 하려는 것이다. stack trace는 디버그 모드에서만 남긴다.
- `MerchantHelper`, `MailHistory`, `WorldEventOverlay` 자동감지는 의도적으로 비활성이다. 각각 도안 감지 미동작, 우편 자동완성 미구현, 퀘스트 기반 완료 감지 미동작 때문이다. 코드가 살아 있어 보여도 켜기 전에 원인부터 확인한다.

## Events.lua

- `UNIT_AURA` / `UNIT_STATS` / `COMBAT_RATING_UPDATE`는 고주기 이벤트라 디바운싱이 필수다. 빠른 갱신(장비·주문 변화)과 느린 갱신(오라·전투수치 변화)을 분리해 둔 구조를 합치지 않는다.
- 트링킷 발동, 물약, 외부 버프 반영은 느린 디바운스(0.45s)로는 놓친다. 그래서 일반 디바운스(0.15s) 경로로 옮겼다. 되돌리면 발동 효과가 표시되지 않는다.
- `QUEST_LOG_UPDATE`도 디바운스 대상이다. `QuestManager:Scan`은 퀘스트당 WoW API를 5회 이상 호출하므로 디바운스가 없으면 초당 수백 회 호출이 된다.
- 디바운스 콜백은 미리 만들어 재사용한다. 이벤트마다 클로저를 새로 만들면 GC 압력이 커진다.
- **재진입 금지**: `BANKFRAME_CLOSED` 핸들러 안에서 `CloseBankFrame`이나 `abpmCloseBankSessions`를 호출하면 안 된다. BankFrame이 닫히는 중에 재호출하면 `BANKFRAME_CLOSED`가 재발화되어 무한 재귀가 된다. 플래그로 막고 있다.
- 루팅 세션 중 BAG/LOOT 이벤트가 동시에 발화해 followup이 중복되는 것을 토큰 패턴으로 막는다. 1.5초 이내 연속 루팅에서 타이머가 누적되지 않게 하기 위한 것이다.
- 인던 진입, 특성 변경, 장비 교체 같은 critical 시점에는 `force=true`로 강제 갱신해야 한다. 캐시된 `lastStateSignature`가 stale한 0이거나 동일 hash일 수 있어, 강제하지 않으면 스탯이 0으로 표시되거나 트링킷 발동이 반영되지 않는다.
- 로그인 직후와 인던·PvP 진입 직후에는 PaperDoll 통계 API가 일시적으로 0을 반환한다. 그래서 짧은 후속 force refresh를 추가로 건다. 이 지연 호출을 제거하면 0 표시가 남는다.
- 은행 세션 프레임 판정은 영문 전역 상수 비교와 `"bank"` 부분 문자열 검색을 함께 쓴다. 다국어 클라이언트 대응이므로 한쪽만 남기지 않는다.

## Data/ItemLevelTable.lua

- 시즌 2에는 탐험가(`expl`) 트랙과 대응 문장이 없어 항목을 제거했다. 시즌 1 구조를 참고해 되살리지 않는다.
- 강화 랭크 사다리는 기준값 +0, +3, +6, +10, +13, +16의 6단계다. **제작 품질 사다리는 +0, +3, +6, +9, +13의 5단계로 다르다.** 두 사다리를 같은 식으로 계산하면 안 된다.
- `sources` 표는 각 값의 근거다. `dump`는 라이브 API 덤프, `tooltip`은 인게임 툴팁 실측, `guide`는 외부 자료다. `guide`가 남아 있으면 `scripts/run_season2_validation.ps1 -Strict`가 실패한다. 인게임 미확인 값으로 릴리스하는 것을 막는 장치이므로, 검증을 통과시키려고 표기만 바꾸지 않는다.
- 구렁은 8단계(295 / 챔피언)에서 아이템 레벨 상한이 고정된다. 9~11단계는 값이 같고, 11단계에서만 영웅 문장과 황금 보관함 신화 문장이 추가된다.
- 신화 난이도 마지막 두 보스와 매우 희귀 아이템은 344(신화 9 상당)다. 공격대 찾기는 279~289이며 표에는 일반 이상만 넣는다.
- `gradeMax.myth = 334`를 유지한다. 와우헤드 위대한 금고 표에는 `335`가 `Mythic 6/6`으로 적혀 있지만, 같은 사이트의 레이드 표가 신화 보스 1~6에 `318 / 321 / 324`를 주고 이는 `+0, +3, +6, +10, +13, +16` 사다리와 정확히 맞아 6/6이 `334`가 된다. 금고 표는 셀 정렬이 깨진 페이지이고, 업적 `Myth of the Mist`의 `331`은 다섯 번째 랭크라 상한 근거가 아니다. 등급 상한은 2026-08-28 문장 툴팁 실측으로 확정한 값이다.
- PvP 값(명예 263~295, 정복 292~308)은 2026-08-28 상인 판매 목록과 개별 툴팁으로 확정했다. 지원자 263은 강화 트랙이 없고, 전투사 289는 노련가 4/6, 검투사 292는 챔피언 1/6이다. `sources.pvp = "tooltip"`이다.
- 값 수집 경위는 `DOC/SEASON2_HANDOFF.md` 6장에 있다.

## Data/WorldEventSchedule.lua

- 좌표(`x`/`y`, 0~100 퍼센티지)와 주기·지속 시간은 모두 인게임 미실측 추정치다. 실측 전까지 정확한 값으로 취급하지 않는다.
- 시각 계산은 `GetServerTime()` UTC 기준이다.

## Data/Defaults.lua · DB.lua

- BIS 신화 preview snapshot 캐시의 기본값은 **비워 둔다.** 첫 접근에서 현재 시즌을 채우는 구조다.
- snapshot은 그 시즌의 아이템 레벨 기준으로 검증한 값이다. 기존 무효화 조건은 전부 `Data/BISMythicVaultLinks.lua`에서 오기 때문에, 시즌이 바뀌어도 그 파일이 그대로면 이전 시즌 snapshot이 계정 SavedVariables에 계속 남는다. 그래서 **현재 시즌을 캐시 키에 포함**해 시즌이 넘어갈 때 한 번 비운다. 이 키에서 시즌을 빼지 않는다.

## UI/BISOverlay.lua

- 이 파일의 top-level local이 이미 197개다. Lua의 스코프당 local 상한은 200이므로 **새 top-level local을 추가하면 파일이 컴파일되지 않을 수 있다.** helper는 전부 기존 테이블의 필드로 넣는다.
- `SeasonGuard.dataSeason`은 동결된 BIS 정적 데이터(`Data/BISCatalog.lua`, `BISMythicVaultLinks.lua`, `BISSeasonPreviewLinks.lua`, `BISEncounterJournal.lua`)가 기준으로 삼는 시즌이다. BIS 데이터를 갱신할 때 이 값도 함께 올린다.
- `Data/ItemLevelTable.lua`의 시즌이 `dataSeason`과 다르면 BIS 후보·템렙·Encounter Journal tier가 현재 시즌과 맞지 않는다. 이때 Encounter Journal 자동 랜딩, M+ 자동 점수화, preview snapshot 스캔, preview 순위 점수를 모두 끈다. 틀린 tier로 이동시키거나 이전 시즌 snapshot으로 현재 시즌 순위를 매기지 않기 위한 것이다.
- `SeasonGuard.IsMismatched`의 판정은 `ItemLevelTable`을 아직 못 읽은 상태에서 **캐시하면 안 된다.** 그 시점의 판정을 굳히면 이후 데이터가 올라와도 영구히 "일치"로 남는다.
- 상단 안내는 한 줄 고정에 줄바꿈이 꺼져 있고 폭이 좁다. 시즌 이름을 그대로 붙이면 스탯 정책 요약이 잘리므로 `[S1]` 형태의 짧은 접두만 붙이고, 불일치 시 경고색을 함께 적용한다. 로케일 파일 소유가 달라 새 번역 키를 만들지 않고 데이터에서 유도한다.
- **Encounter Journal 열기에 `itemID`를 넘기지 않는다.** Blizzard가 Encounter Journal 아이템 툴팁 버튼을 secret sell-price 데이터로 만들기 때문에, 애드온이 소유한 클릭 경로에서 특정 아이템에 포커스를 주면 사용자가 전리품 행에 마우스를 올릴 때 그 툴팁 경로가 오염된 채로 남는다. Encounter Journal 열기 자체도 `pcall`로 보호한다.
- BIS 아이템 툴팁은 shopping tooltip 경로를 써서 sell price `MoneyFrame` 렌더링을 막는다. 이 플래그는 **단일 `SetHyperlink` 호출 동안만** 세우고, 애드온 소유 툴팁이 숨겨질 때 즉시 해제한다. 계속 켜 두면 다른 툴팁에 영향이 간다.
- difficulty 24(시간여행 던전)에서는 아이템이 스케일다운된 ilvl로 표시되므로 범위 검증을 우회한다. 이 예외를 빼면 시간여행 중 정상 아이템이 걸러진다.
- itemLink 파싱에서 `numBonusIDs` 앞의 필드 순서는 enchant, gem 4개, suffix, unique, link level, spec, mask, context다.
- 시즌 M+ 드랍은 구던 원본 품질이 파란색이어도 최소 에픽으로 보정해 표시한다.

## UI/ItemLevelOverlay.lua

- 안개문장(Mistcrest) 통화 ID는 2026-08-28 라이브 덤프로 확정했다. 시즌 1 Dawncrest(3383 / 3341 / 3343 / 3345 / 3347)와는 전혀 다른 신규 ID다.
- **함정**: 같은 이름의 통화가 3437~3441에도 있다. 그쪽은 `maxQuantity`가 0이고 대부분 미발견 상태다. 실제 사용 통화는 등급별 상한(300/300/300/200/200)이 잡힌 3442~3446 세트다. 이름으로 찾아 바꾸지 않는다.
- 오버레이는 파티찾기(`PVEFrame`)가 열려 있을 때만 표시한다. 이미 열려 있는 경우를 위해 초기화 시 즉시 시도하는 경로가 따로 있다.
- 시즌 2 월드 보스와 Lair는 야외부터 신화까지 난이도가 나뉜다. 시즌 1처럼 단일 항목만 있는 형태도 계속 렌더링해야 한다.

## UI/StatsOverlay.lua

- **WoW 12.1부터 전투, 쐐기, 전장, 레이드 조우 중에는 aura가 보호 상태가 된다.** index / slot / instanceID 기반 `C_UnitAuras` 조회를 애드온이 호출하면 Lua 오류가 난다. spellID 기반 조회는 정상이다.
- 실패 직후에는 backoff로 잠시 조회를 멈춘다. refresh마다 오류 경로를 다시 밟지 않게 하려는 것이고, 보호가 풀리면 backoff 만료로 저절로 복구된다.
- `GetTime`을 못 쓰는 상황에서는 backoff를 걸지 않는다. 만료를 판단할 수 없어 한 번 실패한 뒤 영구히 빈 hash가 되기 때문이다.
- aura hash는 부분적으로 남기지 않고 실패 시 **빈 값으로 통일**한다. 부분 hash를 남기면 보호 상태가 오갈 때마다 signature가 흔들려 불필요한 refresh가 발생한다.
- 보호된 player stat 값을 0으로 확정 표시하면 인던 진입 후 계속 0%처럼 보인다. 이 파일 내부에서는 보호값을 `nil`로 분리하고, 표시 단계에서 마지막 정상 값이나 명시적 fallback을 쓴다.
- `C_UnitAuras` 반환 테이블은 secret number라 직접 산술 시 taint 오류가 난다. `safeNumber`로 격리하고 산술·포맷 자체도 `pcall`로 감싸 한 aura가 실패해도 다음 aura 처리가 계속되게 한다.
- signature에는 인스턴스 컨텍스트(none/party/raid/pvp/scenario)와 활성 버프 hash가 들어간다. 전자는 인던 진입·이탈 시 stale signature를, 후자는 트링킷·물약·외부 버프로 인한 절대값 변동 미반영을 막는다. 둘 다 빼면 안 된다.
- signature 빌드, snapshot 빌드, priority text 빌드, `applyTextStyle` 옵션 테이블은 모두 재사용 버퍼다. 매 Refresh마다 테이블을 새로 만들지 않기 위한 의도적 구조다. `getDisplayClassName` 캐시는 로케일 로드 후 첫 호출에서 한 번만 만든다.

## Modules/BlizzardFrameManager.lua

- `MANAGED_FRAMES`의 `uiPanel=true`는 `ShowUIPanel` / `UpdateUIPanelPositions`가 OnShow 이후 위치를 덮어쓰는 계열이라는 표시다. 저장 좌표가 있을 때 `SetUserPlaced(true)` + 딜레이 복원이 필요하다. 런타임에 `UIPanelWindows`에 등록된 프레임도 같은 방식으로 감지한다.
- **`WorldMapFrame`과 `QuestLogFrame`은 의도적으로 제거됐다.** `WorldMapFrame`에 `SetMovable` / `ClearAllPoints` / `SetUserPlaced` 등 어떤 조작을 해도 내부 `QuestMapFrame` 레이아웃이 파괴될 수 있다. 3차례 수정 시도(ef47cdd, af67ad7, noRestore 플래그) 모두 완전 해결에 실패했다. 다시 추가하지 않는다. 이동 가능한 월드맵이 필요하면 MoveAnything 같은 전용 애드온을 쓴다.
- `WorldMapFrame`은 `MANAGED_FRAMES`와 완전히 분리된 드래그 전용 경로만 남겼다. `ClearAllPoints` / `SetPoint` / 위치 저장·복원을 일체 하지 않고, 세션 내 위치는 WoW의 `SetMovable` 동작이 알아서 보존한다.
- `StopMovingOrSizing`은 암묵적으로 `UserPlaced=true`를 설정한다. `WorldMapFrame`에 이 상태가 남으면 퀘스트 목록 패널 레이아웃이 파괴되므로 드래그 종료 직후 `false`로 되돌린다.
- 최대화(전체화면) 상태에서는 드래그를 막고 위치도 저장하지 않는다. 전체화면 좌표를 저장하면 다음 복원 때 윈도우 모드 레이아웃이 깨진다.
- 저장 좌표가 **없는** 기본 프레임은 `UserPlaced=false`로 두고 Blizzard의 기본 좌/우 패널 배치에 맡긴다. 처음부터 전부 `UserPlaced=true`로 고정하면 여러 기본 창이 같은 중앙 좌표에 겹친다.
- `UpdateUIPanelPositions`와 `ShowUIPanel`을 훅해 위치를 복원한다. 캐릭터창 탭 전환이나 인접 패널 닫힘으로 WoW가 배치를 재계산하는 경우 대응이다. 즉시 복원 외에 지연 복원이 한 번 더 필요한데, 탭 전환 후 WoW가 다음 프레임에서 위치를 재설정하기 때문이다. 지연 타이머는 중복 방지를 위해 하나만 유지한다.

## UI/MythicPlusRecordOverlay.lua

- 훅 설치는 특정 addon 이름에 의존하지 않는다. Blizzard가 M+ UI를 담는 addon 이름을 바꿔도 동작해야 하기 때문이다. `setupHooks`는 `ChallengesFrame`이 없으면 즉시 실패를 돌려주고 `_hooksReady`로 중복을 거르므로, 몇 번 호출되든 훅은 한 번만 설치된다.

## UI/SilvermoonMapOverlay.lua

- `LayoutPoints`는 핫패스라 매번 테이블을 만들지 않고 재사용 버퍼와 객체 풀을 쓴다(필터 통과 포인트 목록, `{point, nearbyCount}` 엔트리 풀, 배치 완료 rect 풀, 후보·best 평가용 임시 rect, 포인트당 16개 후보 오프셋 버퍼). GC 스파이크 방지가 목적이므로 "읽기 쉽게" 되돌리지 않는다.
- 재사용 버퍼는 매 run 시작 시 이전 run의 잔여 슬롯을 제거해야 한다. `table.sort` 범위를 정확히 제한하기 위한 것이다.
- `mapID → mapInfo` 캐시는 영구 캐시다. `mapInfo`는 세션 중 변하지 않으므로 매번 `pcall(C_Map.GetMapInfo)`를 부르지 않는다. 실패는 `false`로 저장한다.
- 시즌 신규 던전/공격대/구렁은 정적 좌표를 넣지 않고 `RuntimePoints`가 클라이언트에서 읽는다. 던전·공격대 입구는 `C_EncounterJournal.GetDungeonEntrancesForMap`, 구렁은 `C_AreaPoiInfo.GetDelvesForMap` + `GetAreaPOIInfo`가 출처다. 좌표를 하드코딩하면 패치마다 깨지고, 시즌 신규 지역은 외부 자료가 부정확하기 때문이다.
- 입구는 `Data/SilvermoonMapData.lua`의 `runtimeInstances`에 있는 journal instance만 받는다. 필터가 없으면 모든 구대륙 지도에 무관한 던전 이름이 쏟아진다. 목록에 없어도 `Data/BISEncounterJournal.lua`의 `instanceIDsByDungeon`에 있으면 던전으로 받아, BIS 데이터를 새 시즌으로 올리면 지도도 따라온다.
- `runtimeMaps`는 시즌 콘텐츠가 존재하는 대상 지도 목록이다. 구렁 POI와 지역 POI 기반 입구 보강은 정적 데이터가 있는 지도와 이 목록의 지도에서만 수행한다. 모든 월드맵을 훑으면 이 오버레이 범위를 벗어난다. 목록은 넓게 잡아도 안전하다. 해당 지도에 대상이 없으면 API가 빈 결과를 주기 때문이다.
- `GetDungeonEntrancesForMap`이 구대륙 지도에서 입구를 돌려주지 않는 경우가 있어, 대상 지도에서는 `C_AreaPoiInfo.GetAreaPOIForMap` + `GetAreaPOIInfo`로 한 번 더 훑는다. 판정은 시즌 인스턴스 이름과의 정규화 완전 일치만 받는다. 부분 일치를 허용하면 무관한 POI가 던전으로 올라온다.
- 시즌 인스턴스 이름 색인은 `EJ_GetInstanceInfo`가 한 건이라도 응답했을 때만 캐시한다. EJ가 아직 준비되지 않은 시점의 결과를 굳히면 세션 내내 이름 판정이 동작하지 않는다.
- 런타임 결과 캐시는 비어 있을 때 `emptyCacheSeconds`(2초)만 유지한다. POI/EJ 데이터는 지도를 연 직후 아직 준비되지 않을 수 있어, 그때의 빈 결과를 확정으로 굳히면 세션 내내 아무것도 표시되지 않는다. `AREA_POIS_UPDATED`도 캐시를 비운다.
- 좌표는 0 초과 1 미만만 받고, API 실패나 이름 누락은 조용히 건너뛴다. 잘못된 위치를 그리는 것보다 아무것도 그리지 않는 편이 낫다.
- 런타임 항목은 정적 항목과 이름·위치로 중복을 거른다. 이름 비교는 공백과 문장부호를 지우고, 9바이트 이상일 때만 포함 관계도 본다. 로케일 라벨(`Blinding Vale`)과 클라이언트 이름(`The Blinding Vale`)이 관사만큼 다르기 때문이다.

## UI/ProfessionKnowledgeOverlay.lua

- 폭 조정은 2 pass가 필요하다. `contentWidth`를 크게 잡아 측정하는 방식이라, 확정된 width 기준으로 각 row와 내부 텍스트 폭을 다시 맞추는 두 번째 pass가 없으면 잘린다.

## UI/StatPriorityDialog.lua

- 프레임은 `Show` 시점 지연 초기화다.
- `ScrollFrame:GetVerticalScrollRange()`가 한 프레임 뒤에야 갱신되는 경우가 있어 다음 프레임에서 스크롤바를 한 번 더 보정한다.

## UI/MainWindow.lua

- 탭 버튼 텍스트가 초기화 타이밍에 따라 보이지 않는 문제가 있어, OnShow 시점에 한 프레임 뒤로 미뤄 레이아웃 완료 후 locale을 다시 적용한다. 이 지연을 없애면 탭 텍스트가 빈 채로 남을 수 있다.

## UI/QuestPanel.lua · Modules/QuestManager.lua

- 퀘스트 패널이 보이지 않으면 전체 스캔을 건너뛴다. `QUEST_LOG_UPDATE` 고빈도 발화 시 CPU 낭비를 막기 위한 것이다. 대신 탭 전환(OnShow) 때 강제 갱신해 건너뛴 스캔을 보완한다. 둘은 한 쌍이므로 한쪽만 제거하면 패널이 stale해진다.
- `QuestManager`는 hidden / task 형태의 항목을 제외한다. 패널이 일반 퀘스트 로그와 같아 보이게 하기 위한 것이다.

## Modules/PrivateAurasGuard.lua

- Blizzard는 private aura와 일반 도움 버프 사이에서 `auraInstanceID` 값을 재사용할 수 있다. 중복처럼 보이는 두 항목은 진단용이므로 둘 다 남긴다.

## Modules/ActionBarApplier.lua

- 처리할 ghost가 없으면 조용히 종료한다. `ACTIONBAR_SLOT_CHANGED` 등이 매우 빈번해 빈 retry 로그가 디버그 버퍼를 폭주시키기 때문이다.
- skip 사유는 바뀔 때만 1회 로그한다. 같은 사유의 연속 호출은 억제한다.

## Modules/MerchantHelper.lua

현재 비활성 모듈이다(도안 감지 미동작). 되살릴 때 아래 제약이 그대로 적용된다.

- `C_Item.GetItemSpell`은 API 버전에 따라 `(spellName, spellID)`를 주기도 하고 단일 숫자를 주기도 한다. 두 번째 반환이 숫자면 `(name, spellID)` 형식, 첫 번째가 숫자면 단일 spellID 형식이다.
- 도안·레시피 spellID는 **10000 이상일 때만 신뢰한다.** 그 아래 값은 오탐이다.
- 아이템 ID 획득은 `C_MerchantFrame.GetItemInfo` → `C_MerchantFrame.GetMerchantItemID` → `GetMerchantItemLink`에서 추출 → 구 API `GetMerchantItemInfo` 순으로 폴백한다. 구 API는 일부 버전에서 9개만 반환해 itemID가 빠지므로 link에서 재시도한다. 순서를 바꾸지 않는다.
- 상점 슬롯 버튼 탐색도 명명 규칙 3가지를 순서대로 시도한다. 세 번째(`MerchantFrame` 자식 순회)는 느리므로 캐시 미스 시 1회만 돈다. 버튼 캐시는 페이지 넘김 대응을 위해 매 스캔마다 리셋한다.
- `MERCHANT_UPDATE`는 연속 발화하므로 throttle이 필요하다.

## Commands.lua

- AuctionHouse 진단 명령은 텍스트가 taint된 상황을 우회하려고 타입 기준(CheckButton)과 프레임 이름 기준으로 스캔한다. 텍스트 기반 탐색은 보조 수단이다.
- UIParent 순회에는 깊이 제한(6 / 12)이 걸려 있다. 제한을 풀면 프레임 트리 전체를 도는 비용이 발생한다.

## UI/MinimapButton.lua

- 드래그 중에는 DB를 읽지 않고 위치를 직접 계산한다. DB 저장과 정규 위치 갱신은 드래그 종료 시 한 번만 한다.

## UI/Widgets.lua

- readOnly EditBox에서 클릭 시 커서가 y=0으로 이동하며 스크롤이 상단으로 튕기는 문제가 있어 이를 막는 처리가 들어 있다.

## UI/WorldEventOverlay.lua

퀘스트 기반 자동 완료 감지는 비활성이다. 수동 토글만 동작한다.

- 완료 표시에 WoW 내장 ReadyCheck 아이콘을 쓴다. UTF-8 `✓`는 일부 폰트에서 깨진다.
- 일부 헬퍼는 `getEventState` 이후에 정의해야 한다. forward reference를 피하기 위한 순서다.
- OnUpdate 드라이버는 1초 간격이며 숨김 상태에서는 즉시 스킵한다.

## UI/UtilityPanel.lua · UI/ConfigPanel.lua

- 2열 그리드 치수는 창 폭 900px에서 content inset 16×2와 box 시작 오프셋 16을 뺀 유효 852px에서 계산했다. 열 폭은 `(852 - 40gap) / 2 ≈ 406`, 컬럼 내부 텍스트 폭은 382다. 창 폭이나 inset을 바꾸면 이 값들을 다시 계산해야 한다.
- 스탯·전문기술 오버레이 체크박스는 편의기능 탭으로 옮겨져 `ConfigPanel`에서는 숨김 처리돼 있다. 중복 노출로 되살리지 않는다.

## ABPM_ruRU_Final_v3.lua

- **로드 순서 제약**: `Locale.lua`, `Locale_Additions.lua`, `DB.lua`, `UI/ConfigPanel.lua` 이후에 로드해야 한다. TOC 순서를 바꾸지 않는다.
- 이 파일은 UIParent 스캔과 전역 `GameTooltip` 훅을 **의도적으로 하지 않는다.** 갱신은 ABProfileManager 컴포넌트에만 걸고, 툴팁 헬퍼도 애드온 전용 tooltip에만 적용한다.
- 키릴 문자 대소문자 변환은 Lua 5.1에서 신뢰할 수 없다. 자동 변환 대신 명시적 맵 항목을 쓴다.
- ruRU에서는 삼각형 기호 대신 ASCII를 쓴다. 기본 ruRU 폰트가 삼각형을 사각형으로 렌더링하는 경우가 있다.
- 병합 후 정적 locale 소스 테이블은 해제한다. 런타임 맵은 그대로 유지된다.
