# ABProfileManager Changelog

이 문서는 `ABProfileManager`의 버전 이력을 정리한 파일입니다.

주의:
- `1.0.0` 이전 항목은 실제 개발 진행 내용을 기준으로 정리한 내부 이력입니다.
- `1.0.0`이 첫 완료 릴리스 기준 버전입니다.

## 1.13.0 - 2026-09-03

시즌 2 인게임 QA에서 확인된 로드 오류와 오버레이 결함을 고치고, 시즌 2 데이터를
와우헤드/DB2로 재검증하고, 영어 표시 결함을 정리한 로컬 릴리스.

2026-09-04 M+ preview selector 확정:
- 인게임에서 `GetDetailedItemLevelInfo("item:268209::::::::::::1:12849")`가 `318`을
  돌려주어 시즌 2 Myth 1/6 selector를 `12849`로 확정했다.
  `Data/BISMythicVaultLinks.lua`의 `generatedPreviewBonusListID`를 `nil`에서 올리고,
  `scripts/validate_bis_mythic_vault_links.py`의 고정값과
  `scripts/validate_season2_scope.py`의 동결 해시를 함께 갱신했다.
- 이로써 M+ 자동 점수화와 preview 툴팁이 다시 동작한다. `Data/Defaults.lua`의
  `mythPreviewCache`를 앞서 빈 테이블로 고쳐 두지 않았다면 이 값을 넣는 순간
  로그인마다 캐시가 폐기됐을 것이다.
- `Data/BISSeasonPreviewLinks.lua`의 raid/tier/crafted selector는 아직 확인 전이라
  그쪽 hover만 기본 `itemLink`로 표시된다.

2026-09-04 낮음 등급 교차 검토 반영:
- `Mixin()`은 함수를 프레임 테이블로 복사하므로 믹스인 `SetUp`을 훅해도 그 전에
  만들어진 아이콘에는 반영되지 않는다. `mixinSetUpHooked`만 보고 인스턴스 훅을
  전부 건너뛰면 `Blizzard_ChallengesUI`가 먼저 로드된 경우 그 아이콘들이 영영
  갱신되지 않는다. `rawget(icon, "SetUp")`이 훅된 믹스인 함수와 같을 때만 건너뛴다
- 데이터 이벤트에서 재시도 상한을 통째로 되돌리는 대신 2만 회복시킨다. 아무것도
  회복시키지 않으면 상한이 소진된 뒤 이벤트 없이 늦게 채워지는 데이터를 잡지 못해
  창을 닫았다 열어야 했다
- 재사용한 탭은 `spec.icon`이 없을 때 텍스처를 지운다. 지우지 않으면 이전 전문화
  아이콘이 남는다. 조기 반환 판정에 첫 탭의 `specName`도 함께 봐서, 언어를 바꿔도
  전문화 수가 같으면 툴팁이 이전 언어로 남던 것을 고쳤다
- 프런티어 적용 조건을 `^%a$` 또는 `^%a[%a ]*%a$`로 좁혔다. 끝이 공백인 키까지
  받으면 `%f[%A]` 직전이 공백이라 영원히 매치되지 않아 치환이 조용히 사라진다
- `getRuObjectiveName`이 자기 본문에서 `isRuRU()`를 확인한다. 가드가 호출자에만
  있으면 노출된 `RURU.GetRuObjectiveName`을 언어 분기 없이 부르는 순간 457항목
  표가 만들어져 지연 생성이 무의미해진다

2026-09-04 낮음 등급 8건 정리:
- `EnsureTabs`가 탭 프레임을 인덱스로 재사용한다. `frame.tabs = {}`로 버리면 WoW
  프레임은 회수되지 않아 이전 버튼이 영구히 남았다. 판정 기준도 `#frame.tabs`가
  아니라 `frame.tabsSpecCount`로 바꾸고 핸들러는 생성 시 한 번만 붙인다
- 스크롤바 썸의 `OnUpdate`를 창 `OnHide`에서 해제한다. 드래그 도중 `PVEFrame`이
  닫히면 `OnMouseUp`이 오지 않아 드라이버가 살아남았다
- `SetUp` 훅을 믹스인 쪽만 건다. 믹스인과 인스턴스를 둘 다 훅해 아이콘 하나의
  `SetUp` 한 번에 `RefreshIcon`이 두 번 돌았다
- 데이터 이벤트에서 재시도 상한을 초기화하지 않는다. `Refresh`가 부른
  `RequestMapInfo`의 응답이 그 이벤트 목록에 있어, 아이콘이 안 그려지는 상황에서
  `ChallengesFrame`이 열린 내내 1초 주기 루프가 유지됐다
- `UtilityPanel:Create`에 재진입 가드를 넣었다
- 월드 이벤트 행의 완료 토글을 `OnClick` 하나로 모았다. `OnMouseDown`에도 같은
  토글이 있어 좌클릭 한 번에 누름과 뗌이 각각 토글해 상태가 제자리로 돌아왔다
- ruRU 치환에서 ASCII 글자·공백으로만 된 키는 프런티어 패턴을 써 낱말 경계에서만
  맞춘다. `"Crit"`이 `"Critical Strike"` 안에서 매치돼 `"치명ical Strike"`가 됐다
- `OBJECTIVE_NAMES_RURU`(457항목)를 지연 생성한다. 읽는 곳이 전부 `isRuRU()` 뒤라
  한국어·영어 클라이언트에서는 테이블이 만들어지지 않는다

2026-09-04 2차 교차 검토 반영:
- `getAllSpecs`가 부분 결과를 캐시하지 않는다. `#specs > 0` 가드는 전부 비었을 때만
  막아, 직업 정보나 전문화 정보가 덜 올라온 순간의 결과가 굳으면 캐시 키가 그 뒤로
  바뀌지 않아 세션 내내 남았다. 직업 이름 누락과 전문화 수 합계를 함께 본다
- `FindRaidTargetByBoss`의 음수 캐시에 `lastMatchPoolTrusted` 조건을 더했다. 티어
  스캔이 실패해도 시즌 폴백 풀은 레이드 버킷만 훑어 0이 아닌 값을 돌려줄 수 있고,
  그 상태의 매치 실패를 굳히면 `bossTargetCache`를 비우는 경로가 진단 명령뿐이라
  세션 내내 보스가 잡히지 않는다
- `EJournal.ShouldRetry`가 실패 시각을 저장하고 `now > attemptedAt`일 때만 막는다.
  `GetTime()`은 프레임 안에서 값이 같으므로 같은 프레임의 두 번째 시도가 통과한다.
  Encounter Journal은 조회 자체가 데이터를 채우는 API라 행 호버가 부르는
  `ResolveEntryLoot`와 이어지는 툴팁의 `GetEntryBossName`이 그 재시도 짝이다.
  쿨다운도 5초에서 2초로 낮췄다
- 지도 레이아웃의 포인트 집합 비교 대상을 `_layoutPrevPoints`로 분리했다.
  `_layoutEntries`는 호출 끝에서 정렬되므로 소스 순서와 맞대면 빠른 경로가 죽는다.
  길이 비교도 `>=`에서 `==`로 바꿨다. `HideAll()` 조기 반환이 꼬리를 잘라내지 않아
  포인트가 줄어든 뒤 낡은 `nearbyCount`가 쓰일 수 있었다
- `RuntimePoints.GetSeasonNames()`를 처음 필요할 때만 부른다. 루프 밖으로 무조건
  올리면 모든 엔트리가 다른 경로로 풀리는 경우까지 한 번씩 스윕한다
- `InvalidateBountifulDelveNamesCache`가 실패 TTL도 지운다. 남기면 로딩 중 빈 결과로
  선 TTL이 직후 도착한 POI 신호를 삼키고, TTL 만료는 갱신을 트리거하지 않아
  다음 refresh까지 `알 수 없음`이 남았다
- 이미 보이는 퀘스트 탭을 다시 선택하면 `OnShow`가 발화하지 않아 강제 스캔이
  사라졌다. `refreshCurrentTab`이 마지막 강제 스캔 시각을 보고 이번 프레임이
  아니면 직접 건다

2026-09-04 보통 등급 경로 정리:
- `UI/BISOverlay.lua`의 `getAllSpecs`를 캐시한다. `Refresh()` 한 번에 5~7번 불리며
  매번 40개 전문화 테이블을 만들고 정렬했다
- Encounter Journal 스캔 실패에 재시도 쿨다운을 뒀다. 실패를 기록하지 않아
  호버할 때마다 `EJ_SelectTier`·`EJ_SelectInstance` 왕복이 통째로 반복됐다
- `MatchRaidBoss`가 실제로 훑은 풀 크기를 남겨 `FindRaidTargetByBoss`의 음수 캐시가
  저장되게 했다. 이전 조건 `#EJournal.raidInstances > 0`은 티어 스캔 전에는 영영
  성립하지 않아 같은 보스명으로 호버할 때마다 전체 재스캔이 돌았다
- 호버마다 만들던 13원소 레이드 라벨 배열과, 툴팁 라인 루프 안에서 만들던 3원소
  키 배열을 `SourcePreview` 필드로 옮겼다. 라벨 비교는 정규화 결과를 한 번만 만든다
- `UI/SilvermoonMapOverlay.lua`의 `GetSeasonNames()`를 엔트리 루프 밖으로 옮기고,
  `resolveDisplayText`를 포인트·언어 기준으로 기억하고, 포인트 집합이 그대로면
  `getNearbyCount` 전체 패스를 건너뛴다
- 풍요 구렁 이름이 비었을 때도 짧은 TTL로 기억해, 시즌 구렁 POI가 없는 지역에서
  6개 지도 POI 전수 조회가 반복되던 것을 막았다
- 버프 hash를 캐시하고 `UNIT_AURA`와 `InvalidateState`에서만 비운다. hash는 오라가
  바뀔 때만 달라지는데 다른 트리거의 refresh마다 40칸 순회를 다시 했다
- `UI_ERROR_MESSAGE`가 은행 세션이 열려 있을 때만 문자열을 판정한다. 고스트 스윕에
  디바운스를 걸었다
- 퀘스트 패널 강제 스캔을 3회에서 2회로 줄이고, 탭 전환 시 `OnShow`와
  `refreshCurrentTab`이 겹쳐 두 번 스캔하던 것을 한 곳으로 모았다
- 숨은 Blizzard 설정 화면은 갱신하지 않는다. 각 페이지에 `OnShow` 갱신이 이미 있다
- `GetProfessionSections`에 세대 기반 캐시를 넣고 ruRU의 캐시 wipe 목록에도 넣었다

2026-09-04 교차 검토 반영:
- 고스트 오버레이 풀을 넣으면서 `handleGhostDrop`과 `handleGhostDismiss`가 상태 메시지에
  쓰는 `overlay.logicalSlot`이 그 사이에 지워지게 됐다. 두 함수가 부르는 배치·해제
  경로가 동기적으로 `RefreshGhosts`를 돌려 오버레이를 풀로 반납하기 때문이다.
  슬롯 번호를 먼저 지역 변수에 담는다. `ReleaseOverlay`에 이중 반납 가드도 넣었다
- 드래그 저장 훅 가드를 Blizzard 프레임 필드 대신 모듈 로컬 `key` 표로 옮겼다.
  프레임 객체에 표시하면 두 관리 대상이 같은 프레임으로 해석될 때 뒤 항목이 통째로
  건너뛰어진다. `hasExisting`이 거짓인 분기에서도 표를 세워, 두 번째 `Apply`에서
  자기가 심은 `SetScript` 위에 훅이 한 번 더 얹히던 것을 막았다
- `worldEventCompletions` 정리에서 세션 플래그를 없앴다. `GetGlobalSettings`는
  `ns.db` 이전에는 기본값 테이블을 돌려주므로, `DB:Initialize` 전에 한 번이라도
  호출되면 실제 저장 테이블이 그 세션 내내 정리되지 않았다
- 월드 이벤트 경로점 정리에서 `PLAYER_LEAVING_WORLD`를 뺐다. 존 이동마다 발생해
  경로점을 지웠다가 1초 뒤 다시 만들어 TomTom의 현재 대상만 초기화됐다.
  던전 진입은 뒤따르는 `PLAYER_ENTERING_WORLD` 자동 접기 분기가 이미 덮는다
- `isSettingsPanelVisible`이 `AddonSettingsPages`의 하위 페이지도 본다. 메인 창을
  다른 탭으로 열어 둔 채 설정 하위 페이지를 보고 있으면 갱신이 멈췄다
- `Typography:ApplyFont`가 보관 중인 `options`와 호출자 테이블이 같은 객체일 때는
  재사용 분기를 타지 않는다. `wipe`가 원본을 먼저 비운다
- ruRU 치환이 키를 길이 내림차순으로 고정 정렬해 적용한다. `pairs` 순서에 맡기면
  `" pts"`가 `" оч.s"`가 되고 `"Demon Hunter"`가 `"Demon 사냥꾼"`이 될 수 있었다.
  키가 서로의 부분 문자열인 쌍에서만 결과가 달라진다
- ruRU 스탯 오버레이 텍스트 후처리에 재진입 가드를 넣었다. 깊이별 스크래치 버퍼를
  공유하므로 순회 중 재진입하면 상위 루프의 버퍼가 덮어써진다

2026-09-04 고빈도 경로 할당 정리:
- `UNIT_AURA`·`UNIT_STATS`·`UNIT_ATTACK_POWER`를 `RegisterUnitEvent(..., "player")`로
  등록한다. `RegisterEvent`로는 파티·공격대·네임플레이트의 모든 유닛분이 디스패처의
  `pcall`까지 올라온 뒤 버려졌다. 20인 공격대 전투에서 초당 수백 건이다
- `UI/StatsOverlay.lua`에서 `pcall`에 넘기던 익명 클로저 5개를 모듈 레벨 함수로 뺐다.
  `toPlainNumber` 하나만으로 refresh당 55~115개가 생겼고 refresh는 최대 초당 6.7회다
- `UI/Typography.lua`의 `ApplyFont`가 등록 항목과 `options` 테이블을 재사용한다.
  호출마다 새로 만들던 탓에 `StatsOverlay`의 재사용 버퍼가 무의미했다
- `ABPM_ruRU_Final_v3.lua`의 치환 루프가 `gsub` 앞에 평문 `find`로 포함 여부를 본다.
  치환 키에 패턴 메타문자가 없어 결과가 같다. 스탯 오버레이는 FontString 하나당
  키 39개를 돌고 이 순회가 `StatsOverlay:Refresh`마다 실행된다
- `patchTextRegions`가 깊이별 스크래치 버퍼를 재사용하고, 툴팁 후처리는
  `tip:NumLines()`까지만 돈다. 이전에는 줄 수와 무관하게 80회를 돌았다.
  래퍼의 `{ original(...) }` + `unpack`도 없앴다. 감싸는 두 함수 모두 반환값이 없다
- 전문기술 즉시 스캔을 오버레이가 켜져 있거나 패널이 보일 때로 제한했다. 그 외에는
  `MarkDirty`만 걸고 `IsQuestComplete`의 지연 스캔에 맡긴다. 즉시 스캔은 완료 퀘스트
  전체를 읽으며 가방·루팅 이벤트마다 세 번 돌았다
- `ns:RefreshUI()`가 현재 탭의 패널 하나만 갱신한다. 호출처 40곳 대부분이 체크박스
  하나를 토글하는 경로인데 보이지 않는 패널 여섯 개까지 매번 다시 그렸다
- `resolveSeasonDungeonName`에 언어별 메모를 붙였다. `table.sort` 비교자 안에서
  불리는 경로라 정렬 1회에 임시 문자열 수천 개가 생겼다

2026-09-04 메모리 점검 반영:
- `UI/BISOverlay.lua`의 `GET_ITEM_INFO_RECEIVED` 핸들러가 BIS와 무관한 아이템까지 링크
  캐시에 넣고 있었다. 이 이벤트에는 필터가 없어 세션 내 모든 아이템 로드가 들어오는데
  캐시 기록이 `requested` 게이트 바깥에 있었고 캐시를 비우는 경로도 없었다
- 고스트 오버레이 프레임을 풀로 재사용한다. WoW 프레임은 회수되지 않는데 고스트가
  해소될 때 참조만 버리고 있어 액션 버튼 아래에 숨은 프레임이 영구히 쌓였다
- `Modules/BlizzardFrameManager.lua`의 `HookScript("OnDragStop")`을 1회만 걸도록 막았다.
  `HookScript`는 해제할 수 없어 창 이동 기능을 껐다 켤 때마다 훅이 누적됐다
- 월드 이벤트 오버레이가 접힘·비활성·던전 자동 접기·로그아웃에서 TomTom 경로점을
  정리한다. 정리가 `UpdateContent` 맨 끝에만 있어 그 경로에서는 도달하지 못했다.
  이 오버레이는 TOC에 없어 로드되지 않으므로 사용자에게 드러난 적은 없고, 다시
  켜기 전에 미리 고쳐 둔 것이다
- `worldEventCompletions`를 `{ [eventKey] = "YYYY-MM-DD" }`로 바꿔 키 개수를 이벤트 수로
  고정했다. `키_날짜` 형태라 만료 경로가 없었다. 이전 형식 키는 조회할 때 정리한다.
  유일한 호출처가 위의 미로드 오버레이라 실제로 쌓인 적은 없다
- `Data/Defaults.lua`의 `mythPreviewCache` 기본값을 비웠다. 실제 데이터와 다른 값이
  박혀 있어 `MergeDefaults`가 로그인마다 되채우고, 그때마다 불일치 판정이 참이 되어
  preview 캐시가 통째로 폐기되는 구조였다

2026-09-04 미착수 작업 처리:
- 월드 이벤트 데이터가 시즌 1 기준이라 이름·지역·주기가 모두 틀려 있었다. 이벤트 4종을
  `살데릴의 연회`(영원노래 숲), `스토마리온 공격`(공허폭풍), `풍요`(4개 지역 순환),
  `하라니르의 전설`(하란다르)로 고치고 mapID를 `2395` / `2405` / `2413`으로 맞췄다
- 분 단위 `interval`/`duration`/`offset` 단일 주기 모델을 `cadence` 모델
  (`weekly` / `interval` / `rotating`)로 바꿨다. 오버레이는 `areaPoiID` 런타임 조회를
  먼저 쓰고, 주간 이벤트는 주간 리셋까지 남은 시간을 쓰며, 기준시각을 모르는 이벤트는
  가짜 카운트다운 대신 `미확인`으로 표시한다
- 월드 이벤트 카운트다운 포맷에 `시간`/`분`/`초`가 소스에 박혀 있어 영어·러시아어에서도
  한국어로 나왔다. 로케일 키 3종으로 옮겼다
- 전문기술 주간 퀘스트 변형 목록에서 questID 4개(`93697` 마법부여, `93701` 약초채집,
  `93707` 채광, `93713` 무두질)가 빠져 있었다. 목록이 `match = "any"`라 그 주에 해당
  변형이 걸리면 완료를 감지하지 못한다. DB2 `QuestV2`(빌드 `12.1.0.69465`)로 주간
  questID 72개를 대조하다 찾았다
- 러시아어 번역 누락 143개를 채웠다. `scripts/validate_locale_contract.py`의
  `RURU_MISSING_BASELINE`을 `143`에서 `0`으로 내렸다

2026-09-04 교차 리뷰 반영:
- 스탯 우선순위 표 창의 제목과 부제가 `Patch 12.0.5` / `패치 12.0.5`로 남아 있었다.
  값은 와우헤드 시즌 2 기준이라 표시가 사실과 달랐다. `Midnight Season 2` / `한밤 시즌 2`와
  `Wowhead Season 2 baseline` / `와우헤드 시즌 2 기준`으로 고쳤다
- `/abpm log` 창이 호출마다 새 프레임을 만들고 있었다. `ABPMLogPopup`을 캐시하고
  `UISpecialFrames`에 등록해 ESC로 닫히게 했다. 복사 창(`ensureCopyPopup`)과 같은 구조다
- 상태 메시지의 성공·실패 판별 낱말표에 한국어·영어만 있어 러시아어는 항상 `안내`로
  분류됐다. 실패 6종·성공 10종의 러시아어 어간을 추가했다
- `ABPM_ruRU_Final_v3.lua`가 덮어쓴 `FormatStatusMessage`의 `kind` 경로가 접두 9종을
  하드코딩하고 `kind == "error"`만 봤다. 실제 분류값은 `failure`라 실패 접두가 붙지 않았다.
  세 언어 모두 `status_prefix_*` 키를 쓰도록 통일하고 `failure`와 `error`를 함께 받는다
- `Utils.FormatStatusMessage`의 접두 중복 방지 가드 두 개가 동작하지 않고 있었다.
  Lua 문자 클래스는 바이트 집합이라 `[●◆▲■]`가 멀티바이트 기호를 잡지 못하고,
  `^(성공|실패|안내):%s`는 Lua 패턴에 대안(`|`)이 없어 리터럴로만 맞는다.
  `status_prefix_*` 값과 직접 대조하는 방식으로 바꿨다
- 은행·복사 안내 7종의 값에 `[ABPM]`이 들어 있어 `Utils.Print`의 애드온 접두와 겹쳤다.
  세 언어에서 접두를 뺐다
- 복사 창 사용법의 매크로 예시가 `ABPMCopy(내용)` / `ABPMCopy(текст)`였다. Lua 식별자는
  ASCII만 받으므로 그대로 붙여넣으면 실패한다. 세 언어를 `ABPMCopy(text)`로 맞추고
  안내 문장도 다듬었다
- BIS 모험 안내서 자동 이동이 막혔을 때의 안내 2종이 언어 분기 없이 한국어였다.
  로케일 키 2종을 세 언어에 추가했다
- 복사 창이 전투 중에도 `EditBox`에 포커스를 가져가던 것을 `InCombatLockdown`으로 막았다
- 언어 판별 헬퍼가 세 벌이었다. `UI/ProfessionKnowledgeOverlay.lua`와
  `UI/SilvermoonMapOverlay.lua`가 `ns.Utils.IsKoreanLanguageSelected`를 쓰도록 통일했다
- `Modules/ProfessionKnowledgeTracker.lua`의 중복 `local rawName` 선언과 미사용
  `local language`를 제거하고 언어 판정 표기를 통일했다
- 문서 정합성을 맞췄다. `BISOverlay` top-level local 표기(현재 `195` / 예산 `198` /
  상한 `200`), 동결 파일 개수 `9`종, `SeasonGuard.dataSeason`과 `[S2]` 접두,
  `baselineItemLevel = 318`, preview 검증 범위 `318~334`, PvP 실측값, `sources` 태그 현황,
  `DOC/SEASON2_HANDOFF.md`의 낡은 해시 목록(사라진 `BISData.lua` 포함) 제거가 대상이다

2026-09-03 추가 변경:
- 전문기술 지식에 12.1 신규 평판 서적 11종을 추가했다. `Zul'jarra's Forces` 평판 6단계에서
  열리는 `Demystifyin': <직업>`이며 각 10점이다. questID는 `96459`, `96511~96520`이고
  `ItemXItemEffect` -> `ItemEffect` -> `SpellEffect`(`Effect=16`) 경로로 DB2에서 확인했다.
  한국어 표시는 공식 이름 `누구나 쉽게 배우는 기술: <직업>`을 쓰고 러시아어 접두도 넣었다.
  직업별 평판 보상 합계가 10점에서 20점으로 늘어난다
- 시즌 2 한국어 이름을 DB2로 전수 대조했다. 신화+ 던전 8종, 레이드 보스 9종, 티어 세트 13종,
  지도 별칭이 모두 저장소 값과 일치해 바꿀 것이 없었다
- `gradeMax.myth = 334` 유지 근거를 문서에 남겼다. 와우헤드 금고 표의 `335`는 셀 정렬이 깨진
  페이지이고, 같은 사이트 레이드 표의 `318 / 321 / 324`가 저장소 랭크 사다리와 정확히 맞는다
- 구렁 11단계 전 구간(완료 보상과 금고)이 와우헤드 표와 일치함을 확인했다. 외부 자료라
  `sources.delves` 태그는 `guide`로 그대로 두었다
- 시즌 2 신화+ 금고 preview selector 후보를 DB2에서 찾아 `DOC/TODO.md`에 적었다.
  Myth 트랙 그룹이 시즌 1 `612`에서 시즌 2 `618`로 바뀌고 `+10` 금고가 이 그룹을 가리키므로
  `SequenceValue = 1`인 `ItemBonusListID = 12849`가 후보다. 아이템 레벨 계산 표는 공개되지
  않아 인게임 확인 전에는 데이터에 넣지 않는다
- 스탯 우선순위 40개 전문화를 와우헤드 전용 stat-priority 페이지로 전수 재대조했다.
  31개가 이미 일치했고 복원 주술사를 수집값 `치명타 및 극대화 > 가속 = 유연성 > 특화`로
  갱신했다. 무법 도적은 `USER_SELECTED` 표식이 붙어 있었지만 저장값이 `가속`을 꼴찌로
  두는 구형 수집 버그 형태였고, 전용 페이지와 인게임 확인 항목이 모두 `가속` 1순위여서
  `가속 > 치명타 및 극대화 > 유연성 > 특화`로 정정했다. 나머지 `USER_SELECTED` 7개는
  동률 표기만 달라 수동값을 유지했다
- 애드온 언어를 영어로 바꿨을 때 한국어가 그대로 나오던 곳을 로케일 키로 옮겼다.
  `/abpm help`의 은행 명령 두 줄, `/abpm copy` 창의 제목·사용법 전체, 로그 창의 버튼과
  빈 로그 안내, 진단 실패 안내, 전투부대 은행 채팅 메시지 6종, 템플릿 기본 이름과
  복제 접미사가 대상이다. 키 32종을 enUS / koKR / ruRU 세 언어에 넣었다
- 전문기술 오버레이의 항목 이름이 영어 모드에서도 한국어로 번역되던 문제를 고쳤다.
  `translateObjectiveName`이 언어를 보지 않고 항상 한국어 표를 적용하고 있었다
- 상태 메시지 접두(`● 안내:` / `● 성공:` / `◆ 실패:`)가 언어와 무관하게 한국어로
  붙던 문제를 고쳤다. 접두를 로케일 키로 바꾸고, `ABPM_ruRU_Final_v3.lua`가 덮어쓴
  `FormatStatusMessage`는 `kind` 인자가 없을 때 원본 분류 로직에 위임하도록 했다.
  이 덮어쓰기 때문에 모든 언어에서 성공/실패 구분이 사라져 항상 `안내`로 나오고 있었다
- `README.md`, `AGENTS.md`, `DOC/ARCHITECTURE.md`, `DOC/HANDOFF.md`, `DOC/README.md`,
  `DOC/TODO.md`, `ABProfileManager/ADDON_INTRO.txt`의 낡은 표기를 정리했다. 버전 `v1.12.0`,
  BIS 카탈로그 `641`행, `BIS 추천 장비는 시즌 1 기준입니다` 헤딩, 시즌 1 미리보기 문구,
  이미 확인된 `Coiled Isle` UiMapID `2512` 서술이 대상이다
- 월드 이벤트 데이터(`Data/WorldEventSchedule.lua`, TOC 미등재 비활성)의 결함을
  DB2 `AreaPOI`/`UiMap`으로 확인해 `DOC/TODO.md`에 적었다. 이벤트 이름 세 건이 틀렸고
  (`Saltheril's Soiree`, `Stormarion`, `Legends of the Haranir`), 실버문(2393)과
  영원노래 숲(2395) mapID가 두 이벤트 사이에서 뒤바뀌어 있으며, 주기 모델도 실제와 다르다
- `Data/ItemLevelTable.lua`의 PvP 근거 서술을 실측 확정값(명예 `263~295`,
  정복 `292~308`, `tooltip`)에 맞춰 `DOC/CODE_NOTES.md`에서 정정했다

주요 변경:
- `UI/MythicPlusRecordOverlay.lua`의 던전명 문자열이 줄바꿈으로 끊겨 있어
  `unfinished string near '"송곳니의'` 로드 오류가 발생했다. 문자열을 한 줄로
  복구하고 파일 개행을 LF로 정규화했다. 문자열 안에 남아 있던 CR도 제거했다
- 쐐기 기록 오버레이가 `C_MythicPlus.RequestMapInfo()`를 호출하지 않아
  `GetSeasonBestForMap`이 항상 `nil`을 반환했다. 데이터 요청과
  `CHALLENGE_MODE_MAPS_UPDATE`, `MYTHIC_PLUS_CURRENT_AFFIX_UPDATE` 등 도착 이벤트
  구독, 최대 8회 지연 재시도를 추가했다
- 던전 아이콘 훅을 믹스인 테이블뿐 아니라 프레임 인스턴스별로도 걸어, 훅 등록
  이전에 만들어진 아이콘이 누락되던 구멍을 막았다. 아이콘 수집도
  `DungeonIcons` / `MapIcons` / `Icons` 필드와 깊이 3 자식 스캔으로 넓혔다
- `/abpm debug mplus` 진단 명령을 추가했다. 설정 상태, API 존재 여부,
  `ChallengesFrame` 표시 여부, 수집된 아이콘 수, 던전별 최고 레벨·점수·오버레이
  상태를 출력한다
- BIS 아이템 클릭 시 모험 안내서가 던전과 보스까지 열리지 않던 문제를 고쳤다.
  레이드는 `instanceID` / `encounterID` 없이 난이도만 넘겨 항상 실패했고,
  `selectedEncounterJournalTierHasInstance`가 던전 목록만 조회해 레이드
  `instanceID`를 끝내 찾지 못했다
- `EJournal` 런타임 인덱스를 도입해 `EJ_SelectTier`, `EJ_GetInstanceByIndex`,
  `EJ_GetEncounterInfoByIndex`로 던전과 레이드를 이름으로 해석한다.
  `BISEncounterJournal.lua`의 하드코딩 표는 빠른 경로로 남기되, 현재 티어 스캔에서
  확인되지 않으면 런타임 인덱스 결과를 쓴다. 레이드는 보스명으로 인스턴스를
  역추적한다
- 보스명 후보에 `displaySourceKoKR`, `displaySourceEnUS`, `dungeonEnUS`를 추가해
  한국어 클라이언트에서 영문 보스명이 매칭되지 않던 문제를 해결했다
- 드랍템 레벨 정보 창에서 하단 문장·열쇠 스트립이 본문 행과 겹치던 문제를 고쳤다.
  `content` 프레임이 `TOPLEFT`와 `RIGHT` 두 점만 잡혀 있어 `RIGHT` 앵커가 세로
  중심까지 고정하는 바람에 높이가 `프레임 높이 - 92`로 계산됐다. 상·하단 앵커를
  명시하고 `tableArea`와 행 배치의 같은 과제약도 정리했다
- 전리품 기반 보스 해석을 추가했다. `EJ_SelectInstance`와 전리품 목록으로
  `itemID → (encounterID, 보스명)` 인덱스를 인스턴스당 1회 스캔해 캐시한다.
  `BISCatalog.lua`의 `boss` 필드가 641행 전부 `nil`이라 정적 데이터로는 보스를
  알 수 없었다. 출처 라벨은 해석에 성공하면 `던전명 · 보스명`으로 표시한다
- 쐐기 기록 오버레이가 던전명을 기록이 있을 때만 그렸다. 이제 던전명은 항상
  표시하고 점수는 기록이 있을 때만 `+레벨 점수` 형식으로 덧붙인다
- 시즌 기록 조회 폴백이 `C_MythicPlus.GetRunHistory(false, true)`로 **이번 주**
  기록만 훑고 있었다. `(true, true)`로 고쳐 시즌 전체를 본다
- `ChallengesFrame.Update` 훅이 재시도 카운터를 리셋해 `drawn=0`일 때 재시도가
  끝없이 반복되고 디버그 로그가 도배됐다. 리셋을 창 표시와 데이터 이벤트로만
  제한하고 동일 디버그 메시지는 10초 안에 재출력하지 않는다
- 드랍템 레벨 정보 창에 오늘의 풍요 구렁 이름을 하단 스트립에 상시 표시한다.
  기존에는 마우스 오버 툴팁에만 있었다. 스트립 높이는 글자 높이에 맞춰 동적으로
  계산한다. 이름 조회 실패 시 `확인 불가`를 캐시에 저장해 영구히 고정되던 문제도
  함께 고쳤다
- 드랍템 레벨 정보 창 본문 글자를 키웠다. 행 라벨 `11 → 13`, 값 `10 → 12`,
  머리글 `9 → 11`. 창 폭은 `448 → 472`, 행 높이는 `17 → 19`로 늘리고 열 위치를
  재배치했다
- `/abpm copy` 명령과 전역 `ABPMCopy(text)` 헬퍼를 추가했다. 진단 결과와 로그를
  복사 가능한 창으로 띄운다
- 레이드 아이템 클릭 시 모험 안내서가 열리지 않던 문제를 마저 고쳤다. 타깃 해석은
  정상이었고 표시 호출이 실패하고 있었다. `EJ_IsValidInstanceDifficulty`로 난이도를
  검증해 유효한 값으로 낮추고, `EJ_SelectInstance` + `EncounterJournal_DisplayInstance`
  경로를 폴백으로 추가했다
- `EJ_GetEncounterInfoByIndex`가 인스턴스를 선택하지 않은 상태에서는 빈 값을 준다.
  보스 목록 조회 시 `EJ_SelectInstance`로 인스턴스를 먼저 선택하고 조회 후 복원하도록
  바꿨다. 레이드 보스 매칭이 계속 실패하던 원인이다
- 실패를 캐시에 박아 세션 내내 복구되지 않던 부정 캐시를 없앴다. 안내서 데이터가
  준비되지 않은 시점의 실패는 캐시하지 않는다
- 슬롯별로 1순위만 보여주던 BIS 목록이 3순위까지 표시한다. 반지·장신구는 1순위가
  둘이라 4순위까지다. 후보가 적은 슬롯은 있는 만큼만 보여준다. 표시 예산이
  `1순위 개수 × 2`라 순위 배지는 3순위까지 매기면서 정작 3순위 행은 그리지 못했고,
  양조 수도사 무기 3순위가 인게임에서 영영 보이지 않았다
- 지도 오버레이가 시즌 2 구렁과 던전·레이드 입구를 표시한다. 좌표를 하드코딩하지 않고
  `C_AreaPoiInfo.GetDelvesForMap`, `C_EncounterJournal.GetDungeonEntrancesForMap`으로
  런타임 조회한다. 확인되지 않은 위치는 그리지 않는다
- 모험 안내서 전리품 인덱스를 `SavedVariables`에 저장한다. 키는 클라이언트 빌드와
  시즌이라 패치나 시즌 교체 시 자동 폐기된다. 두 번째 접속부터는 스캔 없이 보스명이
  즉시 표시된다. 시즌 API가 아직 `-1`을 돌려주는 시점에는 캐시를 건드리지 않는다
- `EJournal.EnsureTier`가 사용자의 모험 안내서 확장팩 선택을 바꾼 뒤 복원하지 않던
  문제를 고쳤다
- `/abpm copy ej` 진단 명령을 추가했다. 안내서 API 상태, 티어별 인스턴스 목록, 레이드
  보스 목록, 샘플 해석 결과를 복사 가능한 창에 출력한다
- 툴팁 프리뷰 기준 단계 선택을 추가했다. `신화 1/6`(기본), `신화 6/6`, `영웅 6/6`,
  `챔피 6/6` 네 단계이며 값은 `ItemLevelTable`에서 런타임에 읽는다. 선택은 표시 전용이라
  순위 계산에 영향을 주지 않고 `ns.db.global.settings.bisOverlay.previewStep`에 저장된다.
  임의 단계의 정확한 아이템 링크는 클라이언트가 제공하지 않으므로 툴팁 본문이 아니라
  `기준:` 줄이 선택 단계를 반영한다. 제작 아이템은 업그레이드 트랙 대상이 아니라 단계
  선택에서 제외하고 `제작 · 318~331` 범위로 표시한다
- 링크를 구하지 못했을 때의 폴백 툴팁에 `기준:` 줄이 없어 티어와 제작 아이템이 시즌 값
  없이 표시되던 문제를 고쳤다
- `EJ_GetDifficulty` 조회에 실패하면 신화 난이도 지정 자체를 건너뛰던 조건을 분리했다.
  전리품 링크가 낮은 난이도 기준으로 잡히던 원인이다
- 스탯 우선순위 수집기를 전문화 개요 페이지 문장 파싱에서 전용 stat-priority 페이지
  파싱으로 교체했다. 조건이 앞에 붙은 1순위 스탯을 정규식이 통째로 버려 무법 도적과
  포식 악마사냥꾼의 `가속`이 1순위에서 꼴찌로 뒤집혀 있었다. 시즌 1 값이 남아 있던
  전문화 6종도 함께 갱신했다. 40개 전문화 중 23개가 바뀌었다
- 수집기가 `source="USER_SELECTED"` 표식이 붙은 전문화 8종(혈기 죽음의 기사, 수호
  드루이드, 보존 기원사, 양조·운무 수도사, 신성 사제, 무법 도적, 고양 주술사)의
  수동 확정 값까지 덮어쓰고 있었다. 8종을 이전 값으로 되돌리고 수집기에 보호를
  넣었다. 표식만 남고 값이 바뀌면 `statPriorityNote`의 근거와 실제 값이 어긋난다
- BIS 카탈로그를 `641`행에서 `657`행으로 재생성해 일부 슬롯에 2·3순위 후보가 생겼다
- 재생성 데이터의 슬롯·출처 오류를 바로잡았다. 냉기 죽음의 기사 `가슴` 칸에 티어
  투구가 들어가 `머리`와 중복되고 실제 티어 가슴이 빠져 있었다. 다리 방어구
  `극지 탐험가의 다리싸개`가 4개 전문화에서 `발`에 배정돼 있었다. 수양·신성 사제와
  악마 흑마의 출처 `25`행이 실제로는 레이드·쐐기 드랍인데 `제작`으로 분류돼
  출처 필터가 어긋나 있었다. 파멸 악마사냥꾼의 레이드 반지·장신구 2행이 근거 없이
  교체된 것도 되돌렸다
- 지도 오버레이 대상 맵을 넓혀 시즌 1 지역 지도에서도 시즌 2 던전 입구를 표시한다.
  시즌 2 인스턴스만 필터링하며 좌표는 여전히 런타임 조회다
- 슬롯당 2순위 후보 확보를 시도했으나 **원본에 데이터가 없다**. Wowhead 시즌 2 가이드는
  40개 전문화 중 36개가 `Overall BiS` 탭 하나뿐이고 슬롯 대안을 제시하지 않는다. 탭이 둘인
  4개 전문화는 기존 수집기가 이미 양쪽을 읽고 있었다. 근거 없는 2순위를 만들지 않기로 하고
  수집기는 그대로 뒀다
- 그 조사 과정의 교차검토에서 기존 데이터 결함을 찾아 고쳤다
  - 냉기 죽음의 기사(`251`)의 가슴 칸에 투구 `271474`가 들어가 있었다. 실제 가슴
    `271477`로 교체했다. 전문화 내 itemID 중복은 이제 0건이다
  - 다리 방어구 `251153`이 4개 전문화에서 발 슬롯에 배정돼 있었다. 다리로 고쳤다
  - 사제 수양·신성과 악마 흑마의 `25`행이 레이드·쐐기 드랍인데 제작으로 분류돼 있었다.
    다른 전문화의 같은 itemID와 대조해 확인되는 행만 정정했고, 대조 근거가 없는 `3`행은
    추정하지 않고 남겼다. `sourceGroup` 집계는 `crafted 103 → 78`, `raid 374 → 393`,
    `mythicplus 101 → 107`이다
  - 스탯 우선순위 수집기가 `USER_SELECTED`로 표시된 8개 전문화의 수동 확정값을 덮어쓰고
    있었다. 값을 복구하고, 수집기가 해당 표식이 붙은 줄을 건너뛰도록 막았다
  - 슬롯 표시 예산이 `bisLimit * 2`라 반지·장신구가 아닌 슬롯에서 `third` 배지가 도달
    불가였다. `bisLimit + 2`로 고쳐 배지 사다리와 예산을 일치시켰다
- `BISOverlay.lua` top-level local은 `195`로 예산 안에 있다
- 로컬 배포는 작업공간 `dist/ABProfileManager-v1.13.0.zip` 생성까지만 수행한다

## 1.12.0 - 2026-08-28

WoW 12.1.0 Midnight 시즌 2 대응. 아이템 레벨표의 일부 구간이 외부 자료 근거라
`scripts/run_season2_validation.ps1 -Strict`는 통과하지 않는다.

주요 변경:
- TOC Interface를 `120100` 단일 값으로 지정하고 버전을 `1.12.0`으로 올림
- 아이템 레벨표를 시즌 2로 교체. 탐험가(expl) 트랙 제거로 등급 5종, `gradeMax`는
  `282 / 295 / 308 / 321 / 334`
- 월드 보스를 야외·일반·영웅·신화 4난이도로 확장. Lair가 난이도를 갖는 구조 반영
- 문장 통화를 안개문장 `3442~3446`으로 교체. 복원 열쇠 `3028`은 그대로 유효
- 12.1 aura 접근 제한 대응. 보호 상태에서 index 조회 실패 시 backoff 후 빈 hash
- M+ 기록 오버레이 훅을 addon 이름에 의존하지 않도록 변경
- BIS 추천 장비를 시즌 2로 재생성. 던전 8종과 맹독 심연 전리품이 반영되며 출처는
  공식 한글명으로 표시된다. 후보는 641행이다
- Encounter Journal 랜딩 데이터를 시즌 2 던전 8종으로 갱신
- `SeasonGuard`가 데이터와 표의 시즌을 비교해 어긋나면 자동 랜딩과 자동 점수화를
  차단한다. 현재는 둘 다 시즌 2라 차단이 꺼져 있다
- 시즌 2 preview selector를 확인하지 못해 M+ 자동 점수화와 시즌 preview 툴팁은
  비활성이다. 잘못된 아이템 레벨을 보여주지 않기 위한 선택이다
- PvP 아이템 레벨을 인게임 상인 툴팁으로 확정. 명예 `263~295`, 정복 `292~308`
- 레이드 아이템 레벨을 모험 안내서 전리품 목록으로 네 난이도 모두 검증
- 똬리의 섬(`2512`)을 구렁 조회 대상과 지도 별칭에 등록
- BIS preview snapshot 캐시에 시즌 무효화 추가
- 시즌 2 검증 하네스 추가 (`run_season2_validation.ps1`, 검증기 3종)
- 애드온 Lua 소스에서 주석을 제거하고 제약은 `DOC/CODE_NOTES.md`로 이관

## 1.11.11 - 2026-06-21

WoW 12.0.7 진균나락 레이드 BIS 데이터와 호환성 보강을 추가한 로컬 패치.

주요 변경:
- 신규 단일 보스 레이드 `진균나락(Sporefall)` / `부식수렁(Rotmire)` 드랍 11종을 BIS 카탈로그에 추가
- 착용 가능 방어구 타입과 전문화별 스탯 우선순위를 기준으로 신규 raid 후보 200개 row의 슬롯 우선순위 재번호화
- 진균나락 Mythic 298 raid preview 범위를 허용하고 `Sporefall / Rotmire` source locale 보강
- StatsOverlay secret number 변환, Encounter Journal tier fallback, 전투부대 은행 세션, 액션바 적용 API, 구렁 API 호출을 12.0.7 기준으로 방어
- `scripts/build_bis_catalog.py`와 `scripts/validate_bis_catalog.py`가 진균나락 raid 보존 seed와 row count를 검증
- 로컬 배포는 작업공간 `dist/ABProfileManager-v1.11.11.zip` 생성까지만 수행하고 WoW 설치 폴더 복사는 하지 않음

## 1.11.10 - 2026-06-03

BISOverlay Lua local 변수 제한 초과 로드 오류를 수정한 로컬 핫픽스.

주요 변경:
- 시즌 preview 상태와 helper를 `SourcePreview` 테이블 필드로 묶어 `UI/BISOverlay.lua` top-level local 개수를 `194`로 낮춤
- WoW Lua chunk 로드 시 발생하던 `main function has more than 200 local variables` 오류 수정
- `scripts/validate_bis_tooltip_contract.py`에 BISOverlay top-level local 개수 예산 검증 추가
- raid/tier/crafted 시즌 preview와 M+ `Myth/신화 1/6 272` snapshot 동작은 유지
- 로컬 배포는 작업공간 `dist/ABProfileManager-v1.11.10.zip` 생성까지만 수행하고 WoW 설치 폴더 복사는 하지 않음

## 1.11.9 - 2026-06-03

BIS 레이드/티어/제작 hover를 시즌 기준 preview 링크로 보강한 로컬 패치.

주요 변경:
- `Data/BISSeasonPreviewLinks.lua` 추가: raid Myth, tier Myth, crafted r5 285 preview 템플릿을 로컬 DB로 관리
- raid/tier hover는 preview link가 실제 신화 tooltip text와 시즌 신화 ilvl 범위를 통과한 경우에만 Blizzard `SetHyperlink()`로 표시
- crafted hover는 preview link가 실제 285로 확인된 경우에만 Blizzard `SetHyperlink()`로 표시
- 실패 시 기존 기본 `itemLink` / `item:<itemID>` fallback 유지
- `scripts/validate_bis_season_preview_links.py` 추가 및 tooltip contract 확장
- 로컬 배포는 작업공간 `dist/ABProfileManager-v1.11.9.zip` 생성까지만 수행하고 WoW 설치 폴더 복사는 하지 않음

## 1.11.8 - 2026-06-03

BIS 티어 hover 첫 표시를 기본 itemID 링크까지 보강한 로컬 패치.

주요 변경:
- BIS 오버레이 상단 아이템 툴팁 체크박스를 기본 on으로 변경하고, 기존 저장값은 1회 마이그레이션으로 on 처리
- 사용자가 체크박스를 직접 끈 뒤에는 해당 선택을 유지하도록 사용자 설정 플래그 저장
- tier/raid/crafted 기본 tooltip 경로에서 클라이언트 full `itemLink`가 없으면 `item:<itemID>` 기본 링크도 Blizzard `SetHyperlink()`에 시도
- 성공한 기본 itemID 링크는 세션 캐시에 저장해 반복 hover 로딩 부담 완화
- 임의 bonusID 조립 금지와 M+ `Myth/신화 1/6 272` 검증 snapshot 정책 유지
- 로컬 배포는 작업공간 `dist/ABProfileManager-v1.11.8.zip` 생성까지만 수행하고 WoW 설치 폴더 복사는 하지 않음

## 1.11.7 - 2026-06-03

BIS 레이드/제작/티어 hover도 Blizzard 기본 아이템 툴팁으로 표시하도록 확장한 로컬 패치.

주요 변경:
- 상단 아이템 토글 on 시 raid/crafted/tier 후보는 클라이언트가 로드한 기본 `itemLink`를 addon-owned Blizzard `GameTooltip:SetHyperlink()`에 전달
- 검증된 시즌 full link가 없는 raid/crafted/tier 후보에는 임의 bonusID를 조립하지 않음
- 성공한 기본 itemLink는 세션 캐시에 재사용해 반복 hover 로딩 부담 완화
- `scripts/validate_bis_tooltip_contract.py`에 raid/crafted/tier 기본 Blizzard tooltip 계약 추가
- 로컬 배포는 작업공간 `dist/ABProfileManager-v1.11.7.zip` 생성까지만 수행하고 WoW 설치 폴더 복사는 하지 않음
- 원격 GitHub 공개 최신 릴리스와 직접 다운로드는 아직 `v1.11.0` 유지

## 1.11.6 - 2026-06-03

BIS M+ hover를 Blizzard 원본 아이템 툴팁과 1회 저장 snapshot 재사용 경로로 전환한 로컬 패치.

주요 변경:
- selector `12801`을 extracted ItemBonus DB2 build `12.0.1.66838` 기준으로 검토
- 상단 아이템 토글 on 시 검증된 `Myth/신화 1/6 272` full item link를 계정 SavedVariables snapshot schema v3로 한 번 저장하고 이후 hover/점수화에서 재사용
- M+ BIS hover는 addon-owned Blizzard `GameTooltip:SetHyperlink()`로 원본 2차 스탯을 렌더링
- BIS 전용 item tooltip은 shopping tooltip 경로를 사용해 sell price `MoneyFrame` 렌더링 차단
- `StatsOverlay`의 미사용 `PaperDollFrame_Set*` setter 제거
- `SafeNumber()`가 secret 값을 일반 숫자로 정규화하지 못하면 `0`으로 fallback
- 로컬 배포는 작업공간 `dist/ABProfileManager-v1.11.6.zip` 생성까지만 수행하고 WoW 설치 폴더 복사는 하지 않음
- 원격 GitHub 공개 최신 릴리스와 직접 다운로드는 아직 `v1.11.0` 유지
- AGENTS, README, ADDON_INTRO, ARCHITECTURE, HANDOFF, SECURITY_REVIEW, DOC index, 릴리스 노트를 v1.11.6 로컬 패치 기준으로 갱신

## 1.11.5 - 2026-06-03

BIS 출처 클릭의 Encounter Journal 랜딩 보호 경로를 보강한 로컬 패치.

주요 변경:
- Encounter Journal 랜딩에서 보호된 `C_EncounterJournal.SetTab` 직접 호출 제거
- 전투 중에는 자동 랜딩을 건너뛰어 Blizzard 보호 기능 차단 팝업 방지
- 비전투 중 M+ 랜딩은 현재 시즌 tier 선선택, availability guard, 검증된 `JournalInstanceID` 경로 유지
- 로컬 배포는 작업공간 `dist/ABProfileManager-v1.11.5.zip` 생성까지만 수행하고 WoW 설치 폴더 복사는 하지 않음
- 원격 GitHub 공개 최신 릴리스와 직접 다운로드는 아직 `v1.11.0` 유지
- AGENTS, README, ADDON_INTRO, ARCHITECTURE, HANDOFF, DOC index, 릴리스 노트를 v1.11.5 로컬 패치 기준으로 갱신

## 1.11.4 - 2026-06-03

M+ Encounter Journal 랜딩과 selector preview hyperlink 비동기 로드 재시도를 보강한 로컬 패치.

주요 변경:
- M+ 드랍 출처 클릭 시 현재 시즌 tier를 먼저 선택하고 availability guard를 통과한 경우에만 검증된 `JournalInstanceID`로 대상 던전 loot 탭 오픈
- 한밤 시즌 1 M+ 던전 ID 고정: `Magisters' Terrace 1300`, `Maisara Caverns 1315`, `Nexus-Point Xenas 1316`, `Windrunner Spire 1299`, `Algeth'ar Academy 1201`, `Seat of the Triumvirate 945`, `Skyreach 476`, `Pit of Saron 278`
- selector preview hyperlink가 아직 로드되지 않아 snapshot이 비어 있으면 비동기 아이템 로드 뒤 exact selector 링크 재검증. 실패 callback timeout 정리와 링크별 세션 최대 2회 재시도 적용
- 저장 snapshot이 없는 M+ 행 hover도 selector preview hyperlink 즉시 해석을 한 번 시도
- 로컬 패키지는 `dist/ABProfileManager-v1.11.4.zip`, 원격 GitHub 공개 최신 릴리스와 직접 다운로드는 아직 `v1.11.0` 유지

## 1.11.3 - 2026-06-02

가방에 없는 M+ 후보도 Myth 1/6 272 tooltip/stat preview를 자동 생성하는 로컬 패치.

주요 변경:
- `Data/BISMythicVaultLinks.lua`에 Midnight 시즌 1 M+10 금고 Myth 1/6 selector `12801` 고정
- 수동 full link가 없는 M+ 후보도 selector preview item string을 자동 생성
- 생성 preview 또는 수동 override가 클라이언트에서 실제 `272`로 검증된 경우에만 tooltip/stat snapshot 저장 및 점수화
- snapshot은 계정 SavedVariables에 저장해 이후 hover와 자동 점수화에서 재사용
- selector 또는 item string 템플릿 변경 시 기존 snapshot cache 자동 초기화
- 실제 다른 템렙으로 해석된 preview는 세션 음성 캐시로 반복 재시도 차단
- 수동 `linksByItemID`는 예외 항목용 override로 유지
- `scripts/validate_bis_mythic_vault_links.py`가 baseline과 selector `12801`, override 형식을 함께 검증
- 검토되지 않은 bonusID 임의 조립 금지 정책 유지
- 로컬 패키지는 `dist/ABProfileManager-v1.11.3.zip`, 원격 GitHub 공개 최신 릴리스와 직접 다운로드는 아직 `v1.11.0` 유지

## 1.11.1 - 2026-06-02

BIS tooltip 색 보존, 검증 링크 DB 자동 점수화, MoneyFrame taint 방어를 추가한 로컬 패치.

주요 변경:
- BIS item tooltip 수동 렌더러가 Blizzard tooltip line color와 품질 색을 보존하도록 보강
- 상단 아이템 토글을 켜면 `Data/BISMythicVaultLinks.lua`의 검증 M+ full link를 자동 점수화
- 자동 검색 full link 자체가 위대한 금고 `Myth 1/6 272`로 검증된 경우에만 해당 링크의 실제 스탯 / 실제 ilvl로 자동 점수화
- 던전 종료 `Hero 3/6 266` 링크만 있으면 272 기준 라벨은 표시하되 점수는 미검증 fallback으로 유지
- `itemID`만으로 `itemLink`/bonusID 조립 금지
- 실제 장비/가방 링크를 자동 검색 링크보다 우선 적용
- hover/자동 큐에서 Encounter Journal UI 상태 변경과 숨은 loot scan을 제거해 `MoneyFrame` secret-number taint 경로 차단
- M+/raid 클릭은 공개 Encounter Journal 열기 경로만 사용
- 점수 캐시, 아이템 요청 dedupe, 분산 큐로 자동 검색 중 rebuild 스로틀 부담 완화
- `scripts/rebuild_bis_database.ps1` 추가: v1.3 카탈로그 입력 → v1.7 scoring 입력 → curated Myth link validate → catalog validate → audit
- `scripts/validate_bis_mythic_vault_links.py` 추가
- M+/tier 추가는 v1.3 파일, 점수 정책은 v1.7 파일에서 관리. raid/crafted는 아직 기존 `BISCatalog.lua` 보존 seed이므로 완전 단일 seed 재생성은 후속 범위
- 로컬 패키지는 `dist/ABProfileManager-v1.11.1.zip`, 원격 GitHub 공개 최신 릴리스와 직접 다운로드는 아직 `v1.11.0` 유지
- README, ADDON_INTRO, ARCHITECTURE, HANDOFF, SECURITY_REVIEW, DOC index, 릴리스 노트를 v1.11.1 로컬 패치 기준으로 갱신

## 1.11.0 - 2026-06-01

한밤 시즌 1 v1.7 컴팩트 런타임 점수 코어를 BIS 오버레이에 연결한 릴리스.

주요 변경:
- `DOC/MidnightS1_MPlus_Addon_Master_v1.7.md`와 `DOC/MidnightS1_MPlus_Addon_DB_v1.7.lua`를 추가
- v1.3 정적 후보 풀 `3130`행을 유지: `mythicplus 2554`, 기존 `raid 285`, 기존 `crafted 91`, `tier 200`
- `Data/MidnightS1MPlusDB.lua`와 `Data/BISRuntimeScoring.lua`를 로드해 실제 소유 `itemLink`가 있는 후보끼리 v1.7 스탯/템렙 점수를 적용
- 실제 링크가 없는 후보는 기존 정적 `overallRank` 순서를 유지해 필터, 즐겨찾기, 레이드/제작 보존 정책과 호환
- 오버레이 rebuild마다 장비/가방 링크 인덱스를 한 번만 생성하도록 최적화
- 40개 전문화 스탯 표와 BIS 정책 메타를 v1.7 기준으로 갱신
- `scripts/build_bis_runtime_scoring.py`를 추가하고 `scripts/validate_bis_catalog.py`가 v1.3 정적 풀과 v1.7 런타임 코어를 분리 검증하도록 보강
- README, ADDON_INTRO, ARCHITECTURE, HANDOFF, SECURITY_REVIEW, DOC index, 릴리스 노트를 v1.11.0 기준으로 갱신

## 1.10.0 - 2026-05-31

한밤 시즌 1 BIS v1.3 오프라인 입력과 40개 전문화 단일 대표 스탯 우선순위를 반영한 릴리스.

주요 변경:
- `DOC/MidnightS1_MPlus_Addon_Master_v1.3.md`와 `DOC/MidnightS1_MPlus_Addon_DB_v1.3.lua`를 BIS 카탈로그 오프라인 생성 입력으로 추가
- v1.3 DB의 중간 `return DB`를 제거하고 EOF의 최종 `return DB` 하나만 유지하도록 정상화
- 40개 전문화의 단일 대표 스탯 우선순위를 `Data/StatPriorities.lua`, `Data/StatPriorityTable.lua`, BIS 정책 메타에 반영
- 애드온 언어가 영어일 때 스탯 우선순위 표가 영문 우선순위 텍스트를 표시하도록 보강
- 단일 대표 우선순위 정책과 맞지 않던 숨김 M+ 전용 토글의 런타임 분기와 개요 표시를 제거하고 SavedVariables 호환 키만 유지
- BIS 카탈로그 `3130`행 유지: `mythicplus 2554`, 기존 `raid 285`, 기존 `crafted 91`, `tier 200`
- v1.3 런타임 점수 정책은 생성 메타데이터까지만 반영하고 실제 `itemLink` 기반 점수 엔진 연결은 후속 설계로 분리
- v1.9.0의 캐릭터별·전문화별 즐겨찾기/보유 상태, 최상단 즐겨찾기 섹션, 보유 아이템명 취소선 유지
- 즐겨찾기/보유 체크 표시를 Blizzard 기본 체크 텍스처로 교체하고, 보유 아이템명 취소선을 전면 레이어로 보강
- 한국어 BIS 표기에서 `Hero/Myth`를 `영웅/신화`로 현지화
- BIS hover 툴팁은 부위, 출처, 현재 순위 중심으로 간소화하고 장황한 검증/템렙 범위 블록 제거
- 보유 체크된 BIS 행은 장착 슬롯과 가방에서 찾은 실제 아이템 링크를 우선 렌더링하며, 체크 시 찾은 링크를 캐릭터별·전문화별 상태에 함께 저장
- README, ADDON_INTRO, ARCHITECTURE, HANDOFF, SECURITY_REVIEW, DOC index, 릴리스 노트를 v1.10.0 기준으로 갱신

## 1.9.0 - 2026-05-31

BIS 오버레이에 캐릭터별·전문화별 즐겨찾기/보유 상태와 M+ M0 툴팁 미리보기를 추가한 릴리스.

주요 변경:
- BIS 아이템 아이콘 앞에 즐겨찾기/보유 체크박스를 추가하고 캐릭터별·전문화별로 저장
- 즐겨찾기 아이템은 `무기` 위 최상단 `즐겨찾기` 섹션으로 이동
- 보유 아이템명은 취소선으로 표시
- M+ 아이템 tooltip preview는 Encounter Journal 신화 던전(M0) Champion 1/6 `246` 기준으로 조회
- `GameTooltip:SetHyperlink()` 직접 호출 금지, source filter, crafted/tier 비랜딩, M+/raid Encounter Journal guard 정책 유지
- README, ADDON_INTRO, ARCHITECTURE, HANDOFF, SECURITY_REVIEW, DOC index, 릴리스 노트를 v1.9.0 기준으로 갱신

## 1.8.0 - 2026-05-31

한밤 시즌 1 M+/티어 BIS 후보를 새 DOC DB 기준으로 재생성하고 BIS 오버레이 표기 정책을 정리한 릴리스.

주요 변경:
- `DOC/MidnightS1_MPlus_Addon_DB_v1.0.lua` 기반으로 40개 전문화 M+/티어 후보를 재생성
- 기존 레이드/제작 행은 보존하고, 게임 런타임 데이터 소스는 계속 `Data/BISCatalog.lua` 하나로 유지
- M+ 보상 프로필을 `던전 종료 영웅 3/6 266` / `위대한 금고·Voidcore 신화 1/6 272` 후보로 분리하되 정적 `itemLink`, `itemString`, bonusID는 생성하지 않음
- BIS row와 전문화 정책에 `staticFinalBisVerified=false`, `runtimeItemLinkRequired=true`, `mythTrackVerified=false`, 스탯 우선순위 검증 메타를 추가
- BIS 오버레이 폭/열 구성을 넓히고, 헤더에 현재 전문화 스탯 정책과 "정적 최종 BiS 아님" 상태를 표시
- BIS 툴팁에 Base ItemID, reward profile, 런타임 링크 필요 여부, Myth 트랙 후보/미검증 상태, 심크 필요 문구를 분리 표시
- `GameTooltip:SetHyperlink()` 금지, visible row만 갱신, crafted/tier 비랜딩, M+/raid Encounter Journal 랜딩 정책 유지
- `scripts/build_bis_catalog.py --addon-db`와 `scripts/validate_bis_catalog.py`를 통해 새 DOC DB 생성/검증 경로 추가
- README, ADDON_INTRO, ARCHITECTURE, HANDOFF, SECURITY_REVIEW, DOC index, 릴리스 노트를 v1.8.0 기준으로 갱신

## 1.7.6 - 2026-05-29

스탯 오버레이 특화 툴팁 핫픽스.

주요 변경:
- 스탯 오버레이 `특화` 행 hover 시 고정된 간단 설명 대신 현재 전문화의 실제 Mastery spell tooltip data를 표시
- `C_SpecializationInfo.GetSpecializationMasterySpells()`와 `C_TooltipInfo.GetSpellByID()`를 사용해 전문화별 특화 이름/설명을 렌더링
- 전역 `GameTooltip` 대신 기존 ABPM 전용 tooltip frame에 수동 렌더링해 MoneyFrame taint 방어 정책 유지
- 특화 툴팁 아래의 평점 기여/DR 구간 안내 유지
- README, ADDON_INTRO, ARCHITECTURE, HANDOFF, 릴리스 노트를 v1.7.6 기준으로 갱신

## 1.7.5 - 2026-05-29

Blizzard 기본 창 이동 안정화와 ABPM 내부 보호 오류 로그를 묶은 패치 릴리스.

주요 변경:
- BlizzardFrameManager가 저장 좌표가 없는 UIPanel 창을 즉시 `SetUserPlaced(true)`로 고정하지 않도록 변경
- 은행/전투부대 은행 창을 UIPanel 대상으로 명시하고, `UIPanelWindows` 런타임 감지로 특성/전문기술/기타 Blizzard UIPanel 창을 보수적으로 처리
- 이전 버전에서 저장된 Blizzard 창 좌표를 `layoutVersion=2` 전환 시 1회 초기화해 중앙 겹침 좌표가 계속 복원되지 않도록 보정
- Blizzard 창 위치 초기화 시 UIPanel 창을 강제로 중앙에 배치하지 않고 Blizzard 기본 레이아웃으로 되돌리도록 수정
- `Utils.RecordCaughtError()` 기반 세션 오류 로그 추가
- `SafeCall`, 모듈 초기화, 이벤트 dispatch, 설정 탭 버튼, 메인 창 탭 전환 콜백에서 잡힌 ABPM 오류를 `/abpm log`와 `/abpm errors`로 확인 가능
- Blizzard PrivateAuras의 private dispel/public buff 충돌 assertion을 좁은 조건으로만 완화하는 `PrivateAurasGuard` 모듈 추가
- README, ADDON_INTRO, ARCHITECTURE, HANDOFF, 릴리스 노트를 v1.7.5 기준으로 갱신

## 1.7.4 - 2026-05-25

WoW Patch 12.0.7 호환성 재패키징을 포함한 유지보수 재배포. 툴팁 판매가 처리에서 발생하던 secret-number taint 오류를 막고, BIS 보상 트랙 안내와 스탯 우선순위 표를 함께 정리했습니다.

주요 변경:
- TOC Interface 번호를 `120005, 120007`로 갱신해 Patch 12.0.5/12.0.7 계열 클라이언트에서 "구버전 애드온" 경고 없이 로드되도록 정리
- 12.0.7 영향 가능성이 있는 tooltip, Encounter Journal, PVE/Mythic+, currency, PaperDoll, aura API 경로를 정적 점검하고 기존 방어 코드 유지
- ABPM 자체 hover 설명이 전역 `GameTooltip`을 직접 소유하지 않도록 애드온 전용 툴팁 헬퍼를 추가
- BIS 아이템 hover에서 `GameTooltip:SetHyperlink()` 직접 호출을 제거하고, `C_TooltipInfo.GetHyperlink()` 텍스트를 수동 렌더링하면서 판매가/화폐 라인을 제외
- 액션바, 모험 안내서, Pawn 비교 툴팁에서 이어질 수 있던 `MoneyFrame.lua secret number` 오류 경로 차단
- 쐐기 BIS 항목에 `던전 종료` / `위대한 금고·Voidcore` 보상 트랙과 대표 아이템 레벨 안내 추가
- Patch 12.0.5 기준 40개 전문화 `스탯 우선순위 표` 팝업 추가 및 현재 전문화 강조 표시
- 첫 설치 언어를 WoW 클라이언트 기준으로 변경: 한국어 클라이언트는 한국어, 영어/미지원 클라이언트는 영어 기본
- 기존 영어 클라이언트에서 실수로 저장된 `koKR` 기본값은 사용자가 직접 한국어를 선택한 기록이 없을 때 한 번만 `enUS`로 보정
- BIS 카탈로그 생성기와 보상 프로필 검증 스크립트 보강
- README, ADDON_INTRO, ARCHITECTURE, HANDOFF, SECURITY_REVIEW, 릴리스 노트를 v1.7.4 유지보수 기준으로 갱신

## 1.7.3 - 2026-04-27

스탯 오버레이 인스턴스/전투 갱신 안정화와 고스트 일괄 정리를 묶은 유지보수 릴리스.

주요 변경:
- 스탯 오버레이 상태 서명에 인스턴스 컨텍스트와 활성 버프 해시를 추가해 특성 변경, 장비 교체, 인스턴스 진입, 전투 중 버프 변화 반응성 보강
- `StatsOverlay:Refresh({ force = true })`와 `InvalidateState()` 경로 추가
- `ZONE_CHANGED_NEW_AREA`, `PLAYER_ENTER_COMBAT`, `PLAYER_LEAVE_COMBAT` 이벤트에서 필요한 UI만 강제 갱신
- 고스트 액션 일괄 정리 버튼과 `DismissAllPendingGhosts()` 경로 추가
- 12.0.5 핫픽스 기준 BIS 출처 라벨, 보스 매핑, 트링킷 우선순위 재검증

## 1.7.2 - 2026-04-26

WoW Patch 12.0.5 secret-number 보호값 대응 핫픽스.

주요 변경:
- Blizzard `PaperDollFrame_Set*` setter 호출을 보호 경로로 감싸 스탯 툴팁 taint 오류를 완화
- `safeNumber()`가 `tonumber(tostring(value))` 패턴을 사용해 secret-number 플래그를 제거한 뒤 산술/비교에 사용하도록 변경
- Patch 12.0.5의 secret-number 동작과 방어 전략을 릴리스 노트에 문서화

## 1.7.1 - 2026-04-26

WoW Patch 12.0.5 호환성 업데이트.

주요 변경:
- TOC Interface 번호를 `120001` → `120005`로 올려 Patch 12.0.5 클라이언트에서 "구버전 애드온" 경고 없이 로드되도록 갱신
- 기능 변경 없음, Interface 호환성 갱신 전용 릴리스

## 1.7.0 - 2026-04-18

한밤 시즌 1 BIS 오버레이를 runtime merge 방식에서 source-aware 정적 카탈로그 방식으로 전환한 릴리스.

유지보수 재배포 (2026-04-19):
- BIS 오버레이의 보스/출처/던전 locale 경로를 보강해 enUS 선택 시 한글 누수가 남지 않도록 정리
- BIS spec/class, StatsOverlay, ProfilePanel, ConfigPanel이 클라이언트 locale 대신 애드온 locale 기준의 직업/특성명을 사용하도록 정리
- BIS 툴팁의 보스 라벨 fallback을 안전화하고 `제나스 지점` canonical 경로를 던전 locale 키에 추가
- 드랍템 레벨 오버레이의 M+/구렁 행 라벨을 locale별 형식으로 분리 (`+2`, `Tier 11` / `2단`, `11단계`)
- 파티찾기 시즌 최고기록 오버레이의 던전명 줄바꿈 규칙을 한/영 locale 모두에 맞게 보정
- 전문기술 오버레이 헤더에 `L / 접기` 버튼과 hover 설명을 추가하고, 기존 보기 전환 버튼과 함께 공통 헤더 조작으로 정리
- README / ADDON_INTRO / 릴리스 노트를 최신 유지보수 내용으로 갱신

주요 변경:
- `Data/BISCatalog.lua`를 런타임 단일 BIS 데이터 소스로 추가하고, 게임 안에서는 더 이상 `BISData_Method.lua + BISData.lua` runtime 병합을 하지 않도록 정리
- `scripts/build_bis_catalog.py`를 추가해 `DOC` seed, Wowhead 가이드, Wago DB2 검증 데이터를 합쳐 한밤 시즌 1 카탈로그를 생성하도록 구성
- Wowhead seed 갱신 스크립트를 40 spec 기준으로 정리하고 `포식자 악마사냥꾼(1382)` 누락을 해소
- BIS 필터를 `쐐기 / 레이드 / 제작 / 티어` 4개 sourceGroup으로 확장하고, 필터 적용 후 visible list 기준으로 `1순위 / 2순위 / 3순위+`를 다시 번호 매기도록 변경
- `koKR/enUS` 아이템명과 source label을 분리 저장해 locale 누수 위험을 줄이고, 생성 단계에서 itemID/locale/source canonicalization 검증을 수행
- `crafted`, `tier`는 Encounter Journal 랜딩 대상에서 제외하고, `mythicplus`, `raid`만 가능한 경우 기존 랜딩을 유지
- TOC 버전과 문서 버전을 `v1.7.0`으로 통일하고, README / ADDON_INTRO / ARCHITECTURE / HANDOFF / SECURITY_REVIEW / DOC index / 릴리스 노트를 동기화

## 1.5.9 - 2026-04-08

오버레이 UX, BIS 표시 규칙, idle CPU hot path, 릴리스 문서 최신화를 함께 묶은 릴리스.

주요 변경:
- Wowhead `current Overall BiS` 39 spec 기준을 유지하면서 `반지 / 장신구`는 상위 2개를 공동 BIS로 표시하도록 정리
- top BIS가 `mythicplus`가 아닌 슬롯만 Wowhead `Best Gear from Mythic+` 후보와 seed fallback을 합친 `Data/BISData.lua` M+ fallback을 뒤에 붙이도록 병합 정책을 보강
- BIS hover 툴팁을 기존 시즌 preview 경로로 복원하고, 제작/촉매 비랜딩 및 source-column Encounter Journal 랜딩 규칙은 유지
- `BISOverlay`와 `ItemLevelOverlay`는 위치 저장 뒤 재오픈 시 저장 좌표를 우선 복원하도록 정리
- `StatsOverlay`, `ProfessionKnowledgeOverlay`, `BISOverlay`는 마우스 휠 scale 저장을 지원
- `ItemLevelOverlay` 구렁 탭 문구를 `보물지도 사용`으로 교체
- `StatsOverlay`는 raw state signature가 같으면 snapshot 재구성을 생략하고 `UNIT_AURA / UNIT_STATS / COMBAT_RATING_UPDATE` 계열을 느린 throttle로 분리해 idle CPU 비용을 줄임
- `SilvermoonMapOverlay`는 상시 0.5초 polling 대신 월드맵 상호작용 시점의 짧은 burst refresh만 유지하고, 안정된 layoutKey가 확인되면 driver를 바로 내려 map idle CPU를 완화
- `Events.lua`의 `PLAYER_SPECIALIZATION_CHANGED`, `SKILL_LINES_CHANGED`는 전역 `RefreshUI()` 대신 관련 UI만 부분 갱신
- `README`, `AGENTS`, `ADDON_INTRO`, `DOC/ARCHITECTURE`, `DOC/HANDOFF`, `DOC/SECURITY_REVIEW`, `DOC/README`, 릴리스 노트를 `v1.5.9` 기준으로 갱신
- 릴리스 메타데이터를 `v1.5.9`로 올리고 패키징 경로/다운로드 링크를 함께 갱신

## 1.5.8 - 2026-03-30

문서 최신화와 BIS / 시즌 최고기록 오버레이 QA 후속 조정을 묶은 릴리스.

유지보수 재패키징 (2026-03-31):
- 현재 비활성/미완성 상태인 `MerchantHelper`, `MailHistory`, `WorldEventOverlay`, `WorldEventSchedule`를 TOC 로드 목록에서 제외해 불필요한 메모리 점유와 초기 로드 비용을 줄임
- `ProfessionKnowledgeTracker`는 완료 퀘스트 스냅샷이 실제로 바뀐 경우에만 generation/cache를 갱신하도록 조정해 bag/loot follow-up refresh의 중복 계산을 완화
- `ProfessionKnowledgeOverlay`는 tooltip 데이터를 hover 시점에만 만들고, render signature가 같으면 전체 row 재구성을 건너뛰도록 정리
- 메인 창 탭 전환은 전역 `RefreshUI()` 대신 현재 탭만 refresh하도록 바꾸고, 메인 창이 닫혀 있을 때는 숨겨진 내부 패널 refresh를 생략하도록 `Core.lua` refresh 경로를 정리

주요 변경:
- 루트 `README`, `ADDON_INTRO`, `AGENTS`, `DOC/ARCHITECTURE`, `DOC/HANDOFF`, `DOC/SECURITY_REVIEW`, `DOC/README`, 릴리스 노트를 현재 동작 기준으로 전면 갱신
- BIS 인던 드랍 정보 오버레이를 최종 QA 상태로 정리: `드랍 출처 / 유형 / BIS 여부` 열, 체크박스형 `쐐기 / 레이드 / 제작` 필터, 참고용 안내 문구, 제작/촉매 비랜딩, 아이템 hover 툴팁 비활성화
- BIS 데이터는 Method 시즌 데이터와 기존 수동 던전 fallback을 함께 병합해 부위별 `BIS / 대체 / 3순위` 구성을 다시 복구
- BIS 모험 안내서 랜딩은 당시 `공결탑 제나스`와 `알게타르 대학` 한글명/직접 ID 보정을 반영했으며, ID 값은 v1.11.4에서 `JournalInstanceID` 기준으로 재검증
- 아이템 캐시 지연 시 BIS 전체 재빌드 대신 보이는 행만 갱신해 깜빡임과 불필요한 새로고침을 줄임
- 시즌 최고기록 오버레이는 `평점 + 던전명`만 하단 정렬로 표시하고, 긴 한글 던전명은 지정 규칙대로 강제 줄바꿈
- 릴리스 메타데이터를 `v1.5.8`로 올리고 패키징 경로/다운로드 링크도 함께 갱신

## 1.5.7 - 2026-03-30

인게임 QA 기준으로 BIS 현재 시즌 정확도와 시즌 최고기록/드랍템 레벨 오버레이 표시를 다시 정리한 로컬 QA 핫픽스 릴리스.

주요 변경:
- `Data/BISData_Method.lua` 하단의 기존 수기 BIS 병합을 제거해, 현 시즌 Method 데이터 뒤에 예전 쐐기/타 스펙 대체재가 섞이던 문제를 차단
- `UI/BISOverlay.lua`가 `sourceType`와 `sourceLabel`을 다시 해석해 잘못 태깅된 던전 항목을 `mythicplus` 경로로 돌리고, 영어 source label은 한글 또는 소스 타입명으로 정규화
- BIS 툴팁은 `mythicplus`와 `raid`에서 Encounter Journal preview link가 안전하게 검증될 때만 실제 시즌 툴팁을 사용하고, 검증되지 않는 `raid/crafted`는 잘못된 저레벨 스탯 대신 현재 시즌 요약만 표시
- BIS 아이템 클릭은 던전명 하드코딩 대신 `itemID -> instanceID/encounterID` 해석 경로를 우선 사용하도록 바꿔 레이드/던전 loot 탭 랜딩을 보강
- `ItemLevelOverlay` 폭과 `위대한 금고` 열을 더 넓히고, `나의 열쇠`의 `오늘의 풍요` 줄 폰트를 축소해 가독성을 재조정
- `MythicPlusRecordOverlay`는 아웃박스를 제거하고 `평점`을 큰 흰색 텍스트로, `최고기록 시간`을 하단 보조 텍스트로만 표시하도록 디자인 수정

## 1.5.6 - 2026-03-30

인게임 QA 후속 이슈를 반영해 BIS 데이터 소스 확장, 구던전 시즌 preview 툴팁 보정, 구렁/열쇠 패널, 파티찾기 시즌 최고기록 아이콘 오버레이를 정리한 릴리스.

주요 변경:
- `Data/BISData_Method.lua`를 Method.gg current overall BIS 기준으로 교체하고, 기존 쐐기 리스트를 각 부위 `대체재 / 2순위`로 병합해 쐐기/레이드/제작 필터가 실제 데이터까지 반영되도록 수정
- BISOverlay에 `출처 / BIS 여부 / 타입(쐐기·레이드·제작)` 컬럼을 추가하고, 소스 필터 버튼을 spec 드롭다운 왼쪽으로 재배치
- 오래된 던전 아이템은 Encounter Journal 시즌 preview loot를 `itemID` 우선 + `아이템명` fallback으로 다시 매칭해 현재 시즌 preview 툴팁을 더 안정적으로 사용하도록 보강
- BIS 아이템 클릭 시 가능하면 Encounter Journal의 해당 던전 loot 탭까지 확실히 랜딩하도록 delayed lootTab focus 경로를 추가
- 드랍템 레벨 오버레이 종합 탭 상단 공통 헤더를 제거하고, 구렁 12단계 아래 `풍요 열쇠 사용` 보상(영웅 1/6)을 별도 행으로 추가
- 우측 `나의 열쇠` 패널을 `오늘의 풍요 4개 + 열쇠 파편 + 복원된 열쇠` 구조로 재배치하고, `나의 문장`/`위대한 금고` 간격과 열 폭을 다시 조정
- 레이드 탭 월드보스 보상을 `?/?` 대신 정확한 등급 문자열로 표시
- 파티찾기 신화+ 시즌 최고기록 던전 아이콘 위에 `단수 / 평점 / 최고기록 시간`을 표시하는 `MythicPlusRecordOverlay`를 추가하고 Utility 탭에서 켜고 끌 수 있게 함
- WoW 기본 설정의 전투메시지 섹션에서 텍스트와 버튼 폭을 더 줄여 overflow를 완화

## 1.5.5 - 2026-03-30

인게임 QA 후속 이슈를 반영해 BIS 시즌 툴팁, BIS 헤더/필터 레이아웃, 드랍템 레벨 우측 패널, 기본 설정 오버플로우를 정리한 릴리스.

주요 변경:
- BISOverlay가 오래된 던전을 고정 EJ ID로 여는 경로를 제거하고, 최신 tier 우선 후보를 실제 시즌 preview loot link로 검증한 뒤 툴팁/클릭 랜딩에 사용
- BIS 아이템 클릭 시 가능할 때 Encounter Journal의 해당 던전 loot 탭까지 직접 열도록 조정
- BIS 헤더에 스크롤 크기조절 힌트, 현재 아이템 레벨, 쐐기/레이드/제작 소스 필터 버튼을 추가하고 spec 아이콘/드롭다운 정렬을 재배치
- BIS 리스트의 아이템명/던전/우선순위 컬럼 폭을 다시 조정하고 던전 컬럼 word-wrap을 끄도록 수정
- 드랍템 레벨 오버레이의 구렁 `?/?` 표기를 제거하고 각 탭 상단에 챔피언/영웅/신화 요약 타이틀을 공통으로 추가
- `나의 문장` 패널을 더 아래로 내리고 글자 크기를 키웠으며, 우측 패널에 `나의 열쇠` 섹션을 추가해 풍요 구렁/복원된 열쇠를 같이 표시
- Blizzard 기본 설정의 전투메시지 블록에서 설명문을 숨기고 폭/모드 버튼 폭을 줄여 오버플로우를 완화

## 1.5.4 - 2026-03-30

인게임 QA를 반영해 BIS 시즌 툴팁, 드랍템 레벨 오버레이, 설정 UI를 다듬은 후속 릴리스.

주요 변경:
- BISOverlay 툴팁이 가능할 때 Encounter Journal 시즌 preview hyperlink를 직접 사용하도록 변경해, 구던전 base item 대신 한밤 시즌 1 M+ preview 스탯/아이템레벨을 우선 표시
- BISOverlay 기본 폭과 컬럼 간격을 줄이고 아이콘 / 아이템명 / 던전 / 우선순위 배치를 더 촘촘하게 조정
- ItemLevelOverlay 기본 폭을 줄이고 `단계` 컬럼을 넓혀 `10단계`, `11단계`, `챔피언 ?/?` 표기가 덜 잘리게 조정
- `나의 문장` 패널을 아래로 내리고 `위대한 금고` 열과의 시각 간격을 더 줄였으며 문장 글자 크기를 확대
- 전문기술 오버레이에서 1회성 포인트를 전부 획득한 경우 화면 오버레이에서만 1회성 요약/상세를 숨기도록 변경
- 메인 UI 설정 탭의 디버그 체크박스와 로그 버튼 겹침 수정, WoW 기본 설정 하위 페이지에 Utility 카테고리 노출, 메인 창 ESC 닫기 지원

## 1.5.3 - 2026-03-30

드랍템 레벨 오버레이 재구성과 BIS 오버레이 시즌 1 데이터 보강 릴리스.

주요 변경:
- ItemLevelOverlay를 `4열 + 우측 나의 문장 패널` 구조로 재정리하고, 쐐기 섹션 타이틀에 챔피언/영웅/신화 최고 강화 레벨 요약 추가
- 위대한 금고 열 잘림을 줄이기 위해 열 폭과 탭 폭을 다시 조정
- BISOverlay를 던전/보스 기준이 아닌 부위 기준 렌더링으로 변경하고 BIS/대체/3순 우선순위 배지 적용
- BIS 툴팁을 베이스 아이템 툴팁 강제 보정 대신 한밤 시즌 1 던전 트랙 요약 툴팁으로 변경
- `Data/BISData_Method.lua`를 추가해 Method.gg 시즌 1 가이드 기반 던전 BIS 데이터를 34개 스펙에 보강
- BIS 슬롯/던전/배지/툴팁 관련 영어/한국어 로케일 정리

## 1.5.2 - 2026-03-29

BISOverlay 클릭 오류 수정 및 드랍 오버레이 문장 섹션 정리 릴리스.

주요 변경:
- BISOverlay `tooltipRegion` 타입을 `Frame`에서 `Button`으로 변경해 `RegisterForClicks` nil 오류 수정
- ItemLevelOverlay 사이드 문장 패널 제거, `기타` 탭 문장 섹션 통합
- Locale 및 패키지 자산을 `v1.5.2` 기준으로 갱신

## 1.5.1 - 2026-03-29

BIS 모험 안내서 연동과 문장 표시 기능을 추가한 릴리스.

주요 변경:
- BISOverlay 던전 헤더 클릭 시 Encounter Journal 연동 추가
- BISOverlay 아이템 툴팁에 M+ 기준 에픽 품질 색상 강제 적용
- ItemLevelOverlay에 현재 보유 문장 수 패널 추가
- README, ARCHITECTURE, HANDOFF, CLAUDE 문서를 `v1.5.1` 기준으로 갱신

## 1.5.0 - 2026-03-29

BIS/드랍 오버레이 UX 개선 1차 릴리스.

주요 변경:
- BISOverlay 타이틀과 열 간격을 정리하고 헤더 영역 마우스 휠 스케일 조절 추가
- ItemLevelOverlay 레이드 탭에 위대한 금고 컬럼 헤더 보강
- UtilityPanel 체크박스 간격과 텍스트 가독성 보정

## 1.4.7 - 2026-03-26

드랍템 레벨정보 오버레이 정식 추가 및 미동작 기능 비활성화 정리.

주요 변경:
- 드랍템 레벨정보 오버레이를 PVEFrame 연동 방식으로 정식 추가
- 월드이벤트 오버레이, 상점 도안 음영처리, 우편 자동완성 기능을 비활성화해 백그라운드 활동 완전 중단
- 편의기능 탭과 디버그 로그 팝업을 정리하고 관련 문서를 갱신

## 1.4.6 - 2026-03-17

경매장 AH 필터 디버깅 결과 반영 — 체크박스 UI 숨김 처리 및 디버그 명령어 정리.

주요 변경:
- 경매장 현 확장팩 필터 체크박스 설정 탭에서 숨김 (코드 유지, UI 비노출)
- Events.lua AH 필터 구현: 필터 버튼 클릭 → 0.35초 후 visible CheckButton 탐색 방식으로 재구현
- Commands.lua `/abpm ahdebug` 디버그 명령어 확장: names, checks, find 모드 추가
- DOC/HANDOFF.md 경매장 필터 섹션 디버깅 결과 상세 기록

## 1.4.5 - 2026-03-17

인게임 테스트 기반 AH 필터 재구현 및 쐐기 체크박스 숨김 처리.

주요 변경:
- 경매장 필터: BrowseSidebar 방식 → 프레임 계층 재귀 탐색(depth 8)으로 재구현
- 스탯 오버레이 쐐기 모드 체크박스 설정 탭에서 Hide() 처리 (코드 유지, UI만 숨김)
- ADDON_INTRO.txt 쐐기 모드 전환 문구 제거
- DOC/HANDOFF.md 미완성 기능 섹션 추가

## 1.4.4 - 2026-03-17

인게임 테스트 기반 스탯 오버레이 수정 및 경매장 신기능 릴리스.

주요 변경:
- 스탯 오버레이 M+ 우선순위 데이터 수정: 비탱커 오버라이드 제거, 탱커 6종만 유연 우선 유지
- 스탯 오버레이 쐐기 모드 툴팁 수정: AddLine 대신 타이틀에 [쐐기]/[레이드] 통합
- 경매장 현 확장팩 필터 자동 선택 기능 추가 (설정 탭 체크박스, AUCTION_HOUSE_SHOW 이벤트)

## 1.4.3 - 2026-03-16

인게임 테스트 기반 UX 개선 릴리스.

주요 변경:
- 전문기술 오버레이 툴팁 목요일 리셋 잔여시간 문장에 하늘색 색상 적용
- 스탯 오버레이 쐐기 모드: 오버레이 레이블 앞 문구 제거, 툴팁에 레이드/쐐기 모드 표시로 변경
- 템플릿 목록 마우스 휠 스크롤 추가 (박스 및 각 row에 OnMouseWheel 바인딩)
- 설정 탭 요약 박스 위 노란색 상태 메시지 제거
- 전문기술 재스캔 완료 시 StaticPopup OK 모달 표시
- ADDON_INTRO.txt 마케팅 관점 소개 텍스트로 전면 재작성

## 1.4.2 - 2026-03-16

인게임 테스트 기반 UI 버그 수정 + 스탯 오버레이 기능 확장 릴리스.

주요 변경:
- 전문기술 오버레이 `주  간:` / `1회성:` prefix를 고정 너비 대신 텍스트 실제 너비로 자동 크기 조정, 값이 바로 옆에 붙도록 개선
- 전문기술 오버레이 row 너비를 프레임 실제 너비에 맞게 재조정하는 post-pass 추가, 히트박스·드래그 영역·툴팁 범위가 시각 영역 밖으로 벗어나던 문제 수정
- readOnly 스크롤 EditBox에서 클릭 시 커서 이동이 스크롤을 상단으로 리셋하던 버그 수정 (퀘스트 후보 목록 스크롤 튕김 해소)
- 설정 탭 전투메시지 박스 높이 증가 (194 → 214px), 표시 모드 버튼이 박스 밖으로 오버플로우되던 문제 해결
- WoW 기본 설정 > 애드온 패널의 전투메시지 섹션 높이 증가 (174 → 244px) 및 패널 총 높이 확대 (700 → 720px)
- 설정 탭 일반 설정 아웃박스 설명 텍스트가 타이틀과 겹치던 위치 문제 수정
- 확인 체크박스 설명에 "템플릿 적용 또는 비우기 전에" 문구 명시
- 스탯 오버레이에 탱커 방어스탯(회피/반격/막기) 표시 여부를 제어하는 체크박스 추가
- 스탯 오버레이에 PvE/쐐기(M+) 선호 스탯 우선순위 모드 체크박스 추가; 쐐기 모드에서는 탱크 버서틸리티 우선, 일부 딜러 헤이스트 우선 순위를 적용
- 지도 오버레이 글자 크기 슬라이더 최대값 상향 (12 → 20)

## 1.4.1.1 - 2026-03-16

profession overlay 세부 정렬/퀘스트 후보목록 입력 경로 보정 릴리스.

주요 변경:
- profession overlay 상세 보기에서 `주  간:` / `1회성:` 뒤 간격을 줄이고 divider `|`를 제거해 내용이 바로 이어지도록 정리
- profession overlay 상세 줄 내부 구분자는 `/` 대신 쉼표 기반으로 바꿔 가독성을 높임
- profession tooltip 범례를 `범례: 완료 | 미완료` 한 줄로 재구성하고, 각 항목에서는 `완료 / 미완료 / 00/00 / 00/00P` token만 색상 적용
- profession row 구분선 길이를 실제 one-time 라인 폭에 맞춰 짧게 보정
- 퀘스트 후보목록 scroll edit box에 마우스 입력과 휠 전달을 다시 연결하고, 퀘스트 ID hyperlink click 경로를 복구
- 설정 탭 전투메시지 박스 제목에서 기호를 제거하고 설명문 anchor를 제목 아래로 옮겨 겹침을 줄임
- 버전, README, 인트로, 아키텍처, 인수인계, 릴리스 노트를 `v1.4.1.1` 기준으로 최신화

## 1.4.1 - 2026-03-16

profession overlay 정렬/지도 보정/전투메시지 설정 정리 릴리스.

주요 변경:
- profession overlay tooltip 범례와 완료/미완료 색상을 복구하고, `주  간:` / `1회성:` prefix 정렬을 다시 고정
- profession 1회성 tooltip은 보물/처음발견보너스의 완료/미완료 목록을 숨기고, 평판 지식서/풍요 지식서만 목록을 유지
- profession overlay `1회성` 줄 우클릭 hitbox를 전체 라인으로 넓혀 TomTom waypoint 선택을 더 쉽게 조정
- 지도 오버레이 글자 크기 범위를 더 넓히고, 줄아만 중복 `평판상인` 정리와 영원노래 숲/하란다르/보이드스톰 좌표 보정을 반영
- 지도 라벨 배치 후보를 늘리고 충돌 패널티를 강화해 큰 글자 크기에서 겹침을 더 보수적으로 완화
- 지원하지 않는 child/detail map은 부모 지도 fallback을 막아 외부 라벨이 섞여 보이던 문제를 줄임
- 퀘스트 후보 목록 앞 깨지던 기호를 ASCII로 교체하고, scroll box 휠 스크롤 전달을 보강
- 설정 탭은 `일반 설정 / 글자 크기 / 개요 / 전투메시지` 박스로 재배치하고, 전투메시지는 WoW 기본 on/off가 아니라 표출 방식만 관리하도록 단순화
- 전투메시지 모드 적용 뒤 짧은 재적용 retry를 추가해 로그인/월드 진입 직후 `부채꼴` 모드 반영 실패 가능성을 더 줄임
- README, 인트로, 아키텍처, 인수인계, 변경 이력, 릴리스 노트를 `v1.4.1` 기준으로 최신화

## 1.4.0 - 2026-03-16

지도/typography/profession UX 재정리 릴리스.

주요 변경:
- 메인 창에 `지도` 전용 탭을 추가하고, 지도 오버레이 설정을 기존 설정 탭에서 분리
- 메인 UI, tooltip, 스탯 오버레이, 전문기술 오버레이, 지도 오버레이 글자 크기를 1pt 단위 슬라이더로 조절하는 typography 계층 추가
- 지도 오버레이에 `평판상인` 필터를 별도 추가하고, 영원노래 숲/하란다르/보이드스톰 포탈 위치 라벨을 확장
- 평판 상인 표기를 지도별 NPC 이름 대신 모두 `평판상인`으로 통일
- 전문기술 오버레이 tooltip 문구를 사용자 문장형으로 재작성하고, 목요일 오전 8시 리셋 기준 잔여 시간을 일/시간/분으로 정밀 표시
- profession 카드와 overlay tooltip의 완료/미완료 문구, TomTom 안내, 깨지던 기호 표기를 정리
- `QUEST_TURNED_IN`, `BAG_UPDATE_DELAYED`, `BAG_NEW_ITEMS_UPDATED`, `LOOT_CLOSED` 이후 follow-up refresh를 추가해 드랍/논문/1회성 반영 누락 가능성을 줄임
- profession 1회성 보물 좌표를 Method, wow-professions, Blizzard 포럼 기준으로 다시 대조해 주요 오차를 보정
- 액션바 템플릿 저장/복제/적용/동기화/되돌리기/가져오기/내보내기 경로에 확인 모달을 강제
- 전투메시지 `부채꼴` 모드 적용 시 관련 CVar를 모두 다시 쓰고, 읽어온 값으로 재검증하는 경로를 추가
- README, 인트로, 아키텍처, 인수인계, 변경 이력, 릴리스 노트를 `v1.4.0` 기준으로 최신화

## 1.3.16 - 2026-03-14

전투메시지 설정 복구 및 최신화 릴리스.

주요 변경:
- Midnight에서 기본 옵션에 잘 노출되지 않는 전투메시지 CVar를 설정 탭에서 직접 제어하는 기능 추가
- 전투메시지, 피해 숫자, 치유 숫자, 방향성 피해 분산 on/off와 `위로 / 아래로 / 부채꼴` 모드 선택 추가
- 선택한 전투메시지 프리셋을 로그인과 월드 진입 때 다시 적용하도록 보강
- 전투메시지 설정은 현재 클라이언트 CVar 값을 1회 읽어 초기값으로 가져오도록 설계해 기존 사용자 값을 함부로 덮어쓰지 않도록 조정
- 구렁/던전 시체 약초채집 blank Lua 오류는 최신 사용자 피드백 기준 재현되지 않은 상태로 문서 갱신
- README, 사용자 문서, 인트로, 아키텍처, 인수인계, 보안, 배포 문서를 `v1.3.16` 기준으로 최신화

## 1.3.15 - 2026-03-14

profession 오버레이 가독성 정리 및 문서 최신화 릴리스.

주요 변경:
- profession 오버레이 tooltip 최소 폭을 넓혀 긴 획득원 이름과 안내 문구 줄바꿈을 완화
- profession 오버레이 상단 요약을 상세/요약 모드 모두 `주간 0/0P`, `1회성 0/0P` 형식으로 통일
- 상세 하위 행은 기존 `0/0` 포인트 표기를 유지해 요약과 세부 정보의 역할을 분리
- 더 이상 사용되지 않는 profession overlay locale 키와 dead local 변수를 정리
- 시체 약초채집 오류 추적 문서를 `v1.3.15` 기준 현재 상태로 갱신하고, 실재현 대기 상태를 명시
- README, 사용자 문서, 인트로, 아키텍처, 인수인계, 보안, 배포 문서를 `v1.3.15` 기준으로 최신화

## 1.3.14 - 2026-03-14

전문기술 갱신 안정화 및 tooltip 표기 보정 릴리스.

주요 변경:
- profession/quest refresh 경로에 방어 로직을 추가해 내부 예외가 전체 UI를 깨뜨리지 않도록 보강
- `LOOT_CLOSED` 이후 profession refresh를 다시 확인하도록 연결해 1회성 보물/채집 완료 반영 타이밍을 더 안전하게 보강
- profession 오버레이 tooltip의 진행 표기를 `1/1개 . 3/3P` 형식으로 정리
- 프로젝트 전체 구조 재검토 TODO와 시체 약초채집 오류 추적 TODO를 문서로 추가
- README, 사용자 문서, 인트로, 아키텍처, 인수인계, 보안, 배포 문서를 `v1.3.14` 기준으로 최신화

## 1.3.13 - 2026-03-13

TomTom waypoint 안내 정리 및 소개 보강 릴리스.

주요 변경:
- TomTom waypoint는 정상 동작하며, 하란다르와 공허폭풍 일부 보물은 별도 지역 지도라 해당 지역에 들어가면 생성된다는 설명으로 정리
- profession 오버레이, 설정 세션 안내, 상태 메시지의 TomTom 문구를 실제 동작 기준으로 업데이트
- README, 사용자 문서, 인트로, 아키텍처, 인수인계, 보안, 배포 문서를 `v1.3.13` 기준으로 최신화
- 인트로와 사용자 문서에 TomTom 기반 미완료 전문기술 보물 waypoint 기능을 주요 포인트로 추가

## 1.3.12 - 2026-03-13

문서 및 TomTom 안내 보강 릴리스.

주요 변경:
- 하란다르와 공허폭풍의 일부 profession 1회성 보물 waypoint는 현재 해당 지역 안에 있을 때만 TomTom이 안정적으로 찍는 것으로 확인
- TomTom bridge에 지역 제한 메시지를 추가하고, profession 오버레이 panel 힌트에도 동일 안내를 반영
- README, 사용자 문서, 인트로, 아키텍처, 인수인계, 보안 문서, 배포 문서를 `v1.3.12` 기준으로 최신화
- 릴리스/패키지 경로와 문서 링크를 `v1.3.12` 기준으로 정리

## 1.3.11 - 2026-03-13

문서 및 안정화 릴리스.

주요 변경:
- 루트 문서와 기술 문서를 현재 구조 기준으로 전면 최신화
- `DOC` 폴더를 만들고 설계, 인수인계, 보안, 배포 절차 문서를 재배치
- 최신 릴리스 노트만 루트에 두고 이전 릴리스 노트는 `DOC/archive/release-notes`로 이동
- profession 오버레이, profession 카드, 퀘스트 목록, 설정 패널의 최근 보정 내용을 문서와 변경 이력에 반영
- 퀘스트 후보 목록의 퀘스트 ID 클릭으로 퀘스트 상세를 열 수 있게 보강한 현재 동작을 사용자 문서에 반영
- profession 오버레이 TomTom panel은 일부 항목에서 첫 선택만 안정적으로 동작하는 알려진 이슈로 분리 기록
- 미사용 TomTom bridge 메서드와 사용되지 않는 locale 키를 정리
- 전체 Lua 파일 `luaparser` 파싱과 `git diff --check` 기준으로 정적 검증 실행

## 1.3.10 - 2026-03-13

패치 릴리스.

주요 변경:
- 한밤(Midnight) 지도 오버레이 지원 맵 판정을 더 엄격하게 바꿔 던전 / 공격대 / 구렁 내부 지도에 외부 라벨이 섞여 보이던 버그를 차단
- 지도 라벨 측정 로직을 다시 정리해 이미 수동 줄바꿈된 한국어 라벨이 다시 쪼개지거나 `...`으로 잘리던 문제를 완화
- 전문기술 오버레이와 퀘스트 후보 목록의 색상 escape 포맷을 교정해 `ff`, `9e` 같은 조각이 노출되던 렌더링 오류를 수정
- 전문기술 오버레이 상세 모드의 `주간 / 1회성` 열 폭을 다시 맞추고, 접두어가 잘리던 문제를 보정
- TomTom 설치 시 전문기술 오버레이 row 우클릭으로 다음 미완료 1회성 보물 waypoint를 찍는 기능 추가
- 전문기술 1회성 보물은 한국어 이름이 모호할 때 고유 영어명 fallback과 좌표 데이터를 사용하도록 보강
- 설정 세션 요약과 전문기술 오버레이 툴팁에 TomTom 필요 안내를 추가
- 문서, 버전, 패키지, GitHub 릴리스를 `v1.3.10` 기준으로 갱신

## 1.3.9 - 2026-03-13

패치 릴리스.

주요 변경:
- 메인 UI와 오버레이의 표시 우선순위를 분리해 메인 창은 계속 앞에 두고, 스탯 / 전문기술 오버레이는 기본 WoW 창을 가리지 않도록 strata를 낮춤
- 설정 탭의 스탯 오버레이 크기 라벨을 `캐릭터 스탯 오버레이 크기`로 바꿔 전문기술 오버레이 크기와 헷갈리지 않도록 정리
- 한밤(Midnight) 지도 오버레이는 refresh 중 중복 진입, 월드맵 전환 직후 nil parent, 0 크기 canvas 같은 예외 케이스를 보수적으로 차단하도록 안전장치를 보강
- 지도 오버레이는 내부 오류 발생 시 전체 UI를 깨뜨리지 않고 오버레이만 숨기고 빠지도록 방어 경로를 추가
- 문서, 버전, 패키지, GitHub 릴리스를 `v1.3.9` 기준으로 갱신

## 1.3.8 - 2026-03-12

패치 릴리스.

주요 변경:
- 한밤(Midnight) 지도 오버레이의 던전 / 구렁 / 공격대 데이터를 공식 분류 기준으로 다시 점검하고, 잘못 섞이던 category와 누락된 입구 라벨을 정리
- 이미 줄바꿈된 지도 라벨은 다시 자동 분절되지 않도록 측정 로직을 바꿔 `전문기술 / 허브`, `보이드스톰 / 포탈` 같은 수동 줄바꿈이 그대로 유지되게 수정
- 실버문 전문기술 허브와 포탈 라벨, 외부 지역 던전 / 구렁 / 공격대 위치를 더 보수적인 offset으로 다시 조정
- 전문기술 탭 카드 헤더는 profession 아이콘을 오른쪽으로 옮기고, 우측 포인트 영역을 작은 2줄 블록으로 재설계해 `0/2` 값이 카드 밖으로 넘치지 않도록 수정
- 전문기술 오버레이 상세 모드는 `주간 | ...`, `1회성 | ...` 형태의 정렬된 2열 레이아웃으로 다시 구성하고, 툴팁은 `완료 / 진행` 상태와 한국어 fallback 이름을 더 우선하도록 보강
- 퀘스트 후보 목록은 제목 / 퀘스트 ID / 진행도 / 유지 사유를 색으로 구분해 읽기 쉽게 정리
- 설정 세션 요약의 제작자 표기를 `제작자 / 이름(이메일)` 한 줄 구조로 정리하고, 저장 범위 안내는 그대로 유지
- 문서, 버전, 패키지, GitHub 릴리스를 `v1.3.8` 기준으로 갱신

## 1.3.7 - 2026-03-12

패치 릴리스.

주요 변경:
- 전문기술 탭 카드의 우측 포인트 값을 `포인트 / 수치` 2줄 블록으로 다시 배치해 `0/2` 같은 값이 카드 밖으로 넘치지 않도록 구조를 재정리
- 전문기술 카드와 오버레이는 완료 상태일 때 더 분명한 색상과 `완료` 표기를 사용해 진행 상태를 바로 구분할 수 있게 보강
- 설정 탭은 `전문기술 체크 오버레이` 토글을 왼쪽 기본 설정 컬럼으로 옮겨 지도 라벨 체크박스 영역 overflow를 줄임
- 제작자 정보 표기를 `이름` + `(이메일)` 2줄 형식으로 정리
- 한밤(Midnight) 지도 라벨은 `구렁 허브`, `살육의 거리`, `교정의 재앙` 같은 핵심 한국어 줄바꿈 예외를 직접 고정
- 지도 라벨 배치 후보를 조정해 주변 충돌이 적은 경우에는 아이콘을 가리지 않는 선에서 POI 근처에 더 가깝게 붙도록 보정
- 퀘스트 탭 `안전 정리 대상` 목록에도 항목 간 빈 줄을 넣어 세 섹션 모두 같은 간격 규칙을 사용하도록 통일
- 문서, 버전, 패키지, GitHub 릴리스를 `v1.3.7` 기준으로 갱신

## 1.3.6 - 2026-03-12

패치 릴리스.

주요 변경:
- 한밤(Midnight) 지도 오버레이의 map 해석을 더 보수적으로 바꿔 잘못된 구역 라벨이 다른 지도에 섞여 보일 가능성을 줄임
- 던전 / 구렁 / 공격대 라벨은 `접두어 줄 + 이름 줄` 구조로 통일하고, 한국어 길이 기준 줄바꿈 규칙을 다시 정리
- 실버문 전문기술 라벨과 외부 지역 라벨 크기를 다시 미세 조정하고, 지원 지도 이름 alias를 보강
- 전문기술 탭 카드의 우측 값 영역을 더 압축해 `0/2` 같은 포인트 값이 카드 밖으로 넘치지 않도록 보정
- 전문기술 오버레이는 상세 모드 정렬을 정리하고, 마우스 오버 툴팁으로 주간/1회성 획득원과 objective 상태를 확인할 수 있게 보강
- 퀘스트 후보 목록은 섹션 제목 여백과 항목 간 줄 간격을 다시 정리해 읽기 쉽게 조정
- 설정 탭 세션 요약에 저장 범위를 명시하고, 지도 라벨 체크박스 영역 배치를 더 촘촘하게 정리
- 문서, 버전, 패키지, GitHub 릴리스를 `v1.3.6` 기준으로 갱신

## 1.3.5 - 2026-03-12

패치 릴리스.

주요 변경:
- 전문기술 탭 카드의 우측 진행 / 포인트 영역을 더 압축해 긴 항목이 카드 밖으로 넘치지 않도록 다시 정리
- 실버문과 외부 지역 지도 라벨 크기를 한 단계 더 키우고, 특히 전문기술 허브 라벨이 더 잘 읽히도록 밀집도 보정을 완화
- 한밤(Midnight) 지도 오버레이에 `주요 시설 / 포탈 / 전문기술 / 던전·공격대 / 구렁` 카테고리별 표시 체크박스를 추가
- 퀘스트 후보 목록을 `안전 정리 대상 / 남겨둘 퀘스트 / 전체 포기 대상` 3개 섹션으로 분리해 가독성을 개선
- 설정 탭 현재 세션 요약을 `세션 / 빠른 안내 / 제작자 정보` 문단으로 다시 정리하고, 기호 사용을 `▶` / `→` 중심으로 정리
- 인트로, 사용자 문서, 설계 문서, 인수인계 문서, 배포 문서를 `v1.3.5` 기준으로 최신화

## 1.3.4 - 2026-03-12

패치 릴리스.

주요 변경:
- 한밤(Midnight) 지도 오버레이를 규칙 기반 라벨 배치 구조로 재정리해 접두어, 줄바꿈, 겹침 완화, 축소 상태 보정을 한 곳에서 처리하도록 정리
- 던전 / 구렁 / 공격대 라벨에 `던전:` / `구렁:` / `공격대:` 접두어를 다시 적용하고, 아이콘을 직접 가리지 않도록 위/아래 배치 규칙을 보강
- 평판 / 풍요 상인 라벨에서 NPC 이름을 제거하고 기능명 중심 표기로 통일
- 쿠엘다나스 섬 라벨 지원을 mapID / 이름 기반 fallback까지 포함하도록 보강
- 전문기술 오버레이와 스탯 오버레이 크기 조절을 `XS / S / M / L / XL` 5단계 프리셋으로 확장
- 템플릿 탭 현재 캐릭터 정보에 특성명 표시 추가
- 퀘스트 후보 목록 순서를 `안전 정리 → 남겨둘 퀘스트 → 전체 포기`로 변경하고, 진행 중 퀘스트 objective 진행도 요약을 함께 표시
- 설정 탭 현재 세션 요약을 스크롤 박스로 바꾸고 제작자 이메일을 함께 표시
- 스탯 오버레이는 버프/스탯 변화 이벤트 범위를 더 넓혀 즉시 갱신 가능성을 보강
- 인트로, 사용자 문서, 설계 문서, 인수인계 문서, 배포 문서를 `v1.3.4` 기준으로 정리

## 1.3.3 - 2026-03-12

패치 릴리스.

주요 변경:
- 전문기술 탭 카드의 row 폭과 높이를 다시 정리해 긴 source 이름과 진행 문구가 카드 오른쪽 밖으로 넘치지 않도록 보정
- 전문기술 탭 상단 제어 영역을 다시 배치해 `전문기술 포인트 오버레이 표시` 체크박스가 메인 UI 밖으로 벗어나지 않도록 수정
- 전문기술 탭에서 `작게 / 기본 / 크게` 버튼으로 전문기술 오버레이 크기를 직접 조절할 수 있게 추가
- 전문기술 오버레이 접기 버튼을 더 작은 아이콘형 버튼으로 축소
- 설정 탭에서 `작게 / 기본 / 크게` 버튼으로 스탯 오버레이 크기를 직접 조절할 수 있게 추가
- 한밤(Midnight) 지도 오버레이 줌 배율 곡선을 다시 조정해, 지도 축소 상태에서도 외부 지역 던전 / 구렁 라벨이 상대적으로 덜 작아지도록 보정
- 인트로와 사용자 안내 문서를 포함한 주요 문서를 `v1.3.3` 기준으로 최신화
- 패키징, GitHub 푸시, 릴리스를 `v1.3.3` 기준으로 다시 실행

## 1.3.2 - 2026-03-12

패치 릴리스.

주요 변경:
- 한밤(Midnight) 지도 오버레이 라벨 규칙을 다시 정리해 던전 / 구렁 / 주요 시설 라벨의 과한 공백과 길이를 줄이고, 긴 라벨은 두 줄 표기로 정리
- 지도 라벨 기본 크기를 다시 낮추고 카테고리별 폭을 고정해 줌 연동 상태에서도 긴 이름이 과하게 가로로 퍼지지 않도록 보정
- 쿠엘다나스 섬 지도에 `마법학자의 정원`과 `태양샘 고원` 입구 라벨 추가
- 설정과 전문기술 탭의 `Midnight` 표기를 `한밤(Midnight)` 기준으로 정리
- 전문기술 카드 레이아웃을 다시 압축해 카드가 하단 영역을 덮던 문제를 완화하고, source 설명을 더 짧고 읽기 쉽게 정리
- `Treatise` 용어를 `전문기술 논문`으로 통일하고 퀘스트 탭의 정리 기준 문구를 일반 사용자 기준으로 다시 정리
- 문서, 버전, 패키지, GitHub 릴리스를 `v1.3.2` 기준으로 갱신

## 1.3.1 - 2026-03-12

패치 릴리스.

주요 변경:
- Midnight 지도 오버레이 글자 크기를 전체적으로 다시 낮춰 긴 던전 / 구렁 이름이 과하게 커지지 않도록 조정
- 지도 확대 / 축소 상태를 읽어 지도 오버레이 글자 크기를 완만하게 자동 조정하도록 보강
- 전문기술 탭에 profession 오버레이 표시 체크박스를 추가해 설정 탭과 같은 값을 즉시 제어할 수 있게 변경
- profession 오버레이를 `상세 / 요약 / 최소` 3단 표시 모드로 확장
- 메인 창을 일반 WoW 창보다 앞에서 보이도록 `Raise / Toplevel / FrameStrata` 동작을 보강
- 인트로 문서와 사용자 문서를 일반 플레이어 기준으로 다시 정리하고 소개 톤을 개선
- 문서, 버전, 패키지, GitHub 릴리스를 `v1.3.1` 기준으로 갱신

## 1.3.0 - 2026-03-12

기능 릴리스.

주요 변경:
- 스탯 오버레이 퍼센트 정렬을 투명 패딩 방식에서 고정 폭 컬럼 방식으로 다시 정리해 검은 글자 흔적 문제를 제거
- 스탯 오버레이 상단 헤더를 `캐릭터 직업 - 특성(아이템레벨)` 형식으로 변경
- profession 카드와 profession 오버레이에 profession 아이콘 표시 추가
- profession 오버레이를 접기 / 펼치기 가능한 상세형으로 확장하고, 주간 / 1회성 합계 외에 주퀘 / 드랍 / 논문 / 보물 같은 핵심 획득원 요약을 함께 표시
- profession 툴팁 이름은 한국어 클라이언트에서 공식 퀘스트명을 우선 사용하고, 나머지는 패턴 번역으로 한글화
- profession UI와 툴팁 문구에서 `KP` 중심 표현을 `포인트` 기준으로 정리
- Midnight 지도 오버레이 글자를 카테고리별로 크게 확대하고, 던전 / 구렁 이름을 한국어 라벨로 교체
- 와우 `설정 > 애드온` 패널 전용 레이아웃을 분리해 오른쪽 박스 돌출 문제를 줄임
- `설정 > 애드온 > ABProfileManager` 아래에 `템플릿 / 액션바 / 전문기술 / 퀘스트` 하위 카테고리 추가
- 하위 카테고리는 기존 메인 UI를 건드리지 않고 경량 요약 패널과 `메인 탭 열기` 버튼으로 구성
- 문서, 버전, 패키지, GitHub 릴리스를 `v1.3.0` 기준으로 갱신

## 1.2.1 - 2026-03-12

패치 릴리스.

주요 변경:
- 고스트 자동 재시도 큐가 사용자가 커서에 주문 / 아이템 / 탈것 / 매크로를 들고 있을 때는 실행되지 않도록 막아, 고스트 위 덮어쓰기 시 아이콘이 즉시 떨어지거나 사라지는 간헐 버그를 완화
- 스탯 오버레이 상단에 `캐릭터 - 직업 - 특성` 헤더를 추가
- 스탯 오버레이 프레임 최소 폭과 힛트박스를 실제 텍스트 폭에 가깝게 줄여 월드 프레임 클릭 방해를 완화
- 스탯 퍼센트 정수부에 투명 패딩을 넣어 한 자리수 / 두 자리수 / 세 자리수 정렬을 다시 보정
- 스탯 오버레이는 동일 스냅샷 재렌더를 건너뛰도록 해 불필요한 UI 갱신을 줄임
- 설정 탭 하단 설명 박스를 현재 캐릭터 / 오버레이 상태 / 전문기술 마지막 스캔 / 디버그 세션 상태 요약으로 교체
- 전문기술 자동 추적 계산에 캐시를 추가해 반복 새로고침 비용을 절감
- Midnight 지도 오버레이는 실제로 보일 때만 주기 갱신이 돌도록 바꿔 상시 `OnUpdate` 비용을 줄임
- 문서를 `v1.2.1` 기준으로 갱신하고 GitHub 릴리스 직접 다운로드 주소를 최신화

## 1.2.0 - 2026-03-12

패치 릴리스.

주요 변경:
- 전문기술 주간 체크를 수동 카운터 방식에서 숨은 퀘스트 기반 자동 추적 방식으로 전환
- 주간 퀘스트, Treatise, 주간 필드 드랍, 주간 채집/분해 드랍, 1회성 보물, 평판 지식서, 일부 풍요 지식서, 약초/채광 처음 발견 보너스를 자동 계산하도록 보강
- 전문기술 탭에 재스캔 버튼과 소스별 진행 툴팁 추가
- 설정 탭 레이아웃을 좌측 일반 설정 / 우측 오버레이 설정으로 재배치해 체크박스 넘침 수정
- Midnight 지도 오버레이 글자 크기와 외곽선을 키워 월드맵 가독성 개선
- 실버문 지도에 포탈 이름, 교역소, 형상변환, 암시장, 정복 상인, 던전/구렁 입구 이름 추가
- Eversong Woods, Harandar, Voidstorm, Zul'Aman 지도에 각 진영 평판 상인과 일부 구렁/던전 입구 이름 추가
- 문서를 `v1.2.0` 기준으로 갱신하고 GitHub 릴리스 직접 다운로드 주소를 최신화
- Lua 정적 문법 파싱, 패키징, 릴리스 갱신을 다시 실행

## 1.1.0 - 2026-03-12

기능 릴리스.

주요 변경:
- `전문기술` 탭 추가
- 전문기술별 `주간 획득원 / 1회성 획득원` 체크리스트와 KP 합계 표시 추가
- 주간 전문기술 체크는 캐릭터별로 저장되고 주간 리셋 키 변경 시 자동 초기화되도록 보강
- 별도 `전문기술 체크` 오버레이 추가
- 설정 탭에 전문기술 오버레이 표시 체크박스 추가
- 설정 탭에 `실버문 지도 오버레이` 체크박스 추가
- Midnight 실버문 월드맵에 은행, 여관, 경매장, 포탈, PvP 허브, 전문기술 허브와 주요 전문기술 상인 위치를 글자 오버레이로 표시하는 기능 추가
- 문서를 `v1.1.0` 기준으로 갱신하고 GitHub 릴리스 직접 다운로드 주소를 문서에 추가
- `luaparser` 기반 Lua 문법 파싱으로 전체 Lua 파일 정적 문법 점검 실행

## 1.0.7 - 2026-03-10

패치 릴리스.

주요 변경:
- 스탯 오버레이 퍼센트 표시를 `정수부`와 `소수부` 컬럼으로 분리해 소수점 위치 정렬 보정
- 스탯 퍼센트는 항상 소수 둘째 자리까지 표시
- 캐릭터 스탯 툴팁 재사용 프록시에 폰트를 직접 지정해 `Font not set` 오류 수정
- 문서와 배포 메타데이터를 `v1.0.7` 기준으로 갱신

## 1.0.6 - 2026-03-10

패치 릴리스.

주요 변경:
- 스탯 오버레이 퍼센트 표기를 항상 소수 둘째 자리까지 유지
- 퍼센트 괄호 열을 고정 폭으로 정리해 한 자리수/두 자리수 퍼센트도 소수점 위치 정렬
- 값 영역 툴팁은 Blizzard 캐릭터 스탯 setter를 우선 재사용해 특화 등 스펙별 설명을 최대한 원문에 가깝게 표시
- 문서와 배포 메타데이터를 `v1.0.6` 기준으로 갱신

## 1.0.5 - 2026-03-10

패치 릴리스.

주요 변경:
- 스탯 오버레이의 평점 컬럼 폭을 고정해 퍼센트 시작 위치 정렬 보정

## 1.0.4 - 2026-03-10

패치 릴리스.

주요 변경:
- 치명 / 가속 / 특화 / 유연 수치를 숫자와 퍼센트로 표시하는 텍스트형 스탯 오버레이 추가
- 스탯 오버레이는 투명 배경의 글자 전용 레이아웃으로 표시
- 스탯 오버레이는 드래그 앤 드롭으로 위치 이동 가능
- 스탯 오버레이 마지막 줄에 현재 특성의 PvE 일반 스탯 우선순위 표시 추가
- 특성별 우선순위는 `Midnight 12.0.1` 기준 일반 PvE 가이드 표를 내장해 축약 표시
- 유연 퍼센트는 총 유연 보너스 기준으로 계산되도록 수정
- 오버레이는 라벨/값 2열 구조로 리팩토링해 가독성 개선
- 탱커 특성일 때 회피 / 무막 / 막기 방어 확률 행 추가
- 스탯 표기는 `평점(퍼센트)` 형식으로 압축하고 간격을 재조정
- 2차 스탯은 rating 기준 `30 / 39 / 47 / 54 / 66%` DR 구간에 따라 퍼센트 숫자만 단계적으로 색상 변경
- 스탯 우선순위 줄은 민트 계열 색상으로 재조정
- 오버레이 값 영역에 마우스 오버 설명 툴팁과 DR 구간 안내 추가
- 설정 탭에 스탯 오버레이 표시 체크박스 추가
- 스탯 오버레이 표시 여부와 위치를 SavedVariables에 저장
- 장비 변경 / 전투 평점 변경 / 특화 갱신 / 능력치 갱신 / 오라 변경 시 스탯 오버레이 자동 갱신
- 배포 스크립트가 릴리스 ZIP과 별도 소스 백업 ZIP을 함께 생성하도록 보강

## 1.0.3 - 2026-03-07

패치 릴리스.

주요 변경:
- 메인 타이틀과 설정 영역에 현재 버전 표시 추가
- 템플릿 삭제 버튼을 상단 저장/복제/새로고침 행으로 이동
- 템플릿 정보에 특성명과 기록 통계 표시 추가
- 전체 액션바 비우기 시 2차 검증 패스 추가
- 미니맵 버튼을 더 작은 사각 `AB` 버튼형으로 원복
- 바 모델 문서에 현재 `1~9번`만 지원하고 `10~12번` 특수 바는 미지원이라고 명시
- 문서와 배포 메타데이터를 `v1.0.3` 기준으로 갱신

## 1.0.2 - 2026-03-07

패치 릴리스.

주요 변경:
- 같은 이름 템플릿 저장 시 덮어쓰기 확인창 추가
- 템플릿 저장 UI와 슬래시 저장 경로를 동일한 확인 로직으로 통일
- 문서와 배포 메타데이터를 `v1.0.2` 기준으로 갱신

## 1.0.1 - 2026-03-07

패치 릴리스.

주요 변경:
- 고스트 슬롯 드래그 해제 지원
- 고스트 슬롯 위에 다른 액션을 올려 덮어쓰기 지원
- 수동 변경된 고스트 슬롯의 자동 재시도 해제 보강
- `적용 가능한 칸만 맞추기` 동기화 버튼 추가
- 미니맵 버튼 스케일 축소 및 둥근 아이콘형 정리
- 사용자 문서, 설계 문서, 인수인계 문서 최신화

## 1.0.0 - 2026-03-07

첫 완료 릴리스이자 1차 출시 버전.

포함 기능:
- 액션바 템플릿 저장 / 복제 / 적용 / 삭제
- 전체 / 부분 범위 적용
- 비교 / 동기화
- 최근 1회 되돌리기
- 문자열 내보내기 / 가져오기
- 현재 특성 전환
- 비행 바 `9번 바` 지원
- 전투 중 대기열 처리
- 매크로 검증 강화
- 미니맵 버튼
- 설정 탭
- 퀘스트 정리 / 전체 퀘스트 포기
- 한국어 기본 UI / 영어 옵션
- 사용자 문서, 설계 문서, 인수인계 문서 정리 완료
- 문자열 import 입력 검증 보강
- 전체 퀘스트 포기 강제 확인 보강
- 보안 점검 문서 추가
- GitHub 저장소 업로드 완료
- 배포용 ZIP 패키지 및 릴리스 노트 정리 완료

## 0.4.0 - 2026-03-07

릴리스 후보 단계.

주요 변경:
- 동기화 버튼 설명 UX 개선
- hover 툴팁 / 클릭 시 하단 설명
- 퀘스트 탭 초안 추가
- 액션바 / 템플릿 / 설정 레이아웃 마감
- 미니맵 버튼 단순형 UI 정리

## 0.3.0 - 2026-03-07

중간 통합 단계.

주요 변경:
- 최근 1회 되돌리기 기능 추가
- 문자열 내보내기 / 가져오기 추가
- 템플릿 복제 추가
- 비행 바 저장/적용 범위 포함
- 매크로 적용 검증 강화

## 0.2.0 - 2026-03-06

핵심 기능 구현 단계.

주요 변경:
- 템플릿 저장 / 적용 / 삭제
- 액션바 비교 / 동기화
- 범위 선택 적용
- 전투 중 대기열 처리
- 고스트 오버레이 처리

## 0.1.0 - 2026-03-06

초기 구조 작성 단계.

주요 변경:
- 애드온 기본 구조 생성
- DB / 명령어 / 메인 창 / 모듈 스텁 구성
- 문서 및 구현 준비 자료 작성
