# ABProfileManager Security Review

검토 기준일: `2026-08-28` (v1.12.0 / WoW 12.1.0 기준)

v1.13.0의 변경(오버레이 결함 수정, 로케일 키 추가, 전문기술 데이터 추가, 스탯 우선순위 갱신)은 아직 별도 보안 검토를 하지 않았다. 새 외부 입력이나 실행 경로를 추가하지 않은 데이터·문자열 변경이다.

## 범위

입력 경로, 파괴적 작업, CVar 제어, 외부 의존성, tooltip / secret-number 방어를 본다. 대상은 템플릿 import/export, profession 자동 추적, 전투메시지 CVar, ABPM 보호 오류 로그, Blizzard 기본 창 이동, PrivateAuras assertion 방어, 퀘스트 대량 포기, 지도/스탯/BIS/드랍템/시즌 최고기록 오버레이, 스탯 우선순위 표, 선택적 TomTom 연동, 오프라인 빌드 도구다.

## 결론

즉시 악용될 만한 동적 코드 실행 경로는 확인되지 않았다.

- `loadstring`, `RunScript` 같은 동적 실행 없음
- 외부 네트워크 전송 없음. import는 코드 실행이 아니라 데이터 파싱
- 오버레이는 로컬 정적 데이터와 Blizzard API 조회만 사용
- ABPM 보호 오류 로그는 세션 메모리에만 남고 파일/네트워크 출력 없음
- 전역 `scriptErrors` CVar를 바꾸지 않음
- 로컬 배포는 작업공간 `dist/` ZIP 생성까지만 수행하며 WoW 설치 폴더로 복사하지 않음
- TomTom 연동은 선택적 로컬 애드온 호출뿐이며 미설치 시 fail-safe

## 12.1 aura 접근 제한

12.1은 전투, 레이드 조우, 쐐기, PvP 중 aura를 보호 상태로 만든다. 이 상태에서 `C_UnitAuras`의 index / slot / instanceID 기반 조회는 Lua 오류를 내고, `UnitAura` 계열은 secret payload를 돌려준다. spellID 기반 조회는 정상이다.

- `UI/StatsOverlay.lua`의 player 버프 hash가 유일한 영향 지점이다. `C_UnitAuras.GetAuraDataByIndex` 호출을 `pcall`로 감싸고, 실패하면 `2.0초` backoff를 걸어 매 refresh마다 오류 경로를 다시 밟지 않는다.
- 실패 시 부분 hash 대신 빈 문자열을 돌려준다. 잘린 hash로 상태 서명이 흔들리지 않게 하기 위함이다. `GetTime()`이 없으면 backoff를 걸지 않고 그대로 진행한다.
- aura 데이터의 `spellId` / `expirationTime` / `applications`는 `safeNumber()`를 거쳐 문자열 포맷에 들어간다. secret 값을 산술이나 `string.format`에 직접 넘기지 않는다.
- 새 aura 코드는 index/slot 조회 대신 spellID 경로를 쓴다.
- `Modules/PrivateAurasGuard.lua`는 `PrivateAuraAnchorContainerMixin`이 없으면 조용히 넘어간다. 12.1에서 추가 작업이 필요 없었다.

## 입력 경로

### 템플릿 문자열

- 길이 제한, 줄 수 제한, 허용된 액션 타입만 통과, 이름 정화, 제어문자 제거

### 퀘스트 작업

- `전체 포기`는 항상 확인 모달 우선
- 안전 정리는 보수적 조건만 사용
- 퀘스트 링크는 상세 열기 용도만 제공

### profession 추적

- 내장 데이터셋만 사용하고 완료 플래그/숨은 퀘스트 조회만 소비
- 외부 문자열을 실행하지 않으며, refresh 예외가 나도 전체 UI를 깨뜨리지 않도록 보호 경로를 사용

## CVar와 설정

### 전투메시지

- 로컬 CVar 읽기/쓰기만 사용. 외부 네트워크, 외부 코드 실행, 매크로 주입 없음
- `_v2` CVar가 없으면 구형 이름으로 fallback하되 적용 범위는 전투메시지 관련 CVar로 한정

### Blizzard 기본 창 이동

- 저장 좌표가 없는 UIPanel 창은 `SetUserPlaced(true)`로 고정하지 않음
- 이전 `layoutVersion`의 저장 좌표는 1회 초기화
- WorldMapFrame은 위치 저장/복원 대상이 아니며 드래그 전용 처리만 유지

### PrivateAuras assertion 방어

- `PrivateAuraAnchorContainerMixin.CheckExistingDispelHasCorrectType`에서 private dispel 항목과 public helpful buff가 같은 `auraInstanceID`를 공유하는 좁은 조건만 우회
- 전역 오류 핸들러, `ScriptErrorsFrame`, `scriptErrors` CVar는 변경하지 않음

### 보호 오류 로그

- `pcall`로 잡은 ABPM 내부 오류만 세션 버퍼에 기록. 동일 오류는 count로 압축하고 최대 `80`개 항목만 유지
- `/abpm log`와 `/abpm errors`는 복사용 UI만 제공하며 파일/네트워크 출력을 하지 않음
- 디버그 모드일 때만 stack trace를 기록하고 기본 상태에서는 첫 오류 줄만 저장

## tooltip / secret-number 방어

- ABPM UI hover 설명은 `UI/Widgets.lua`의 `Widgets.GetTooltip()` / `Widgets.HideTooltip()` 전용 프레임을 쓴다. 액션바 패널, 전문기술 UI, 지도/스탯/BIS/드랍 오버레이가 모두 이 경로다.
- 스탯 오버레이 특화 tooltip은 Blizzard API로 현재 전문화의 Mastery spellID를 조회해 `C_TooltipInfo.GetSpellByID()` 결과 라인만 렌더링한다. 전역 `GameTooltip:SetSpellByID()`를 직접 호출하지 않는다.
- BIS 아이템 hover 전용 frame은 addon-owned Blizzard item tooltip이다. `SetHyperlink()` 호출 전에 `isShopping`을 세워 shopping tooltip 경로로 렌더링하므로 sell price `MoneyFrame`이 열리지 않는다. 이 경로가 액션바 / 모험 안내서 / Pawn 비교 툴팁으로 taint가 번지던 문제의 회귀 방지 조건이다.
- `StatsOverlay`의 미사용 `PaperDollFrame_Set*` tooltip setter 호출은 제거했고 다시 연결하지 않는다.
- WoW 12.0.5+의 secret-number 값은 `Utils.SafeNumber()`와 개별 `pcall` 보호 경로를 통해 필요한 곳에서만 숫자로 정규화한다. 정규화에 실패하면 원본 secret 값을 전파하지 않고 `0`으로 fallback한다.
- `ns:SafeCall(...)`은 모듈 refresh와 이벤트 진입점의 예외를 `pcall`로 감싼다.

## BIS 추천 장비 카탈로그 오버레이

### 시즌 불일치 차단 (v1.12.0)

BIS 데이터는 시즌 1 기준으로 동결됐고 시즌 2 M+ 던전 풀과 겹치지 않는다. `UI/BISOverlay.lua`의 `SeasonGuard`가 저하를 숨기지 않게 처리한다.

- 판정은 `Data/ItemLevelTable.lua`의 `season`과 BIS 쪽 `dataSeason = "Midnight Season 1"` 문자열 비교뿐이다. 새 API를 쓰지 않는다.
- 불일치면 Encounter Journal 자동 랜딩, M+ 자동 점수화, preview snapshot 스캔, preview 순위 점수를 모두 끈다. 실패를 반복 시도하지 않으므로 무효한 preview 요청이 큐에 쌓이지 않는다.
- 상단 안내에 `[S1]` 접두와 경고색을 붙인다. 후보 목록과 순위 계산, 카탈로그 데이터는 건드리지 않는다.
- `DB:GetBISOverlayMythPreviewCache()`의 무효화 키에 현재 시즌이 들어가 시즌이 넘어가면 이전 시즌 snapshot을 한 번 비운다.

### 데이터와 조회 경로

- 게임 런타임 후보 풀은 `Data/BISCatalog.lua` 정적 카탈로그(총 `3330`행: `mythicplus 2554`, `raid 485`, `crafted 91`, `tier 200`)만 읽는다. 런타임 merge와 런타임 웹 조회는 없다.
- locale 문자열은 생성 시점에 `koKR/enUS`로 분리 저장되며 게임 안에서는 해당 locale 필드만 노출한다.
- M+/tier row는 `staticFinalBisVerified=false`, `runtimeItemLinkRequired=true`, `mythTrackVerified=false` 메타를 표시하며 itemID만으로 트랙이나 최종 BiS를 확정하지 않는다.
- `Data/MidnightS1MPlusDB.lua`는 저장소에 고정된 v1.7 컴팩트 코어이며 네트워크나 동적 코드 로드를 하지 않는다. `Data/BISRuntimeScoring.lua`는 실제 full link를 `C_Item.GetItemStats()`와 `GetDetailedItemLevelInfo()` 기반 점수 함수에 전달한다.
- preview item string 템플릿은 시즌 2 기준이다. `Data/BISMythicVaultLinks.lua`는 `baselineItemLevel = 318`이고 시즌 2 selector는 인게임 미확인이라 `nil`이다. `Data/BISSeasonPreviewLinks.lua`의 검증 범위는 raid/tier `318~334`, crafted `331`이며 링크 표는 비어 있다. 런타임은 이를 그대로 신뢰하지 않고 Blizzard tooltip의 실제 item level과 `Myth/신화` text를 다시 확인한다. 시즌 불일치 상태에서는 SeasonGuard가 이 스캔 자체를 막는다.
- 검토되지 않은 bonusID를 `itemID`와 임의 조합하는 경로는 금지한다. selector 교체는 해당 데이터 파일과 validator를 함께 갱신한다.
- 검증에 실패하면 기본 `itemLink` 또는 `item:<itemID>` tooltip으로 fallback하고 성공한 링크만 세션 캐시에 재사용한다.
- `mythicplus`, `raid`만 Encounter Journal 랜딩을 시도한다. `crafted`, `tier`는 제외다. 보호된 `C_EncounterJournal.SetTab`을 직접 호출하지 않고 전투 중에는 자동 랜딩을 건너뛴다.
- hover와 자동 큐에서 Encounter Journal UI 상태를 바꾸거나 숨은 loot scan을 하지 않는다.
- 즐겨찾기/보유 체크는 캐릭터별·전문화별 SavedVariables boolean만 저장한다.
- 스크롤 중 tooltip 렌더 억제, 점수 캐시, 아이템 요청 dedupe, 분산 큐로 rebuild 부담을 제한한다. 장비/가방 링크는 정렬이나 hover에서 스캔하지 않고 보유 체크 on 시 한 번만 찾는다.
- 시즌 preview 상태와 helper는 `SourcePreview` 테이블 필드로 묶어 WoW Lua chunk의 200-local 제한을 넘지 않게 유지한다. 현재 top-level local은 `198`이다.

## 그 밖의 오버레이

### 드랍템 레벨 / 시즌 최고기록

- 통화, 키, 점수, 던전명은 Blizzard API에서 읽어 화면에만 렌더한다. 별도 저장, 전송, 외부 실행 경로는 없다.
- 시즌 2 문장 통화 ID는 `3442~3446`, 복원 열쇠는 `3028`이다. 조회 결과가 `nil`이면 오류 대신 `-`로 표시한다.
- 파티찾기 아이콘 오버레이는 기존 Blizzard frame 위에 텍스트만 덧씌운다. `ChallengesFrame` 지연 로드에서도 훅은 1회만 설치된다.

### 스탯 우선순위 표

- `Data/StatPriorityTable.lua`의 정적 문자열/숫자 데이터만 표시한다. 외부 입력, 네트워크 조회, 동적 코드 실행이 없다.
- 현재 전문화 강조는 Blizzard specialization ID 조회 결과와 정적 specID map 비교만 사용한다.

### 지도 오버레이

- 외부 입력 없음. 카테고리 필터는 boolean 설정만 사용하고, refresh 예외가 나도 메인 UI를 망가뜨리지 않는다.

## 오프라인 도구

`scripts/` 아래 생성기와 검증기, `DOC/MidnightS1_MPlus_Addon_*` 입력 파일은 릴리스 준비용 repo 도구이며 TOC에 로드하지 않는다. 런타임에는 검토된 결과 Lua 파일만 포함한다.

- BIS 생성 파이프라인은 빌드 머신에서만 외부 데이터를 조회하고 결과는 정적 Lua로 고정해 출하한다.
- `scripts/run_season2_validation.ps1`은 Lua 전체 파싱, `git diff --check`, 동결 파일 해시 검사, 아이템 레벨표, 로케일 계약, 기존 BIS 검증 6종을 순서대로 실행한다. `-Strict`는 출처가 외부 가이드뿐인 값을 실패로 처리한다.
- `scripts/validate_season2_scope.py`가 동결 BIS 파일 10종과 `ItemLevelTable.lua`의 `BISRewardProfiles` 블록이 byte-identical인지 확인한다. 해시가 어긋나면 릴리스를 중단한다.
- `scripts/strip_lua_comments.py`는 소스 Lua 주석을 제거하며 위 동결 파일과 `BISRewardProfiles` 블록은 제외한다. 주석 제거는 문자열 리터럴과 코드에 손대지 않아야 하므로 실행 후 Lua 전체 파싱을 확인한다.
- `scripts/validate_bis_tooltip_contract.py`는 `UI/BISOverlay.lua` top-level local 개수도 검사해 `main function has more than 200 local variables` 로드 오류 재발을 막는다.

## 저위험 메모

- TomTom 연동은 하란다르/공허폭풍 일부 보물에서 별도 지역 지도 컨텍스트를 쓴다. 보안 문제가 아니라 외부 애드온과 맵 컨텍스트 제약이다.
- 정적 좌표 기반 지도 데이터는 패치 후 drift가 생기면 수동 보정이 필요하다.
- 이 환경은 `lua`/`luac` 대신 `luaparser` 정적 파싱으로 문법을 검증한다.
- `Data/ItemLevelTable.lua`의 `delves` / `mythicPlus` / `raid` / `pvp`는 아직 출처가 외부 가이드다. 표시 수치가 실제와 다를 수 있으며 `-Strict` 검증이 이를 릴리스 차단으로 처리한다.

## 유지 원칙

- 신규 외부 입력 경로가 생기면 타입/길이/단일행 정화부터 넣는다.
- destructive action은 확인 모달 우선으로 유지한다.
- profession/지도/BIS/드랍 기능은 데이터셋 중심으로 유지하고 임의 코드 경로를 만들지 않는다.
- 설정 기능은 CVar/로컬 SavedVariables 제어를 넘어 외부 시스템 호출로 확장하지 않는다.
- 보호 상태 API(12.1 aura 계열)는 `pcall` + backoff + 안전 기본값 조합으로만 접근한다.
