# ABProfileManager Architecture

버전 기준: `v1.11.3 로컬 패치 기반, Interface 120005, 120007 / WoW Patch 12.0.5·12.0.7 계열`

## 목적

`ABProfileManager`는 WoW Retail에서 다음 작업을 한 번에 처리하는 관리형 애드온입니다.

- 액션바 템플릿 저장, 비교, 부분 적용, 동기화
- 최근 1회 되돌리기
- 퀘스트 정리
- 전문기술 포인트 자동 추적
- 전투메시지 표출 방식 관리
- 캐릭터 스탯 오버레이
- 한밤(Midnight) 지도 오버레이
- 전체 typography 슬라이더
- 드랍템 레벨 참조 오버레이
- BIS 추천 장비 카탈로그 오버레이
- 파티찾기 시즌 최고기록 아이콘 오버레이
- 한밤 시즌 1 v1.7 기준 40개 전문화 단일 대표 스탯 우선순위 표 팝업

핵심 원칙:

- 기존 메인 UI 레이아웃은 쉽게 흔들지 않는다.
- 액션바와 profession 로직은 데이터 중심으로 유지한다.
- 지도 오버레이는 보수적인 맵 판정과 정적 좌표를 사용한다.
- 글자 크기 변경은 도메인별 typography 계층으로 통합한다.
- 파괴적 작업은 확인창과 입력 검증을 우선한다.
- BIS 정적 후보는 생성된 카탈로그만 읽고, 열기 시점의 병합/웹 조회를 금지한다.
- 애드온 hover 설명은 전용 tooltip frame을 사용하고, 전역 `GameTooltip:SetHyperlink()` 경로로 Blizzard money tooltip을 taint하지 않는다. BIS 수동 tooltip 렌더러는 Blizzard line color와 품질 색을 보존한다.

## 부트스트랩

- `ABProfileManager/Core.lua`
  - 네임스페이스 초기화
  - 시작 시 모듈 초기화
- `ABProfileManager/DB.lua`
  - SavedVariables 초기화
  - 공통 설정, UI 위치, character 데이터 관리
- `ABProfileManager/Events.lua`
  - `ADDON_LOADED`
  - `PLAYER_LOGIN`
  - `PLAYER_ENTERING_WORLD`
  - profession / quest / stats 갱신 이벤트 연결
- `ABProfileManager/Commands.lua`
  - `/abpm` 슬래시 명령 처리
- 현재 비활성/미완성 기능인 `MerchantHelper`, `MailHistory`, `WorldEventOverlay`, `WorldEventSchedule`는 repo에는 유지하지만 패키지 TOC 로드 목록에서는 제외한다.

## 주요 모듈

### 액션바

- `Modules/ActionBarScanner.lua`
  - 현재 액션바 상태 스캔
- `Modules/ActionBarApplier.lua`
  - 실제 적용, 비우기, 전투 중 대기열, 고스트 재시도
- `Modules/ProfileManager.lua`
  - 템플릿 저장, 삭제, 적용
- `Modules/TemplateSyncManager.lua`
  - 비교와 동기화
- `Modules/TemplateTransfer.lua`
  - 문자열 내보내기/가져오기
- `Modules/RangeCopyManager.lua`
  - 전체, 바, 선택 바, 슬롯 범위 해석
- `Modules/SlotMapper.lua`
  - 실제 수정 가능한 슬롯 매핑
- `Modules/UndoManager.lua`
  - 최근 1회 작업 복구
- `Modules/GhostManager.lua`
  - 누락 액션 고스트 표시

### profession / 지도 / 설정

- `Modules/ProfessionKnowledgeTracker.lua`
  - profession별 획득원 집계
  - 완료 퀘스트/숨은 퀘스트 기반 추적
  - 카드/오버레이/툴팁 데이터 제공
- `Modules/CombatTextManager.lua`
  - Midnight 최신 전투메시지 `_v2` CVar와 구형 이름 fallback을 함께 관리
- `Modules/BlizzardFrameManager.lua`
  - 선택적으로 Blizzard 기본 창을 드래그 가능하게 만듦
  - 저장 좌표가 없는 UIPanel 창은 Blizzard 기본 배치에 맡기고, 저장 좌표가 있는 UIPanel 창만 `SetUserPlaced(true)`로 복원
  - `global.settings.blizzardFrames.layoutVersion=2` 이전 저장 좌표는 1회 초기화
- `Modules/PrivateAurasGuard.lua`
  - Blizzard PrivateAuras의 private dispel/public helpful buff auraInstanceID 충돌 assertion만 좁게 완화
- `Modules/TomTomBridge.lua`
  - TomTom 선택적 연동
  - 하란다르/공허폭풍 일부 1회성 보물은 해당 지역 진입 후 waypoint 생성
- `UI/ProfessionKnowledgeOverlay.lua`
  - 상단 요약은 문장형 안내와 정확한 주간 리셋 잔여 시간 표시를 사용
  - tooltip은 범례, 완료/미완료 색상, source별 요약 규칙, TomTom 안내를 함께 노출
- `UI/ConfigPanel.lua`
  - 일반 설정, typography 슬라이더, 개요, 전투메시지 표출 방식 설정
- `UI/MapPanel.lua`
  - 지도 오버레이 전용 탭
  - 지도 글자 크기 슬라이더와 카테고리 필터 제공

### 드랍 / BIS / 시즌 최고기록

- `UI/ItemLevelOverlay.lua`
  - 파티찾기(PVEFrame) 열릴 때 옆에 표시
  - 탭: 개요 / 쐐기 / 구렁 / 레이드 / 기타
  - 각 행: `단/난이도 | 클리어보상 | 드랍문장 | 위대한 금고`
  - 우측 고정 패널에 현재 문장 보유량과 `오늘의 풍요 4개 / 열쇠 파편 / 복원된 열쇠` 표시
  - 구렁 표 보조 행은 `보물지도 사용` 문구를 사용
  - 위치 저장 뒤 재오픈 시 저장 좌표를 우선 복원
  - `CREST_ID_BY_GRADE = { adv=3383, vet=3341, chmp=3343, hero=3345, myth=3347 }`
  - `DELVE_RESTORED_KEY_CURRENCY_ID = 3028`
- `UI/BISOverlay.lua`
  - 현재 캐릭터 클래스의 전 특성 탭과 부위별 추천 장비 카탈로그 렌더
  - 정적 `Data/BISCatalog.lua`를 읽어 slot별 후보를 구성
  - 상단 아이템 토글이 켜져 있으면 `Data/BISMythicVaultLinks.lua`의 내장 selector `12801`로 M+ 후보의 `Myth 1/6 272` preview item string을 자동 생성
  - 생성 preview 또는 수동 override full link 자체가 위대한 금고 `Myth 1/6 272`로 검증된 경우에만 tooltip line, 색상, 실제 스탯 / 실제 ilvl을 계정 SavedVariables 스냅샷으로 저장
  - 저장 스냅샷은 `Data/BISRuntimeScoring.lua` 어댑터로 점수화하고 같은 slot 정렬에 적용
  - selector 또는 item string 템플릿 변경 시 기존 SavedVariables snapshot cache를 초기화
  - 실제 다른 템렙으로 해석된 preview는 세션 음성 캐시에 넣어 반복 큐잉을 방지
  - 저장 스냅샷이 없는 후보는 정적 `overallRank` 순서를 유지
  - 장비/가방 링크는 정렬 또는 hover에서 스캔하지 않고, 보유 체크 on 시 저장용 링크를 한 번만 검색
  - 던전 종료 `Hero 3/6 266` 링크만 있으면 272 기준 라벨은 표시하되 점수는 미검증 fallback으로 유지
  - 임의 bonusID는 조립하지 않고, 오프라인으로 검토한 시즌 selector만 `Data/BISMythicVaultLinks.lua`에서 관리
  - hover/자동 큐에서 Encounter Journal UI 상태를 바꾸거나 숨은 loot scan을 하지 않음
  - 스크롤 중 행 hover tooltip 생성을 잠시 억제하고, 가방/장비 변경 이벤트 전체 rebuild를 제거
  - 점수 캐시, 아이템 요청 dedupe, 분산 큐로 자동 검색 중 rebuild 부담을 완화
  - 필터는 `mythicplus / raid / crafted / tier` 4개 기본 on
  - 필터 적용 후 살아남은 후보를 기준으로 visible rank를 다시 계산
  - 첫 2개는 `1순위 / 2순위`, 이후는 `3순위+` 배지로 표기
  - 아이콘 앞 즐겨찾기/보유 체크박스는 캐릭터별·전문화별 상태를 저장
  - 즐겨찾기 항목은 `무기` 위 최상단 섹션으로 이동하고, 보유 아이템명은 취소선 표시
  - `아이템명 / 드랍 출처 / 트랙·검증 상태 / 우선순위` 중심 열 구성
  - 헤더에 현재 전문화 스탯 정책과 정적 최종 BiS 미확정 상태를 표시
  - M+ 항목은 `rewardProfiles`로 던전 종료 Hero 3/6 266 / 위대한 금고·Voidcore Myth 1/6 272 대표 후보 트랙과 템렙을 표시
  - M+ 자동 검색 큐는 내장 selector preview를 만들고 수동 override full link를 우선 적용하며, 링크 자체가 위대한 금고 Myth 1/6 272로 검증된 경우에만 실제 스탯 / 실제 ilvl로 점수화
  - `mythicplus`, `raid`만 가능한 경우 Encounter Journal loot 탭 랜딩
  - `crafted`, `tier`는 Encounter Journal 랜딩 대상에서 제외
  - M+ 행 hover는 저장된 272 스냅샷의 tooltip 텍스트와 Blizzard line color, 품질 색을 전용 tooltip에 수동 렌더링하고, 없으면 미검증 안내만 표시
  - `GET_ITEM_INFO_RECEIVED`는 전체 rebuild 대신 visible row patch만 수행
  - 헤더 마우스 휠로 0.5~2.0배 스케일 조절
  - 위치 / 스케일 / 접기 상태를 저장하고 재오픈 시 복원
- `UI/MythicPlusRecordOverlay.lua`
  - `ChallengesFrame.DungeonIcons` 위에 `평점 + 던전명` 표시
  - 시간 라인은 사용하지 않음
  - 긴 한글 던전명은 별도 줄바꿈 규칙 적용
  - Utility 탭 체크박스로 on/off

## 데이터 계층

- `Data/Defaults.lua`
  - SavedVariables 기본값
  - BIS source filter 기본값은 `mythicplus/raid/crafted/tier` 전부 on
- `Data/ProfessionKnowledge.lua`
  - profession별 획득원 정의
- `Data/ProfessionKnowledgeWaypoints.lua`
  - profession 1회성 보물 좌표
- `Data/SilvermoonMapData.lua`
  - 한밤(Midnight) 지도 라벨 정의
- `Data/StatPriorities.lua`
  - 스탯 오버레이 한 줄 표시용 한밤 시즌 1 v1.7 단일 대표 우선순위
- `Data/StatPriorityTable.lua`
  - 메인 창 `스탯 우선순위 표` 팝업이 표시하는 한밤 시즌 1 v1.7 기준 40개 전문화 표
  - 전문화별 단일 대표 우선순위와 현재 전문화 매칭용 specID map 포함
- `Data/ItemLevelTable.lua`
  - 컨텐츠별 드랍 아이템 레벨 테이블
  - `ns.Data.BISRewardProfiles`로 BIS row가 참조할 대표 보상 트랙 정의
  - M+ row 라벨과 자동 검색 full link 검증용 위대한 금고 Myth 1/6 272 대표 프로필 제공
- `Data/BISCatalog.lua`
  - 런타임에서 직접 읽는 단일 BIS 정적 후보 카탈로그
  - v1.11.3 기준 총 `3130`행: `mythicplus 2554`, `raid 285`, `crafted 91`, `tier 200`
  - row별 `specID, slot, itemID, nameKoKR, nameEnUS, sourceGroup, sourceLabel, overallRank, sourceRank` 보관
  - `dungeon / boss / profession / catalyst / rewardProfiles` 등 source detail과 locale별 표기를 함께 저장
  - v1.11.0부터 v1.7 단일 대표 우선순위와 M+/tier row별 `staticFinalBisVerified`, `bisValidationLevel`, `runtimeItemLinkRequired`, `requiresRuntimeItemLink`, `mythTrackVerified`, `staticPriorityStatus`, `v13Evidence`, `statPrioritySummary` 메타를 함께 저장
- `Data/MidnightS1MPlusDB.lua`
  - `DOC/MidnightS1_MPlus_Addon_DB_v1.7.lua`에서 설치한 컴팩트 런타임 점수 코어
  - 실제 `itemLink`에서 아이템 레벨과 스탯을 읽어 전문화별 점수를 계산
- `Data/BISRuntimeScoring.lua`
  - ABPM specID, slot, sourceGroup을 v1.7 코어 키로 변환하는 네임스페이스 어댑터
  - 검증된 Myth snapshot과 필요 시 실제 itemLink 점수를 캐시
- `Data/BISMythicVaultLinks.lua`
  - Midnight 시즌 1 M+10 금고 Myth 1/6 selector `12801`, 예외 항목용 full link override, 선택적 사전 스캔 snapshot을 보관
  - selector preview와 등록 override는 클라이언트에서 한 번 스캔한 뒤 계정 SavedVariables snapshot으로 재사용
  - 런타임이 실제 item level을 다시 검증하므로 검토되지 않은 bonusID를 넣지 않음
- `Data/BISData_Method.lua`
  - Wowhead `current Overall BiS` seed 입력
- `Data/BISData.lua`
  - Wowhead `Best Gear from Mythic+` + seed fallback 입력
- `DOC/MidnightS1_MPlus_Addon_Master_v1.3.md`
  - v1.10.0 M+/티어 카탈로그 정책을 정리한 사람용 오프라인 생성 입력
  - 실제 `itemLink` 기반 점수 엔진 연결은 후속 설계 범위로 분리
- `DOC/MidnightS1_MPlus_Addon_DB_v1.3.lua`
  - v1.10.0 M+/티어 카탈로그 생성용 오프라인 입력
  - 중간 `return DB`를 제거하고 EOF의 최종 `return DB` 하나만 유지
  - TOC에 직접 로드하지 않으며 런타임 데이터 소스가 아니다
- `DOC/MidnightS1_MPlus_Addon_Master_v1.7.md`
  - 실제 `itemLink` 점수화 정책과 UI 연동 규칙을 정리한 컴팩트 가이드
- `DOC/MidnightS1_MPlus_Addon_DB_v1.7.lua`
  - 40개 전문화 스탯 가중치와 런타임 점수 API를 제공하는 설치 입력
- `scripts/refresh_wowhead_bis.py`
  - Wowhead `current Overall BiS` 40 spec 데이터를 `Data/BISData_Method.lua`로 재생성
- `scripts/refresh_wowhead_mplus_fallbacks.py`
  - Wowhead M+ 추천 후보를 `Data/BISData.lua`로 재생성
- `scripts/build_bis_catalog.py`
  - 기존 DOC/Wowhead 경로 또는 `--addon-db` v1.3 DOC DB 경로로 `Data/BISCatalog.lua`를 생성
  - v1.3 DOC DB 경로에서는 기존 `raid 285` / `crafted 91`행을 보존하고 `mythicplus 2554` / `tier 200`행을 생성
  - dungeon/source alias canonicalization, locale 누수 검사, itemID 검증, 정적 링크 미생성 검증을 포함
  - v1.3 입력은 정적 후보 풀 생성 기준으로 유지
- `scripts/build_bis_runtime_scoring.py`
  - v1.7 코어를 런타임 경로에 설치하고 40개 전문화 스탯 표와 BIS 정책 메타를 갱신
- `scripts/rebuild_bis_database.ps1`
  - v1.3 카탈로그 입력 → v1.7 scoring 입력 → Myth preview selector/override validate → catalog validate → audit 순서의 통합 재생성 진입점
  - M+/tier 추가는 v1.3 파일만 갱신 가능하고, 점수 정책은 v1.7 파일에서 관리
  - raid/crafted는 아직 기존 `BISCatalog.lua` 보존 seed이므로 완전 단일 seed 재생성은 후속 범위
- `scripts/validate_bis_catalog.py`
  - v1.3 정적 후보 풀과 v1.7 런타임 코어를 분리 검증
  - 40개 전문화, 기존 raid/crafted row 보존, M+ reward profile, 정적 itemLink/bonusID 미생성, crafted/tier 비프로필 정책을 검증
- `scripts/validate_bis_mythic_vault_links.py`
  - `Data/BISMythicVaultLinks.lua`의 baseline, 시즌 selector `12801`, override 카탈로그 itemID 포함 여부, full item string 형식을 검증
- `scripts/validate_bis_reward_profiles.py`
  - M+ BIS row가 유효한 보상 프로필 key를 참조하는지 검증

## UI 계층

- `UI/MainWindow.lua`
  - 메인 프레임과 탭 전환
- `UI/Widgets.lua`
  - 공통 위젯 헬퍼와 애드온 전용 tooltip frame(`Widgets.GetTooltip`, `Widgets.HideTooltip`) 제공
- `UI/ProfilePanel.lua`
  - 현재 캐릭터, 템플릿 목록, 템플릿 작업
- `UI/ActionBarPanel.lua`
  - 범위 선택, 비교, 동기화
- `UI/ProfessionPanel.lua`
  - profession 카드, 오버레이 설정, 재스캔
- `UI/MapPanel.lua`
  - 지도 탭, 포탈/평판상인 필터, 지도 글자 크기 조절
- `UI/QuestPanel.lua`
  - 퀘스트 후보 목록, 안전 정리, 전체 포기
- `UI/ConfigPanel.lua`
  - 메인 설정 탭
- `UI/AddonSettingsPages.lua`
  - 와우 `설정 > 애드온` 하위 카테고리
- `UI/Typography.lua`
  - 도메인별 글자 크기 보정과 tooltip 폰트 재적용
- `UI/StatsOverlay.lua`
  - 캐릭터 스탯 오버레이
  - 특화 tooltip은 현재 전문화의 Mastery spell tooltip data를 ABPM 전용 tooltip에 렌더링
- `UI/StatPriorityDialog.lua`
  - 한밤 시즌 1 v1.7 기준 직업/전문화별 단일 대표 스탯 우선순위 표 팝업
- `UI/ProfessionKnowledgeOverlay.lua`
  - profession 포인트 오버레이
- `UI/SilvermoonMapOverlay.lua`
  - 한밤(Midnight) 지도 텍스트 오버레이
- `UI/ItemLevelOverlay.lua`
  - 드랍 아이템 레벨 참조 오버레이
- `UI/BISOverlay.lua`
  - BIS 추천 장비 카탈로그 오버레이
- `UI/MythicPlusRecordOverlay.lua`
  - 시즌 최고기록 아이콘 오버레이
- `UI/UtilityPanel.lua`
  - 편의기능 탭

## 저장 구조

### 계정 공통

- `global.settings`
  - 언어
  - 확인창
  - 디버그
  - 오버레이 표시 여부
  - BIS source filter / 잠금 상태
  - typography 도메인별 오프셋
  - 지도 라벨 카테고리 필터
  - 마우스 이동 자동 복구
  - Blizzard 기본 창 이동 설정과 저장 좌표 layout version

### UI

- `ui`
  - 메인 창 위치
  - profession 오버레이 위치/모드/scale
  - stats 오버레이 위치/scale
  - itemLevelOverlay 위치/scale/currentTab/collapsed/anchorMode
  - bisOverlay 위치/scale/collapsed/anchorMode

### 캐릭터별

- profession 진행 상태
- 캐릭터 기본 정보
- 템플릿 작성 시 원본 캐릭터 메타데이터
- 사용자가 켠 전투메시지 표출 방식 상태
- 전문화별 BIS 즐겨찾기/보유 아이템 상태

## BIS 카탈로그 흐름

1. `DOC/MidnightS1_MPlus_Addon_Master_v1.3.md`와 `DOC/MidnightS1_MPlus_Addon_DB_v1.3.lua`를 M+/티어 오프라인 입력으로 준비
2. `scripts/rebuild_bis_database.ps1`
3. 내부에서 `scripts/build_bis_catalog.py --addon-db` → `scripts/build_bis_runtime_scoring.py` → `scripts/validate_bis_mythic_vault_links.py` → `scripts/validate_bis_catalog.py` → `scripts/audit_bis_data.py` 순서로 실행
4. 생성 결과 `Data/BISCatalog.lua`, `Data/MidnightS1MPlusDB.lua`, `Data/BISRuntimeScoring.lua`를 패키지에 포함
5. 게임 런타임에서는 `UI/BISOverlay.lua`가 정적 후보와 `Data/BISMythicVaultLinks.lua`의 selector preview 또는 override에서 저장한 SavedVariables snapshot 점수를 함께 사용

seed 경계:

- M+/tier 추가는 v1.3 파일만 갱신할 수 있다.
- 점수 정책은 v1.7 파일에서 관리한다.
- 시즌 selector 교체 또는 예외 항목용 Myth 1/6 272 full link override 추가는 `Data/BISMythicVaultLinks.lua`만 갱신한다.
- raid/crafted는 아직 기존 `BISCatalog.lua` 보존 seed이므로 완전 단일 seed 재생성은 후속 범위다.

런타임 규칙:

- open/spec/filter 전환은 단일 rebuild 경로를 사용
- slot grouping과 정렬 키는 생성 시점에 최대한 고정
- locale 선택은 row에 저장된 `nameKoKR/nameEnUS`, `displaySourceKoKR/displaySourceEnUS`를 우선 사용하고, legacy `boss/source` 값은 런타임 alias 정규화로 마지막 누수를 막는다
- `GET_ITEM_INFO_RECEIVED`는 icon/quality/item hyperlink 보정이 필요한 visible row만 patch
- BIS hover tooltip은 전역 `GameTooltip:SetHyperlink()`를 호출하지 않고, tooltipData line과 Blizzard line color, 품질 색을 수동 렌더링한다
- 상단 아이템 토글이 켜져 있으면 `Data/BISMythicVaultLinks.lua`의 selector `12801`로 M+ 후보 preview item string을 자동 생성한다
- 생성 preview 또는 수동 override full link 자체가 위대한 금고 `Myth 1/6 272`로 검증된 경우에만 tooltip/stat snapshot을 SavedVariables에 저장하고 실제 스탯 / 실제 ilvl로 점수화한다
- 던전 종료 `Hero 3/6 266` 링크만 있으면 272 기준 라벨은 표시하되 점수는 미검증 fallback으로 유지한다
- M+ 자동 검색은 검토되지 않은 bonusID를 조립하지 않는다
- M+/tier row는 정적 최종 BiS가 아니며 실제 `itemLink`/bonusID와 심크/QE/로그 검증이 필요하다는 메타를 함께 표시한다
- 검증 snapshot이 없는 후보는 정적 순서를 유지한다
- selector 또는 item string 템플릿 변경 시 이전 SavedVariables snapshot cache를 초기화하고, 다른 템렙으로 해석된 preview는 같은 세션에서 반복 재시도하지 않는다
- 장비/가방 링크는 정렬이나 hover에서 스캔하지 않고, 보유 체크 on 시 저장용으로만 한 번 찾는다
- hover/자동 큐에서 Encounter Journal UI 상태를 바꾸거나 숨은 loot scan을 하지 않는다
- 스크롤 중 tooltip 렌더 억제, 점수 캐시, 아이템 요청 dedupe, 분산 큐로 자동 검색 중 rebuild 부담을 완화한다
- money/currency/sell-price line은 렌더링하지 않는다. 이 규칙은 `Blizzard_MoneyFrame` secret-number taint 회귀 방지용이다

## 회귀 포인트

- BIS 필터 on/off 후 visible rank가 기대대로 다시 계산되는지
- 즐겨찾기/보유 체크가 캐릭터별·전문화별로 분리 저장되고, 즐겨찾기 섹션/보유 취소선이 즉시 갱신되는지
- `레이드 off + 쐐기만 on`에서 쐐기 드랍템과 인던명이 남는지
- M+ BIS row에 위대한 금고 Myth 1/6 272 baseline이 표시되는지
- 상단 아이템 토글 on/off에 따라 M+ selector preview 자동 생성이 활성화/비활성화되는지
- `Myth 1/6 272`로 검증된 selector preview 또는 override만 실제 스탯 / 실제 ilvl 자동 점수화를 받는지
- 던전 종료 `Hero 3/6 266` 링크만 있으면 272 기준 라벨은 표시되고 점수는 미검증 fallback으로 유지되는지
- 검증된 272 snapshot이 재접속 뒤에도 재사용되는지
- BIS hover/자동 큐 뒤 Encounter Journal hover에서 `MoneyFrame.lua secret number` 오류가 재발하지 않는지
- 자동 점수 분산 큐가 rebuild를 과도하게 반복하지 않는지
- tooltip에 정적 최종 BiS 아님, 런타임 링크 필요, itemID만으로 Myth 트랙 미확정 문구가 표시되는지
- `제작 + 티어만 on`에서 Encounter Journal 잘못 랜딩이 없는지
- BIS hover 뒤 액션바 / 모험 안내서 / Pawn item tooltip에서 `MoneyFrame.lua secret number` 오류가 재발하지 않는지
- BIS 수동 tooltip이 Blizzard line color와 품질 색을 보존하는지
- `koKR`에서 영어 누수, `enUS`에서 한글 누수가 없는지
- 스크롤 thumb, 마지막 열 가림, 저장 위치/스케일, 접힘 상태 복원이 유지되는지
- `스탯 우선순위 표` 버튼, 현재 전문화 강조, 긴 분기 문구 줄바꿈이 유지되는지
