# CODE_NOTES

## 목적

소스 Lua에서 주석을 전부 제거했다. 제거한 주석 중 "지우면 나중에 사고가 나는 것"만 골라 이 문서에 남긴다.

**소스에는 주석이 없으므로 코드 제약은 여기서 확인한다.** 값을 바꾸거나 구조를 손대기 전에 해당 파일 절을 먼저 읽는다.

여기 없는 내용은 자명한 설명이거나 함수명으로 드러나는 내용이라 버린 것이다. 코드와 이 문서가 어긋나면 코드가 사실이고, 이 문서를 고친다.

기준: v1.13.0 / Interface 120100 / WoW 12.1.0.

주석 제거는 `scripts/strip_lua_comments.py`가 담당하며, 동결 파일 9개와 `Data/ItemLevelTable.lua`의 `BISRewardProfiles` 블록은 제외 대상이다.

---

## Utils.lua

- 상태 메시지 접두는 `status_prefix_info` / `status_prefix_success` / `status_prefix_failure` 세 키로 나간다. 성공·실패 판정은 `failureMarkers`와 `successMarkers` 낱말표에 의존하므로 새 언어를 추가하면 이 표에도 낱말을 넣어야 `info` 밖으로 나간다. 이 heuristic은 특정 언어 전용이 아니라 세 언어 공통 경로다.
- 접두 중복 방지 가드는 `status_prefix_*` 값과 직접 대조한다. Lua 패턴의 문자 클래스는 바이트 집합이라 `[●◆▲■]` 같은 멀티바이트 기호 집합이 동작하지 않고, `|` 대안 문법도 없다. 예전 두 가드는 이 때문에 한 번도 참이 되지 않았다.
- 진단 출력은 로케일화하지 않는다. `/abpm debug`와 `/abpm copy`의 **본문**(`Diagnose`, `DiagnoseJournal`, `[AH Debug]`, `ns.Utils.Debug`)은 한국어로 두고, 창 제목·사용법·버튼 같은 UI 껍데기만 로케일 키를 쓴다. 진단은 개발자가 읽는 출력이라 언어를 섞으면 대조가 어렵다.
- `ABPM_ruRU_Final_v3.lua`가 `FormatStatusMessage`를 언어와 무관하게 덮어쓴다. `kind`가 `nil`이면 원본에 위임해 낱말표 분류를 살리고, `kind`가 오면 `status_prefix_*` 키로 접두를 만든다. 이 위임을 걷어내면 `kind` 없이 부르는 호출부 9곳이 전부 `안내`로 고정된다.
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

- 여러 파일에서 같은 본문으로 중복되던 헬퍼를 여기로 모았다. `Clamp`, `GetAverageItemLevel`, `IsKoreanLanguageSelected`, `SafeTooltipString`, `Colorize`, `FormatOffsetValue`, `IsEmptyRecord`, `BuildRecordSignature`다.
- 소비 파일은 원래 정의 자리에 `local name = ns.Utils.Name` 한 줄만 남긴다. 호출부를 건드리지 않아 회귀 범위가 좁고, `Utils.lua`가 TOC 파일 목록의 5번째(`Core` → `Constants` → `Locale` → `Locale_Additions` → `Utils`, TOC 13행)라 모든 소비자보다 먼저 로드되므로 별칭이 안전하다. `UI/ProfessionKnowledgeOverlay.lua`의 `isKoreanOverlay`와 `UI/SilvermoonMapOverlay.lua`의 `isKoreanLocale`도 이 별칭 방식으로 통일했다.
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

## Core.lua

- `isSettingsPanelVisible`은 `ConfigPanel.settingsFrame`뿐 아니라 `AddonSettingsPages.panels`의 하위 페이지도 본다. 상위 카테고리 패널만 보면, 메인 창을 다른 탭으로 열어 둔 채 Blizzard 설정의 ABPM 하위 페이지를 보고 있을 때 그 페이지가 실시간으로 갱신되지 않는다.
- `ns:RefreshUI()`는 메인 창이 열려 있을 때 **현재 탭의 패널 하나만** 갱신한다. 호출처가 40곳 넘고 대부분 체크박스 하나를 토글하는 경로라, 일곱 패널을 전부 돌리면 보이지도 않는 화면에서 슬롯 순회와 문자열 조립이 반복된다. 탭을 바꾸는 모든 경로가 `refreshCurrentTab`을 거치므로 숨은 패널은 표시될 때 갱신된다.
- Blizzard 설정 창이 따로 열려 있으면 그때만 `ConfigPanel`을 추가로 갱신한다.

## Events.lua

- `UNIT_AURA`, `UNIT_STATS`, `UNIT_ATTACK_POWER`는 `RegisterUnitEvent(..., "player")`로 등록한다. `RegisterEvent`로 등록하면 파티·공격대·네임플레이트의 모든 유닛분이 디스패처까지 올라와 `pcall`을 거친 뒤 버려진다. 20인 공격대 전투에서 초당 수백 건이다. 핸들러의 `unitToken` 검사는 그대로 둔다.
- 고스트 스윕(`refreshGhostsAndRetries`)은 `GHOST_REFRESH_DELAY` 디바운스를 거친다. `ACTIONBAR_SLOT_CHANGED`와 `UPDATE_BONUS_ACTIONBAR`는 액션바 편집과 자세 전환마다 발생하고, 스윕 한 번이 `GetButtonIndex()`로 전 버튼을 훑는다.
- `UI_ERROR_MESSAGE`는 은행 세션이 열려 있을 때만 문자열을 판정한다. 전투 중 "기력이 부족합니다" 같은 메시지가 초당 여러 번 오는데, 판정 결과는 어차피 세션 조건과 함께 쓰이므로 순서를 바꿔도 결과가 같다.
- `abpmIsAccountBankShown`은 `pcall(AccountBankPanel.IsShown, AccountBankPanel)`로 부른다. 클로저를 넘기면 호출마다 하나씩 만들어진다.
- 전문기술 갱신은 전문기술 오버레이가 켜져 있거나 전문기술 패널이 보일 때만 `RefreshQuestCache(true)`로 즉시 스캔한다. 그렇지 않으면 `MarkDirty`만 건다. `Tracker:IsQuestComplete`가 `RefreshQuestCache(false)`를 부르므로, 실제로 무언가를 평가할 때 한 번 스캔된다. 즉시 스캔은 완료 퀘스트 전체(오래 키운 캐릭터는 2만~4만)를 읽고 최소 2N번의 테이블 연산을 하며, 가방·루팅 이벤트마다 세 번 돈다.

## Modules/GhostManager.lua

- 고스트 오버레이는 **풀에서 꺼내 쓴다.** WoW에서 `CreateFrame`으로 만든 프레임은 회수되지 않으므로, 고스트가 해소될 때 참조만 버리면 액션 버튼 아래에 숨은 프레임이 영구히 쌓인다. 해소·교체 경로는 전부 `ReleaseOverlay`로 풀에 돌려주고 `AcquireOverlay`로 다시 꺼낸다.
- 풀에서 꺼낸 오버레이는 부모가 달라져 있으므로 `SetParent` 뒤에 `SetFrameLevel`을 다시 건다. 생성 시점의 프레임 레벨은 그때의 부모 기준이라 재사용에서는 맞지 않는다.
- `handleGhostDrop`과 `handleGhostDismiss`는 `overlay.logicalSlot`을 **먼저 지역 변수에 담는다.** 두 함수가 부르는 `ActionBarApplier`의 배치·해제 경로가 그 안에서 동기적으로 `RefreshGhosts`를 호출하고, 그때 해당 오버레이가 풀로 반납되며 `logicalSlot`이 지워진다. 이후 상태 메시지에서 다시 읽으면 슬롯 이름이 `0`으로 나온다.
- `ReleaseOverlay`는 `overlay._pooled`로 이중 반납을 막는다. 같은 오버레이가 풀에 두 번 들어가면 서로 다른 두 슬롯이 같은 프레임을 잡는다.

## Modules/BlizzardFrameManager.lua

- `makeFrameMovable`의 드래그 저장 훅은 모듈 로컬 `dragStopHookedFrames[key]`로 1회만 건다. `HookScript`는 해제할 수 없어서, 편의기능 체크박스를 껐다 켤 때마다 훅이 하나씩 쌓이고 드래그 한 번에 `saveFrameDB`가 그만큼 중복 실행된다.
- 이 표는 **프레임이 아니라 `key`로 기억한다.** 프레임 객체에 플래그를 쓰면 두 `MANAGED_FRAMES` 항목이 같은 프레임으로 해석될 때(예: 특성 UI가 `PlayerSpellsFrame`에 통합된 경우) 뒤 항목이 통째로 건너뛰어진다. 값에 프레임을 담아 두므로 getter가 나중에 다른 프레임을 돌려주면 다시 건다.
- `hasExisting`이 거짓인 분기에서도 이 표를 세운다. 세우지 않으면 두 번째 `Apply`에서 자기가 심은 `SetScript` 핸들러 위에 `HookScript`가 한 번 더 얹혀 드래그마다 `saveFrameDB`가 두 번 돈다.

## Modules/ProfessionKnowledgeTracker.lua

- `GetProfessionSections`는 `professionSectionsCache`에 `questCacheGeneration`을 함께 담아 기억한다. 인접한 `GetProfessionSummary`·`EvaluateSource`는 이미 캐시를 쓰는데 이 함수만 매번 섹션·행 테이블을 새로 만들었고, `ProfessionPanel:RefreshCard`가 카드마다 부른다.
- 새 캐시를 추가하면 `resetEvaluationCaches`와 `ABPM_ruRU_Final_v3.lua`의 `RURU.RefreshProfessionCaches` **양쪽**에 넣어야 한다. 한쪽만 넣으면 세대가 오른 뒤에도 이전 세대의 행이 남는다. 참고로 `sections[i].title`을 읽는 소비자는 없다. 패널과 오버레이는 제목을 `ns.L`로 직접 만들고 `rows`만 가져간다.

## UI/QuestPanel.lua · UI/ConfigPanel.lua

- `queueRefresh`는 즉시 1회와 0.45초 뒤 1회만 강제 스캔한다. 이전에는 0.15초 지점까지 세 번이었다. `QuestManager:Scan(true)`는 퀘스트 로그 전체를 다시 훑고 배열 3개를 정렬한다. 지연 스캔은 토큰으로 중복을 막는다.
- 이미 보이는 퀘스트 탭을 다시 선택하면 `SetShown(true)`가 no-op이라 `OnShow`가 발화하지 않는다. `refreshCurrentTab`은 `QuestPanel._lastForcedScanAt`이 **이번 프레임**이 아닐 때만 강제 스캔한다. `GetTime()`은 프레임 안에서 값이 같으므로, `OnShow`가 방금 강제 스캔했으면 건너뛰고 아니면 직접 건다.
- 탭 전환 시 강제 스캔은 기본적으로 `frame` `OnShow`에 둔다. `refreshCurrentTab`도 강제로 부르면 `SetShown`이 `OnShow`를 동기 발화한 직후 한 번 더 돌아 클릭 한 번에 두 번 스캔한다. `isRefreshing` 가드는 재진입만 막고 연속 호출은 막지 못한다.
- `ConfigPanel:Refresh`는 Blizzard 설정 창이 보일 때만 `settingsRefs`를 갱신하고, `AddonSettingsPages:Refresh`는 실제로 표시된 페이지만 갱신한다. 각 페이지에 `OnShow` 갱신이 이미 있어 표시 시점 정확성은 유지된다.

## Data/ProfessionKnowledge.lua

- 주간 퀘스트는 직업마다 변형이 여러 개고 `match = "any"`로 묶는다. 그 주에 걸린 변형 하나만 완료되면 되므로 **변형 목록에서 questID가 하나라도 빠지면 그 주에는 완료를 감지하지 못한다.**
- 12.1 questID 블록은 연속 구간이다. 제작 7종이 `93690~93696`으로 각 1개, 마법부여 `93697~93699`, 약초채집 `93700~93704`, 채광 `93705~93709`, 무두질 `93710~93714`다. 2026-09-04에 `93697`, `93701`, `93707`, `93713`이 빠져 있던 것을 채웠다. 구간에 구멍이 보이면 누락을 의심한다.
- `treatise` questID(`95127~95131`, `95133~95138`)는 와우헤드에 노출되지 않는 숨은 퀘스트다. DB2 `QuestV2` 존재 확인까지만 가능하고 이름 대조는 인게임에서 한다. `95132`는 DB2에는 있지만 논문 퀘스트가 아니다.

## Data/WorldEventSchedule.lua

- 이벤트마다 `cadence`가 주기 종류를 정한다. `weekly`(살데릴의 연회, 하라니르의 전설), `interval`(스토마리온 공격 30분), `rotating`(풍요 8시간마다 4개 지역 순환, 창 3분)이다. 이전의 단일 `interval`/`duration`/`offset` 분 단위 모델은 네 이벤트 중 어느 것과도 맞지 않아 버렸다.
- 이벤트 이름과 지역은 2026-09-04 재확인했다. `Saltheril's Soiree/살데릴의 연회`는 영원노래 숲(`2395`), `Stormarion Assault/스토마리온 공격`은 공허폭풍(`2405`), `Legends of the Haranir/하라니르의 전설`은 하란다르(`2413`)다. 이전 데이터의 `2444`(공허폭풍 하위 지도 `Slayer's Rise`)와 풍요의 `2393`(실버문)은 틀린 값이었다.
- 풍요의 4개 동굴 좌표는 외부 가이드 2종이 일치한 값이다. `Watha'nan Crypts`(영원노래 숲 56.78/65.79), `Loaknit Den`(줄아만 31.62/26.14), `Floaret Grotto`(하란다르 66.14/61.69), `Abundant Voidburrow`(공허폭풍 38.82/53.31). 동굴 한글명은 공식 출처를 찾지 못해 지역명만 쓴다.
- `anchorVerified`와 `rotationVerified`는 둘 다 `false`다. **주기의 기준시각과 순환 순서를 아직 모른다.** 이 플래그가 `false`인 동안 오버레이는 카운트다운을 만들어내지 않고 `미확인` 상태로 표시한다. 인게임에서 기준시각을 재면 `anchor`(서버 시각 초)를 넣고 플래그를 올린다.
- `areaPoiID`는 DB2에서 확인한 값이다(연회 `8600`, 전설 `8423`). 이 값이 있으면 런타임 `C_AreaPoiInfo.GetAreaPOISecondsLeft`가 정답이므로 정적 계산보다 먼저 쓴다. 스토마리온 공격과 풍요의 POI ID는 아직 모른다.
- 좌표(`x`/`y`, 0~100 퍼센티지)는 외부 가이드 값이고 인게임 미실측이다.
- 시각 계산은 `GetServerTime()` UTC 기준이다.

## UI/SilvermoonMapOverlay.lua

- `resolveDisplayText`는 포인트별로 결과를 약한 키 테이블에 기억한다. 한국어 경로는 글자 단위 배열과 청크 테이블, `table.concat`을 여러 번 거치는데, 결과는 포인트와 언어에만 의존한다. 확대·축소로 `layoutKey`의 버킷이 바뀔 때마다 68개 포인트분을 통째로 다시 계산했다.
- `LayoutPoints`는 포인트 집합이 그대로면 `getNearbyCount`를 다시 돌리지 않는다. 이 값은 좌표에만 의존하고 확대 배율과 무관하다. 런타임 포인트는 무효화 때 새 테이블로 만들어지므로 객체 동일성 비교로 충분하다.
- **비교 대상은 `_layoutPrevPoints`이지 `_layoutEntries`가 아니다.** `_layoutEntries`는 호출 끝에서 `table.sort`로 제자리 정렬되므로, 다음 호출에 `_layoutPoints`(소스 순서)와 맞대면 거의 항상 첫 인덱스에서 어긋나 빠른 경로가 죽는다.
- 길이 비교는 `>=`가 아니라 `==`다. `HideAll()` 조기 반환 경로는 `_layoutEntries` 꼬리를 잘라내지 않아서, `>=`로 두면 포인트가 줄어든 뒤 앞쪽이 일치할 때 사라진 포인트를 포함한 `nearbyCount`가 그대로 쓰인다.
- `CollectEntrances`는 `RuntimePoints.GetSeasonNames()`를 **처음 필요할 때 한 번만** 부른다. 이 함수는 `ejResolved > 0`일 때만 결과를 캐시하므로, 루프 안에 두면 Encounter Journal이 아직 응답하지 않는 구간에서 엔트리마다 전체 재구축이 돈다. 루프 밖으로 무조건 올리면 이번엔 모든 엔트리가 `GetInstanceCategory`로 풀리는 경우까지 한 번씩 스윕한다.

## UI/ItemLevelOverlay.lua 풍요 구렁 캐시

- 풍요로운 구렁 이름을 하나도 못 찾으면 그 사실을 `BOUNTIFUL_DELVE_EMPTY_TTL` 동안 기억한다. 빈 결과를 캐시하지 않으면 `DELVE_MAP_IDS` 6개 지도 × POI 전수 조회가 호출마다 반복되고, `RefreshSidePanel`은 이것을 두 번 부른다. `AREA_POIS_UPDATED`가 캐시를 무효화하므로 시즌 구렁 POI가 없는 지역에서는 영원히 반복됐다.
- `InvalidateBountifulDelveNamesCache`는 실패 TTL도 함께 지운다. 남기면 로딩 중 빈 결과로 TTL이 서고, 직후 실제 POI가 올라와 `AREA_POIS_UPDATED`가 무효화해도 스캔이 막혀 `알 수 없음`이 남는다. **TTL 만료 자체는 갱신을 트리거하지 않으므로** 지연이 TTL 길이로 끝나지 않고 다음 refresh 트리거까지 이어진다.
- throttle 이득은 그대로다. 이 함수를 한 refresh 안에서 두 번 부르는 `RefreshSidePanel` 경로에는 무효화 이벤트가 끼어들지 않는다.

## UI/StatsOverlay.lua

- 버프 hash는 `_buffHashCache`에 담고 `UNIT_AURA`와 `InvalidateState`에서만 비운다. hash는 오라가 바뀔 때만 달라지는데, `COMBAT_RATING_UPDATE` 같은 다른 트리거의 refresh마다 40칸 `pcall` 순회를 처음부터 다시 했다. 백오프로 빈 문자열을 돌려주는 경로는 캐시하지 않는다.
- `pcall`에 익명 클로저를 넘기지 않는다. `pcall(function() return value + 0 end)` 형태는 호출마다 upvalue를 잡는 클로저를 힙에 만든다. `toPlainNumber`는 refresh 1회에 55~115번 불리고 refresh는 최대 초당 6.7회이므로 초당 수백 개가 쌓인다. 인자를 받는 모듈 레벨 함수(`addZero`, `numberFromString`, `indexField`, `readColorParts`, `valuesMatch`)를 `pcall`에 넘긴다.
- `_textStyleOptions`는 재사용 버퍼다. `Typography:ApplyFont`가 이 버퍼를 복사해 보관하므로 버퍼 자체는 매번 새로 만들지 않아도 된다.

## UI/Typography.lua

- `ApplyFont`가 보관 중인 `options` 테이블과 호출자가 넘긴 테이블이 같은 객체면 재사용 분기를 타지 않는다. `wipe`가 원본을 먼저 비워 설정이 통째로 사라진다.
- `ApplyFont`의 등록 항목은 **재사용한다.** 매번 `{ baseSize, options = shallowCopy(options) }`를 새로 만들면 호출자가 재사용 버퍼를 넘겨도 의미가 없다. `StatsOverlay`의 행 스타일 적용만으로 refresh당 35~50회 불리므로 테이블 70~100개가 즉시 쓰레기가 된다. 기존 항목이 있으면 `baseSize`를 덮어쓰고 `options` 테이블을 `wipe` 후 다시 채운다.

## ABPM_ruRU_Final_v3.lua 성능

- 치환은 `applyReplacements`가 담당하고 키를 **길이 내림차순으로 고정 정렬해** 적용한다. `pairs` 순서에 맡기면 짧은 키가 먼저 걸려 `" pts"`가 `" оч.s"`가 되고 `"Demon Hunter"`가 `"Demon 사냥꾼"`이 된다. 정렬 결과는 맵별로 한 번만 만들어 약한 키 테이블에 보관한다.
- 이 정렬은 키가 서로의 접두·부분 문자열인 쌍(`" pt"`/`" pts"`, `"Weekly Quest"`/`"Trainer Weekly Quest"`, `"Hunter"`/`"Demon Hunter"`, `"Охотник"`/`"Охотник на демонов"`)만 바꾼다. 그 외에는 결과가 같다.
- 키가 Lua 패턴으로 쓰이므로 `"Crit"`은 `"Critical"` 안에서도 매치된다. 길이 정렬로는 못 막는다. 남아 있는 결함이다.
- `applyReplacements`는 `gsub` 전에 `find(..., 1, true)`로 평문 포함 여부를 먼저 본다. 치환 키에 Lua 패턴 메타문자가 없어 결과가 같고, 대부분의 줄은 어느 키도 포함하지 않으므로 `gsub`의 패턴 컴파일과 결과 문자열 할당이 통째로 사라진다. 스탯 오버레이는 FontString 하나당 39개 키를 돌고 `StatsOverlay:Refresh`마다 실행된다.
- `patchTextRegions`는 깊이별 스크래치 버퍼를 재사용한다. `{ frame:GetRegions() }`와 `{ frame:GetChildren() }`는 노드마다 테이블 2개를 만든다.
- 버퍼를 공유하므로 `patchStatsOverlayText`에 재진입 가드를 둔다. 순회 중 `SetText`가 다른 refresh를 유발하면 상위 루프가 쓰던 버퍼가 덮어써진다. 현재 대상은 스크립트가 없는 FontString뿐이라 발생하지 않지만, 대상이 늘면 바로 깨진다.
- 툴팁 후처리는 `tip:NumLines()`까지만 돈다. 이전에는 줄 수와 무관하게 항상 80회를 돌며 전역 이름 문자열 160개를 만들었다. 러시아어가 아니면 원본 호출 직후 반환한다.
- 래퍼가 감싸는 `Widgets.ApplyTooltip`과 `StatsOverlay:Refresh`는 **반환값이 없다.** `{ original(...) }` + `unpack`으로 반환값을 보존할 필요가 없고, 그 테이블은 호출마다 버려진다.

## Data/Defaults.lua · DB.lua

- BIS 신화 preview snapshot 캐시의 기본값은 **비워 둔다.** 첫 접근에서 현재 시즌을 채우는 구조다. `mythPreviewCache = {}`여야 하며 `schemaVersion`·`baselineItemLevel`·`generatedPreviewBonusListID` 같은 값을 여기에 적지 않는다. `Utils.MergeDefaults`가 로그인마다 `nil` 키를 기본값으로 되채우므로, 기본값에 값이 들어 있으면 `GetBISOverlayMythPreviewCache`의 불일치 판정이 매번 참이 되어 **캐시가 로그인마다 통째로 폐기된다.**
- `worldEventCompletions`는 `{ [eventKey] = "YYYY-MM-DD" }` 형태다. 키에 날짜를 붙이면(`eventKey_YYYY-MM-DD`) 만료 경로가 없어 계정 파일에 무한히 쌓인다. 값이 문자열이 아닌 항목은 이전 형식이라 조회할 때 지운다.
- 이 정리는 **세션 플래그로 한 번만 돌리지 않는다.** `GetGlobalSettings`는 `ns.db`가 아직 없으면 `Data/Defaults.lua`의 테이블을 돌려주므로, `DB:Initialize` 전에 한 번이라도 불리면 플래그가 기본값 테이블 기준으로 서고 실제 저장 테이블은 그 세션 내내 정리되지 않는다. 항목 수가 이벤트 수로 고정돼 있어 매번 훑어도 비용이 없다.
- snapshot은 그 시즌의 아이템 레벨 기준으로 검증한 값이다. 기존 무효화 조건은 전부 `Data/BISMythicVaultLinks.lua`에서 오기 때문에, 시즌이 바뀌어도 그 파일이 그대로면 이전 시즌 snapshot이 계정 SavedVariables에 계속 남는다. 그래서 **현재 시즌을 캐시 키에 포함**해 시즌이 넘어갈 때 한 번 비운다. 이 키에서 시즌을 빼지 않는다.

## UI/BISOverlay.lua

- 이 파일의 top-level local은 현재 `195`개다. `scripts/validate_bis_tooltip_contract.py`가 세는 값이며(선언된 이름 수, `LocalAssign` targets + `LocalFunction`) 예산은 `198`, Lua 스코프당 상한은 `200`이다. **새 top-level local을 추가하면 파일이 컴파일되지 않을 수 있다.** helper는 전부 기존 테이블의 필드로 넣는다.
- `SeasonGuard.dataSeason`은 동결된 BIS 정적 데이터(`Data/BISCatalog.lua`, `BISMythicVaultLinks.lua`, `BISSeasonPreviewLinks.lua`, `BISEncounterJournal.lua`)가 기준으로 삼는 시즌이다. BIS 데이터를 갱신할 때 이 값도 함께 올린다.
- `getAllSpecs`는 `BISOverlay._allSpecsCache`에 결과를 담는다. 캐시 키는 플레이어 직업, 직업 수, 언어다. `Refresh()` 한 번에 `EnsureTabs`·`UpdateSpecPickerButton` 경로로 5~7번 불리는데, 매번 40개 전문화 테이블을 만들고 정렬했다.
- **부분 결과를 캐시하지 않는다.** 직업 이름이 하나라도 비었거나 수집한 전문화 수가 `GetNumSpecializationsForClassID` 합계와 다르면 저장을 건너뛴다. 캐시 키가 그 뒤로 바뀌지 않으므로, 덜 올라온 데이터를 굳히면 세션 내내 남는다. `SeasonGuard.IsMismatched`에서 이미 금지한 것과 같은 형태다.
- 캐시된 배열은 `frame.specPicker.items`로도 나간다. **불변으로 다룬다.** 이 배열을 정렬하거나 원소를 고치면 캐시가 오염된다.
- `EJournal.ShouldRetry(store, key, cooldown)`는 실패한 스캔을 잠시 막는다. Encounter Journal은 로그인 직후나 데이터가 덜 올라온 구간에서 빈 결과를 돌려주는데, 실패를 기록하지 않으면 호버할 때마다 `EJ_SelectTier`·`EJ_SelectInstance` 왕복 전체가 다시 돈다. **성공을 기록하는 `scannedTiers`·`lootScanned`가 먼저 걸러지므로 성공 경로는 막지 않는다.**
- 이 함수는 실패 시각을 그대로 저장하고 `now > attemptedAt`일 때만 막는다. `GetTime()`은 한 프레임 안에서 값이 같으므로 **같은 프레임의 두 번째 시도는 통과한다.** Encounter Journal은 조회 자체가 데이터를 채우는 API라 첫 호출이 실패하고 두 번째가 성공하는 패턴이 있다. 행 `OnEnter`가 `ResolveEntryLoot`를 부르고 이어지는 툴팁이 `GetEntryBossName`으로 한 번 더 부르는 것이 그 경로다. `now < attemptedAt`으로 막으면 이 재시도가 사라진다.
- `MatchRaidBoss`가 `EJournal.lastMatchPoolSize`에 실제로 훑은 풀 크기를 남긴다. `FindRaidTargetByBoss`의 음수 캐시 조건이 `#EJournal.raidInstances > 0`이었는데, 그 배열은 `ScanTierBucket`만 채우고 `MatchRaidBoss`의 폴백 풀은 지역 변수라, 티어 스캔 전에는 음수 캐시가 **영영 저장되지 않았다.** 폴백 풀을 `raidInstances`에 병합하면 안 된다. 그 배열은 전 티어 검색의 입력이고 폴백 풀은 현재 시즌만 담는다.
- 풀 크기만으로는 부족해서 `lastMatchPoolTrusted`를 함께 본다. 티어 스캔이 한 번도 성공하지 않은 상태에서도 `GetSeasonRaidInstances()` 폴백은 레이드 버킷만 훑어 0이 아닌 값을 돌려줄 수 있고, 그때 조우 목록이 비어 있으면 매치가 실패한다. 그 실패를 `false`로 굳히면 `bossTargetCache`를 비우는 경로가 `DiagnoseJournal` 뿐이라 세션 내내 남는다.
- `SourcePreview.raidLocationLabels`는 호버마다 만들던 12원소 배열이다. 첫 사용 때 정규화 결과를 `raidLocationLookup`으로 한 번만 만들어, 호출당 `normalizeCompareText`가 13회에서 1회로 준다.
- `SourcePreview.tooltipTextKeys`는 툴팁 라인 루프 **안에서** 만들던 3원소 배열이다. 툴팁 한 건이 20~30라인이라 호출당 테이블이 그만큼 생겼다.
- `resolveSeasonDungeonName`은 `EJournal.GetSeasonDungeonNameCache()`로 결과를 기억한다. 미스일 때 던전 8종을 돌며 `normalizeCompareText`(`gsub` 3회)를 반복하는데, `getEntrySourceType`이 첫 줄에서 이 함수를 부르고 그 `getEntrySourceType`이 `compareSlotEntries` 즉 `table.sort` 비교자 안에서 불린다. 해결 실패는 `false`로 캐시한다. 캐시는 언어가 바뀌면 통째로 버린다.
- `Data/ItemLevelTable.lua`의 시즌이 `dataSeason`과 다르면 BIS 후보·템렙·Encounter Journal tier가 현재 시즌과 맞지 않는다. 이때 Encounter Journal 자동 랜딩, M+ 자동 점수화, preview snapshot 스캔, preview 순위 점수를 모두 끈다. 틀린 tier로 이동시키거나 이전 시즌 snapshot으로 현재 시즌 순위를 매기지 않기 위한 것이다.
- `SeasonGuard.IsMismatched`의 판정은 `ItemLevelTable`을 아직 못 읽은 상태에서 **캐시하면 안 된다.** 그 시점의 판정을 굳히면 이후 데이터가 올라와도 영구히 "일치"로 남는다.
- 상단 안내는 한 줄 고정에 줄바꿈이 꺼져 있고 폭이 좁다. 시즌 이름을 그대로 붙이면 스탯 정책 요약이 잘리므로 `[S2]` 형태의 짧은 접두만 붙이고, 불일치 시 경고색을 함께 적용한다. 로케일 파일 소유가 달라 새 번역 키를 만들지 않고 데이터에서 유도한다.
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
- `getEventState`의 판정 순서는 `areaPoiID` 런타임 조회 → `weekly`(`C_DateAndTime.GetSecondsUntilWeeklyReset`) → `anchorVerified`가 참일 때만 정적 주기 계산이다. 어느 것도 못 풀면 `unknown`을 돌려주고 타이머 자리에 `-`를 찍는다. **기준시각을 모르는 이벤트에 가짜 카운트다운을 그리지 않는다.**
- TomTom 경로점 정리는 `syncWaypoints` 하나에만 있고 그것은 `UpdateContent` 맨 끝에서만 돈다. `UpdateContent`는 접힘·비활성·던전 자동 접기에서 그 전에 반환하므로 **그 경로마다 `clearAllEventWaypoints`를 따로 불러야 한다.** 부르지 않으면 이벤트가 끝나도 화살표와 미니맵 핀이 남는다. 호출 지점은 던전 자동 접기, 수동 접기, 비활성, `PLAYER_LOGOUT` 네 곳이다.
- `PLAYER_LEAVING_WORLD`에서는 정리하지 않는다. 이 이벤트는 존 이동과 로딩 화면마다 발생하므로, 정리하면 1초 뒤 `OnUpdate`가 경로점을 다시 만들어 TomTom의 현재 대상만 초기화된다. 던전 진입은 뒤따르는 `PLAYER_ENTERING_WORLD` 자동 접기 분기가 이미 덮는다.
- `rotating` 이벤트는 위치가 고정이 아니다. `getEventPlacement`가 mapID/좌표/지역 라벨을 함께 돌려주고, 풀리지 않으면 TomTom 경로점을 만들지 않는다. 툴팁 지역명도 이 결과를 쓴다.
- 카운트다운 포맷은 `world_event_timer_hm` / `_ms` / `_s` 로케일 키에서 온다. 이전에는 `시간`/`분`/`초`가 소스에 박혀 있어 영어·러시아어에서도 한국어가 나왔다.

## UI/UtilityPanel.lua · UI/ConfigPanel.lua

- 2열 그리드 치수는 창 폭 900px에서 content inset 16×2와 box 시작 오프셋 16을 뺀 유효 852px에서 계산했다. 열 폭은 `(852 - 40gap) / 2 ≈ 406`, 컬럼 내부 텍스트 폭은 382다. 창 폭이나 inset을 바꾸면 이 값들을 다시 계산해야 한다.
- 스탯·전문기술 오버레이 체크박스는 편의기능 탭으로 옮겨져 `ConfigPanel`에서는 숨김 처리돼 있다. 중복 노출로 되살리지 않는다.

## ABPM_ruRU_Final_v3.lua

- **로드 순서 제약**: `Locale.lua`, `Locale_Additions.lua`, `DB.lua`, `UI/ConfigPanel.lua` 이후에 로드해야 한다. TOC 순서를 바꾸지 않는다.
- 이 파일은 UIParent 스캔과 전역 `GameTooltip` 훅을 **의도적으로 하지 않는다.** 갱신은 ABProfileManager 컴포넌트에만 걸고, 툴팁 헬퍼도 애드온 전용 tooltip에만 적용한다.
- 키릴 문자 대소문자 변환은 Lua 5.1에서 신뢰할 수 없다. 자동 변환 대신 명시적 맵 항목을 쓴다.
- ruRU에서는 삼각형 기호 대신 ASCII를 쓴다. 기본 ruRU 폰트가 삼각형을 사각형으로 렌더링하는 경우가 있다.
- 병합 후 정적 locale 소스 테이블은 해제한다. 런타임 맵은 그대로 유지된다.
