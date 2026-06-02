# ABProfileManager Security Review

검토 기준일: `2026-06-01`

## 범위

- 템플릿 import/export
- profession 자동 추적
- 전투메시지 CVar 제어
- ABPM 보호 오류 로그
- Blizzard 기본 창 이동 관리
- PrivateAuras assertion 방어
- 퀘스트 대량 포기
- 지도 오버레이와 설정 패널
- 스탯 오버레이 특화 tooltip
- BIS 추천 장비 카탈로그 오버레이
- 드랍템 레벨 오버레이
- 파티찾기 시즌 최고기록 아이콘 오버레이
- 스탯 우선순위 표 팝업
- 선택적 TomTom 연동

## 결론

현재 구조상 즉시 악용될 만한 동적 코드 실행 경로는 확인되지 않았다.

핵심 판단:

- `loadstring`, `RunScript` 같은 동적 실행 없음
- 외부 네트워크 전송 없음
- import는 코드 실행이 아니라 데이터 파싱 방식
- 지도/BIS/드랍 오버레이는 로컬 정적 데이터와 Blizzard API 조회만 사용
- hover 설명은 애드온 전용 tooltip frame을 사용하며, 전역 `GameTooltip:SetHyperlink()`로 Blizzard money tooltip을 직접 열지 않음
- TomTom 연동은 선택적 로컬 애드온 호출뿐이며, 미설치 시 fail-safe로 빠짐
- ABPM 보호 오류 로그는 세션 메모리 안에만 저장하며 외부 전송이나 파일 쓰기를 하지 않음
- Lua 오류 팝업을 전역으로 숨기는 `scriptErrors` CVar 변경은 하지 않음

## 주요 안전장치

### 템플릿 문자열

- 길이 제한
- 줄 수 제한
- 허용된 액션 타입만 통과
- 이름 정화
- 제어문자 제거

### 퀘스트 작업

- `전체 포기`는 항상 확인 모달 우선
- 안전 정리는 보수적 조건만 사용
- 퀘스트 링크는 상세 열기 용도만 제공

### profession 추적

- 내장 데이터셋만 사용
- 완료 플래그/숨은 퀘스트 조회만 소비
- 외부 문자열을 실행하지 않음
- refresh 예외가 나도 전체 UI를 깨뜨리지 않도록 보호 경로를 사용

### 전투메시지 설정

- 로컬 CVar 읽기/쓰기만 사용
- 외부 네트워크, 외부 코드 실행, 매크로 주입은 없음
- `_v2` CVar가 없을 때는 구형 이름으로 fallback 하지만, 적용 범위는 전투메시지 관련 CVar에 한정한다

### 보호 오류 로그

- `pcall`로 잡은 ABPM 내부 오류만 세션 버퍼에 기록
- 동일 오류는 count로 압축하고 최대 80개 항목만 유지
- `/abpm log`와 `/abpm errors`는 복사용 UI만 제공하며 파일/네트워크 출력을 하지 않음
- 디버그 모드일 때만 stack trace를 기록하고, 기본 상태에서는 첫 오류 줄만 저장

### 스탯 오버레이 특화 tooltip

- 현재 전문화의 Mastery spellID를 Blizzard API로 조회하고 `C_TooltipInfo.GetSpellByID()` 결과만 읽음
- 전역 `GameTooltip:SetSpellByID()`를 직접 호출하지 않고 애드온 전용 tooltip에 텍스트 라인만 렌더링
- 외부 입력, 네트워크, 동적 코드 실행 없음

### Blizzard 기본 창 이동

- 저장 좌표가 없는 UIPanel 창은 `SetUserPlaced(true)`로 고정하지 않음
- 이전 `layoutVersion`의 저장 좌표는 1회 초기화해 잘못된 중앙 겹침 좌표 재사용을 방지
- WorldMapFrame은 위치 저장/복원 대상이 아니며 기존처럼 드래그 전용 처리만 유지

### PrivateAuras assertion 방어

- `PrivateAuraAnchorContainerMixin.CheckExistingDispelHasCorrectType`의 좁은 충돌 조건만 우회
- private dispel 항목과 public helpful buff가 같은 `auraInstanceID`를 공유하는 경우에만 suppress
- 전역 오류 핸들러, `ScriptErrorsFrame`, `scriptErrors` CVar는 변경하지 않음

### BIS 추천 장비 카탈로그 오버레이

- 게임 런타임의 후보 풀은 `Data/BISCatalog.lua` 정적 카탈로그만 읽는다
- 런타임 merge와 런타임 웹 조회를 하지 않는다
- `DOC/MidnightS1_MPlus_Addon_Master_v1.3.md`와 `DOC/MidnightS1_MPlus_Addon_DB_v1.3.lua`는 릴리스 생성/검증용 오프라인 입력이며 TOC에 직접 로드하지 않는다
- v1.3 DB는 중간 `return DB`를 제거하고 EOF의 최종 `return DB` 하나만 유지한다
- 생성된 카탈로그는 총 `3130`행이다: `mythicplus 2554`, 기존 `raid 285`, 기존 `crafted 91`, `tier 200`
- locale 문자열은 생성 시점에 `koKR/enUS`로 분리 저장되며, 게임 안에서는 해당 locale 필드만 노출한다
- M+/tier row는 `staticFinalBisVerified=false`, `runtimeItemLinkRequired=true`, `mythTrackVerified=false` 메타를 표시하며 itemID만으로 Myth/Hero 트랙이나 최종 BiS를 확정하지 않는다
- `Data/MidnightS1MPlusDB.lua`는 저장소에 고정된 v1.7 컴팩트 코어이며 네트워크나 동적 코드 로드를 하지 않는다
- `Data/BISRuntimeScoring.lua`는 실제 full link를 `C_Item.GetItemStats()`와 `GetDetailedItemLevelInfo()` 기반 점수 함수에 전달한다
- 상단 아이템 토글이 켜져 있으면 `Data/BISMythicVaultLinks.lua`의 검토된 시즌 selector `12801`로 M+ 후보 preview item string을 생성하고, 검증 결과를 계정 SavedVariables snapshot으로 저장한다
- 생성 preview 또는 수동 override full link 자체가 위대한 금고 `Myth 1/6 272`로 검증된 경우에만 snapshot의 실제 스탯 / 실제 ilvl로 자동 점수화한다
- selector 또는 item string 템플릿 변경 시 기존 SavedVariables snapshot cache를 초기화하고, 실제 다른 템렙으로 해석된 preview는 세션 음성 캐시로 반복 재시도를 차단한다
- 던전 종료 `Hero 3/6 266` 링크만 있으면 272 기준 라벨은 표시하되 점수는 미검증 fallback으로 유지한다
- 검토되지 않은 bonusID를 `itemID`와 임의 조합하는 경로는 금지한다. 내장 selector 교체는 `Data/BISMythicVaultLinks.lua`와 validator를 함께 갱신한다
- 스크롤 중 tooltip 렌더 억제, 점수 캐시, 아이템 요청 dedupe, 분산 큐를 사용해 자동 검색 중 rebuild 부담을 제한한다
- 장비/가방 링크는 정렬이나 hover에서 스캔하지 않고, 보유 체크 on 시 저장용 링크를 한 번만 찾는다
- M+ reward profile은 Hero 던전 종료 / Myth 금고 후보 템렙만 저장하고 정적 `itemLink`, `itemString`, bonusID를 만들지 않는다
- `mythicplus`, `raid`만 Encounter Journal 랜딩을 시도하고, `crafted`, `tier`는 랜딩 대상에서 제외한다
- 즐겨찾기/보유 체크는 캐릭터별·전문화별 SavedVariables boolean 상태만 저장하며 외부 입력이나 실행 경로를 추가하지 않는다
- 아이템 캐시 수신 시 visible row를 우선 갱신하고, 자동 점수 재시도가 필요한 경우에만 rebuild한다
- BIS item hover는 `C_TooltipInfo.GetHyperlink()`의 tooltipData 텍스트만 전용 tooltip에 수동 렌더링하며 Blizzard tooltip line color와 품질 색을 보존한다
- 판매가, 화폐, money line은 렌더링하지 않아 `Blizzard_MoneyFrame` secret-number 산술 경로를 피한다
- 전역 `GameTooltip:SetHyperlink()` 직접 호출을 금지해 액션바, 모험 안내서, Pawn 비교 툴팁으로 taint가 이어지는 경로를 줄였다
- hover/자동 큐에서 Encounter Journal UI 상태 변경과 숨은 loot scan을 금지한다. M+/raid 클릭은 공개 열기 경로만 사용한다
- `BISData_Method.lua`, `BISData.lua`, `DOC/MidnightS1_MPlus_Addon_Master_v1.3.md`, `DOC/MidnightS1_MPlus_Addon_DB_v1.3.lua`, `DOC/MidnightS1_MPlus_Addon_Master_v1.7.md`, `DOC/MidnightS1_MPlus_Addon_DB_v1.7.lua`, `scripts/build_bis_catalog.py`, `scripts/build_bis_runtime_scoring.py`, `scripts/validate_bis_mythic_vault_links.py`, `scripts/validate_bis_catalog.py`, `scripts/audit_bis_data.py`, `scripts/rebuild_bis_database.ps1`는 릴리스 준비용 repo 도구다. 이 중 런타임에는 검토된 v1.7 Lua 복사본만 `Data/MidnightS1MPlusDB.lua`로 포함한다
- `scripts/rebuild_bis_database.ps1`는 v1.3 카탈로그 입력 → v1.7 scoring 입력 → Myth preview selector/override validate → catalog validate → audit 순서로 실행한다. M+/tier 추가는 v1.3 파일, 점수 정책은 v1.7 파일에서 관리하며 raid/crafted는 아직 기존 `BISCatalog.lua` 보존 seed이다

### 공통 tooltip / secret-number 방어

- `UI/Widgets.lua`의 `Widgets.GetTooltip()` / `Widgets.HideTooltip()`가 ABPM 자체 hover 설명용 전용 tooltip frame을 관리한다
- 액션바 패널, 전문기술 UI, 지도/스탯/BIS/드랍 오버레이 등 ABPM UI hover는 이 전용 frame을 사용한다
- WoW 12.0.5+의 secret-number 값은 `Utils.SafeNumber()`와 개별 `pcall` 보호 경로를 통해 필요한 곳에서만 숫자로 정규화한다
- `ns:SafeCall(...)`은 모듈 refresh/이벤트 진입점의 예외를 `pcall`로 감싸, 일시적 taint 오류가 전체 UI 오류창으로 번지는 것을 줄인다

### 스탯 우선순위 표

- `Data/StatPriorityTable.lua`의 정적 문자열/숫자 데이터만 표시한다
- 외부 입력, 네트워크 조회, 동적 코드 실행 경로가 없다
- 현재 전문화 강조는 Blizzard specialization ID 조회 결과와 정적 specID map 비교만 사용한다

### 드랍템 레벨 / 시즌 최고기록 오버레이

- 통화, 키, 점수, 던전명은 Blizzard API에서 읽어와 화면에만 렌더한다
- 별도 저장, 전송, 외부 실행 경로는 없다
- 파티찾기 아이콘 오버레이는 기존 Blizzard frame 위에 텍스트만 덧씌운다

### 지도 오버레이

- 외부 입력 없음
- 카테고리 필터는 boolean 설정만 사용
- refresh 예외가 나도 메인 UI를 망가뜨리지 않도록 보수적으로 처리

## 저위험 메모

- TomTom 연동은 하란다르/공허폭풍 일부 보물에서 별도 지역 지도 컨텍스트를 사용한다.
  - 보안 문제가 아니라 외부 애드온 및 맵 컨텍스트 제약에 가깝다.
- 정적 좌표 기반 지도 데이터는 패치 후 drift가 생기면 수동 보정이 필요하다.
- 이 환경은 `lua`/`luac` 대신 `luaparser` 정적 파싱으로 문법 검증을 진행한다.
- BIS 생성 파이프라인은 빌드 머신에서만 외부 데이터를 조회하며, 결과는 정적 Lua 파일로 고정해 출하한다.

## 유지 원칙

- 신규 외부 입력 경로가 생기면 타입/길이/단일행 정화부터 넣는다.
- destructive action은 확인 모달 우선으로 유지한다.
- profession/지도/BIS/드랍 기능은 데이터셋 중심으로 유지하고, 임의 코드 경로를 만들지 않는다.
- 설정 기능은 CVar/로컬 SavedVariables 제어를 넘어서 외부 시스템 호출로 확장하지 않는다.
