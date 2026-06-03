# ABProfileManager Handoff

버전 기준: `v1.11.8 로컬 패치 기반`

## 0-new. v1.11.8 로컬 패치 메모

- BIS 오버레이 상단 아이템 툴팁 체크박스는 신규 기본값과 기존 SavedVariables 1회 마이그레이션 모두 on으로 둔다.
- 사용자가 체크박스를 직접 토글하면 `_itemTooltipUserConfiguredV1`을 저장해 이후 선택을 유지한다.
- 티어 BIS hover에서 클라이언트가 full `itemLink`를 아직 반환하지 않으면 기본 `item:<itemID>` 링크도 addon-owned Blizzard `GameTooltip:SetHyperlink()`에 시도한다.
- 성공한 기본 itemID 링크는 `DEFAULT_ITEM_TOOLTIP_LINK_CACHE`에 저장해 같은 세션에서 재사용한다.
- 임의 bonusID 조립 금지, M+ `Myth/신화 1/6 272` snapshot, shopping tooltip 기반 `MoneyFrame` 차단은 유지한다.
- 로컬 배포는 작업공간 `dist/ABProfileManager-v1.11.8.zip` 생성까지만 수행한다. WoW 설치 폴더로 복사하지 않는다.

## 0-prev. v1.11.7 로컬 패치 메모

- 레이드 / 제작 / 티어 BIS hover도 상단 아이템 토글 on 시 addon-owned Blizzard `GameTooltip:SetHyperlink()` 기본 item tooltip을 표시한다.
- 이 출처들은 검증된 시즌 full link가 없는 정적 `itemID` 후보이므로 임의 bonusID를 조립하지 않는다.
- 클라이언트가 로드한 기본 `itemLink`는 세션 메모리 `DEFAULT_ITEM_TOOLTIP_LINK_CACHE`에 재사용한다.
- M+ `Myth/신화 1/6 272` snapshot과 shopping tooltip 기반 `MoneyFrame` 차단은 유지한다.
- 로컬 배포는 작업공간 `dist/ABProfileManager-v1.11.7.zip` 생성까지만 수행한다. WoW 설치 폴더로 복사하지 않는다.

## 0-prev. v1.11.6 로컬 패치 메모

- Midnight 시즌 selector `12801`은 extracted ItemBonus DB2 build `12.0.1.66838`에서 검토했다.
- 상단 아이템 토글이 켜져 있으면 검증된 `Myth/신화 1/6 272` full item link를 계정 SavedVariables snapshot schema v3로 한 번 저장하고 이후 hover/점수화에서 재사용한다.
- M+ BIS hover는 snapshot full item link를 addon-owned Blizzard `GameTooltip:SetHyperlink()`에 전달해 Blizzard 원본 2차 스탯을 표시한다.
- BIS 전용 item tooltip은 shopping tooltip 경로를 사용해 sell price `MoneyFrame` 렌더링을 차단한다.
- `StatsOverlay`에서 미사용 `PaperDollFrame_Set*` setter를 제거했다.
- `Utils.SafeNumber()`는 secret 값을 일반 숫자로 정규화하지 못하면 원본을 돌려주지 않고 `0`으로 fallback한다.
- 로컬 배포는 작업공간 `dist/ABProfileManager-v1.11.6.zip` 생성까지만 수행한다. WoW 설치 폴더로 복사하지 않는다.
- 원격 GitHub 공개 최신 릴리스와 직접 다운로드는 아직 `v1.11.0`을 유지한다.

## 0-prev. v1.11.5 로컬 패치 메모

- BIS 드랍 출처 클릭의 Encounter Journal 랜딩에서 보호된 `C_EncounterJournal.SetTab` 직접 호출을 제거했다.
- 전투 중에는 자동 랜딩을 건너뛰어 Blizzard 보호 기능 차단 팝업을 방지한다.
- 비전투 중 M+ 랜딩은 현재 시즌 tier 선선택, availability guard, 검증된 `JournalInstanceID` 경로를 유지한다.
- 로컬 배포는 작업공간 `dist/ABProfileManager-v1.11.5.zip` 생성까지만 수행한다. WoW 설치 폴더로 복사하지 않는다.
- 원격 GitHub 공개 최신 릴리스와 직접 다운로드는 아직 `v1.11.0`을 유지한다.

## 0-prev. v1.11.4 로컬 패치 메모

- M+ Encounter Journal 랜딩은 검증된 `JournalInstanceID`를 사용한다. 한밤 시즌 1 기준은 `Magisters' Terrace 1300`, `Maisara Caverns 1315`, `Nexus-Point Xenas 1316`, `Windrunner Spire 1299`, `Algeth'ar Academy 1201`, `Seat of the Triumvirate 945`, `Skyreach 476`, `Pit of Saron 278`이다.
- M+ 랜딩은 현재 시즌 tier를 먼저 선택하고 availability guard를 통과한 경우에만 대상 던전 loot 탭을 연다.
- selector preview hyperlink가 아직 로드되지 않아 snapshot이 비어 있으면 비동기 아이템 로드 뒤 exact selector 링크를 다시 검증한다. 실패 콜백은 timeout으로 정리하고 링크별 재시도는 세션에서 최대 2회로 제한한다.
- M+ 행 hover도 저장 snapshot이 없을 때 selector preview hyperlink의 즉시 해석을 한 번 시도한다.
- 로컬 패키지는 `dist/ABProfileManager-v1.11.4.zip`이다. 원격 GitHub 공개 최신 릴리스와 직접 다운로드는 아직 `v1.11.0`을 유지한다.

## 0-prev. v1.11.3 로컬 패치 메모

- `Data/BISMythicVaultLinks.lua`에 Midnight 시즌 1 M+10 금고 Myth 1/6 selector `12801`을 고정했다.
- 상단 아이템 토글이 켜져 있으면 수동 full link가 없는 M+ 후보도 `item:<itemID>...:1:12801` preview item string을 자동 생성한다.
- selector `12801`은 샘플 신형/구형 던전 아이템에서 `272`, `Myth 1/6`, 2차 스탯 반환을 오프라인 검증했다.
- 생성 preview도 클라이언트 tooltip이 실제 `272`로 확인된 경우에만 SavedVariables snapshot으로 저장하고 점수화한다.
- selector 또는 item string 템플릿 변경 시 기존 SavedVariables snapshot cache를 초기화한다.
- 실제 다른 템렙으로 해석된 preview는 세션 음성 캐시에 넣어 rebuild마다 다시 큐잉하지 않는다.
- `linksByItemID`는 자동 생성으로 처리할 수 없는 예외 항목용 수동 override로 유지한다.
- 검토되지 않은 bonusID를 임의로 조립하지 않는다.
- 로컬 패키지는 `dist/ABProfileManager-v1.11.3.zip`이다. 원격 GitHub 공개 최신 릴리스와 직접 다운로드는 아직 `v1.11.0`을 유지한다.

## 0-prev. v1.11.2 로컬 패치 메모

- BIS 목록 스크롤 중에는 행 hover tooltip 생성을 `0.20초` 억제한다. 휠과 custom thumb drag가 같은 경로를 사용한다.
- 상단 아이템 토글이 켜져 있으면 `Data/BISMythicVaultLinks.lua`의 검증 full link를 한 번 스캔하고 계정 공통 `global.settings.bisOverlay.mythPreviewCache`에 tooltip/stat 스냅샷을 저장한다.
- 저장 스냅샷은 tooltip line 색상, 실제 스탯, 실제 ilvl을 포함한다. 이후 hover와 자동 점수화는 SavedVariables 스냅샷만 사용한다.
- 정확한 `Myth 1/6 272` full link가 없는 후보는 272 수치를 추측하지 않는다. 미검증 안내만 표시한다.
- 슬롯 정렬과 hover 경로에서 장비/가방 링크 우선 처리를 제거했다. 보유 체크 on 시 저장용 링크를 한 번 찾고, 그 링크가 실제 272이면 스냅샷에도 저장한다.
- `BAG_UPDATE_DELAYED`, `PLAYER_EQUIPMENT_CHANGED` 기반 BIS 전체 rebuild를 제거했다.
- 과거 Encounter Journal preview 경로의 미사용 보조 함수와 rebuild 시 가방 링크 인덱스 생성 코드를 제거했다.
- 로컬 패키지는 `dist/ABProfileManager-v1.11.2.zip`이다. 원격 GitHub 공개 최신 릴리스와 직접 다운로드는 아직 `v1.11.0`을 유지한다.

## 0-prev. v1.11.1 로컬 패치 메모

- BIS item tooltip 수동 렌더러는 Blizzard tooltip line color와 품질 색을 보존한다.
- 상단 아이템 토글이 켜져 있으면 링크가 없는 M+ 후보 full link를 `Data/BISMythicVaultLinks.lua`에서 자동 검색한다.
- 자동 검색 full link 자체가 위대한 금고 `Myth 1/6 272`로 검증된 경우에만 해당 링크의 실제 스탯 / 실제 ilvl로 자동 점수화한다.
- 던전 종료 `Hero 3/6 266` 링크만 있으면 272 기준 라벨은 표시하되 점수는 미검증 fallback으로 유지한다.
- `itemID`만으로 `itemLink`/bonusID를 조립하지 않는다.
- 실제 장비/가방 링크가 있으면 검증 DB 링크보다 우선한다.
- hover/자동 큐에서 Encounter Journal UI 상태 변경과 숨은 loot scan을 제거해 `MoneyFrame` taint 경로를 차단했다.
- 점수 캐시, 아이템 요청 dedupe, 분산 큐로 자동 검색 중 rebuild 스로틀 부담을 줄였다.
- `scripts/rebuild_bis_database.ps1`는 v1.3 카탈로그 입력 → v1.7 scoring 입력 → curated Myth link validate → catalog validate → audit 순서로 실행한다.
- M+/tier 추가는 v1.3 파일만 갱신할 수 있고 점수 정책은 v1.7 파일에서 관리한다. raid/crafted는 아직 기존 `BISCatalog.lua` 보존 seed이므로 완전 단일 seed 재생성은 후속 범위다.
- 로컬 패키지는 `dist/ABProfileManager-v1.11.1.zip`이다. 원격 GitHub 공개 최신 릴리스와 직접 다운로드는 아직 `v1.11.0`을 유지한다.

## 0-prev. v1.11.0 메모

- `DOC/MidnightS1_MPlus_Addon_Master_v1.7.md`와 `DOC/MidnightS1_MPlus_Addon_DB_v1.7.lua`는 정적 후보 풀 교체 파일이 아니다. 실제 `itemLink`를 점수화하는 컴팩트 런타임 코어다.
- 정적 후보 풀은 v1.3 입력으로 생성한 `Data/BISCatalog.lua` 총 `3130`행을 유지한다: `mythicplus 2554`, 기존 `raid 285`, 기존 `crafted 91`, `tier 200`.
- `scripts/build_bis_runtime_scoring.py`는 v1.7 코어를 `Data/MidnightS1MPlusDB.lua`로 설치하고 `Data/StatPriorities.lua`, `Data/StatPriorityTable.lua`, BIS 정책 메타를 갱신한다.
- `Data/BISRuntimeScoring.lua`는 ABPM specID, slot, sourceGroup을 v1.7 키로 변환한다.
- `UI/BISOverlay.lua`는 실제 소유 `itemLink`가 있는 후보끼리 v1.7 점수를 우선 적용한다. 링크가 없는 후보는 기존 정적 순서로 fallback한다.
- 장비/가방 링크 인덱스는 rebuild마다 한 번만 만든다. 후보 행마다 가방 전체를 다시 스캔하지 않는다.
- `scripts/validate_bis_catalog.py`는 v1.3 정적 풀과 v1.7 런타임 코어를 분리 검증한다.

## 0-prev. v1.10.0 메모

- `DOC/MidnightS1_MPlus_Addon_Master_v1.3.md`와 `DOC/MidnightS1_MPlus_Addon_DB_v1.3.lua`가 BIS 카탈로그 오프라인 생성 입력으로 추가됐다. 둘 다 TOC에 직접 로드하지 않는다.
- v1.3 DB는 중간 `return DB`를 제거하고 EOF의 최종 `return DB` 하나만 유지한다. 생성 입력을 보정할 때 중간 return을 다시 넣지 않는다.
- `scripts/build_bis_catalog.py --addon-db`는 40개 전문화 단일 대표 스탯 우선순위를 생성된 `Data/StatPriorities.lua`, `Data/StatPriorityTable.lua`, `Data/BISCatalog.lua` 정책 메타에 반영한다.
- `Data/BISCatalog.lua`는 총 `3130`행을 유지한다: `mythicplus 2554`, 기존 `raid 285`, 기존 `crafted 91`, `tier 200`.
- v1.3 런타임 점수 정책은 `runtimeItemLinkRequired`, `requiresRuntimeItemLink`, `staticPriorityStatus`, `v13Evidence`, `statPrioritySummary` 같은 생성 메타데이터까지만 반영한다.
- 실제 `itemLink` 기반 점수 엔진 연결은 후속 설계 범위다. 현재 게임 런타임이 v1.3 DB의 점수 함수를 호출한다고 가정하면 안 된다.
- v1.9.0의 캐릭터별·전문화별 BIS 즐겨찾기/보유 상태, 최상단 즐겨찾기 섹션, 보유 아이템명 취소선은 그대로 유지한다.

## 0-prev. v1.9.0 메모

- `DB.lua`는 캐릭터 record 아래 전문화별 BIS item 상태를 저장한다. itemID마다 `favorite`, `owned`만 유지하고 둘 다 꺼지면 해당 item 상태를 제거한다.
- `UI/BISOverlay.lua`는 아이콘 앞에 즐겨찾기/보유 체크박스를 표시한다. 즐겨찾기 item은 원래 부위 대신 `무기` 위 최상단 `즐겨찾기` 섹션에 모으고, 보유 item 이름은 취소선으로 표시한다.
- M+ item hover preview는 Encounter Journal 신화 던전(M0) Champion 1/6 `246` 기준을 사용한다.
- `GameTooltip:SetHyperlink()` 직접 호출 금지, source filter, `crafted/tier` 비랜딩, `mythicplus/raid` Encounter Journal guard 정책은 유지한다.

## 0-prev. v1.8.0 메모

- BIS M+/티어 후보는 당시 `DOC/MidnightS1_MPlus_Addon_DB_v1.0.lua`를 오프라인 입력으로 `scripts/build_bis_catalog.py --addon-db`에서 생성했다. 현재 입력은 v1.3으로 교체됐다.
- 게임 런타임 BIS 데이터 소스는 계속 `ABProfileManager/Data/BISCatalog.lua` 하나다. 생성 결과에는 `ns.Data.BISItems`와 `ns.Data.BISSpecPolicies`가 함께 들어간다.
- 새 생성 경로는 기존 `raid`와 `crafted` row를 현재 카탈로그에서 보존하고, M+/tier 후보만 새 DOC DB 기준으로 재생성한다.
- M+ row의 `rewardProfiles`는 `mplus_end_of_dungeon` Hero 3/6 266과 `mplus_great_vault_voidcore` Myth 1/6 272 후보를 담지만, `itemString`/`itemLink`/bonusID는 정적으로 만들지 않는다.
- row 메타는 기본적으로 `staticFinalBisVerified=false`, `runtimeItemLinkRequired=true`, `mythTrackVerified=false`이다. itemID만으로 Hero/Myth 트랙이나 최종 스탯을 확정하지 않는다.
- `UI/BISOverlay.lua`는 헤더에 현재 전문화 스탯 정책과 "정적 최종 BiS 아님" 상태를 표시하고, tooltip에 런타임 링크 필요/심크 필요/Myth 후보 미검증 상태를 분리 표시한다.
- `scripts/validate_bis_catalog.py`는 40개 전문화, 기존 raid row 보존, M+ reward profile, 정적 링크 미생성, crafted/tier 비프로필 정책을 검증한다.

## 0-prev. v1.7.6 메모

- `UI/StatsOverlay.lua`의 특화 tooltip은 `C_SpecializationInfo.GetSpecializationMasterySpells()`로 현재 전문화의 Mastery spellID를 얻고, `C_TooltipInfo.GetSpellByID()` line을 ABPM 전용 tooltip에 렌더링한다.
- 전역 `GameTooltip:SetSpellByID()`를 직접 쓰지 않는다. v1.7.4 이후 GameTooltip/MoneyFrame taint 방어 정책과 동일하게 addon-owned tooltip 수동 렌더링을 유지한다.
- 특화 tooltip에도 기존 평점 기여/DR 구간 안내를 뒤에 붙인다.

## 0-prev. v1.7.5 메모

- `Modules/BlizzardFrameManager.lua`는 저장 좌표가 없는 UIPanel 창을 `SetUserPlaced(true)`로 고정하지 않는다. 기본 배치가 없는 상태에서 UserPlaced를 강제로 켜면 캐릭터/은행/특성 등 Blizzard 기본 창이 중앙에 겹칠 수 있다.
- 은행/전투부대 은행은 `BankFrame` 기준으로 UIPanel 대상에 포함했다. `UIPanelWindows` 런타임 감지도 함께 사용하므로 수동 `uiPanel=true` 누락이 있어도 실제 UIPanel 창은 같은 규칙을 탄다.
- `global.settings.blizzardFrames.layoutVersion`은 `2`이다. 이전 저장 좌표는 1회 비워서 과거 중앙 겹침 좌표가 계속 복원되지 않게 한다.
- `/abpm log`와 `/abpm errors`는 디버그 로그와 ABPM 보호 오류 로그를 함께 보여준다. 보호 오류는 `Utils.RecordCaughtError()`에 세션 한정으로 저장되며, 같은 오류는 count로 압축한다.
- `Core.lua`의 `SafeCall`, 모듈 초기화, `Events.lua` 이벤트 dispatch, `ConfigPanel`/`MainWindow` 주요 버튼 콜백은 보호 오류 로그 경로를 탄다.
- `Modules/PrivateAurasGuard.lua`는 Blizzard PrivateAuras의 private dispel/public helpful buff auraInstanceID 충돌 assertion만 좁게 우회한다. 전역 `scriptErrors` CVar는 건드리지 않는다.

## 0-prev. v1.7.4 메모

- ABPM UI hover 설명은 전역 `GameTooltip`을 직접 쓰지 않고 `UI/Widgets.lua`의 `Widgets.GetTooltip()` / `Widgets.HideTooltip()` 전용 프레임을 사용한다. 새 hover 설명을 추가할 때도 이 경로를 유지한다.
- 패키지 TOC는 WoW Patch 12.0.5/12.0.7 계열 대응을 위해 `Interface: 120005, 120007`이다. 스탯 우선순위 표 데이터는 별도 재검증 전까지 Patch 12.0.5 baseline으로 유지한다.
- `UI/BISOverlay.lua`의 BIS 아이템 hover는 `GameTooltip:SetHyperlink()` 금지다. `C_TooltipInfo.GetHyperlink()`의 tooltipData line을 수동 렌더링하고, money/currency/sell-price 계열 라인은 건너뛴다.
- 위 규칙은 액션바, Encounter Journal, Pawn 비교 툴팁에서 `Blizzard_MoneyFrame/Mainline/MoneyFrame.lua` secret-number 산술 오류가 ABPM taint로 표기되던 문제의 회귀 방지 조건이다.
- `Data/ItemLevelTable.lua`에 `ns.Data.BISRewardProfiles.mythicplus`가 추가됐다. M+ BIS row는 `rewardProfiles`로 던전 종료 / 위대한 금고·Voidcore 대표 트랙과 템렙을 표시한다.
- `Data/StatPriorityTable.lua`와 `UI/StatPriorityDialog.lua`가 추가됐다. 메인 창 유틸리티 영역의 `스탯 우선순위 표` 버튼에서 Patch 12.0.5 기준 40개 전문화 표를 연다.
- `scripts/validate_bis_reward_profiles.py`는 기존 XLSX 생성 경로의 M+ 보상 프로필 연결 상태를 검증한다. v1.8.0 새 DOC DB 경로의 릴리스 검증은 `scripts/validate_bis_catalog.py`를 우선 사용한다.
- 인게임 확인 시 ABPM UI hover 뒤에 액션바 아이템, 모험 안내서 아이템, Pawn 비교 툴팁을 순서대로 마우스오버해 `MoneyFrame.lua secret number` 오류가 재현되지 않는지 본다.
- 언어 기본값은 클라이언트 기준이다. `koKR` 클라이언트는 한국어, `enUS/enGB`와 현재 미지원 locale은 영어로 시작한다. 기존 영어 클라이언트에 저장된 우발적 `koKR` 기본값은 `languageUserSelected ~= true`일 때 1회 `enUS`로 보정한다.

## 0-prev. v1.7.3 메모

- `UI/StatsOverlay.lua` `BuildStateSignature`에 인스턴스 컨텍스트(`IsInInstance()`)와 player 활성 buff hash(`spellId:expirationTime*10:applications`, slot 1..40)를 추가했다.
- `Refresh(options)`는 `{ force = true }` 옵션을 받는다. `lastStateSignature` / `lastSnapshotSignature`를 우회하며, 외부에서 `StatsOverlay:InvalidateState()`로 캐시를 명시 무효화할 수 있다.
- `Events.lua`는 `ZONE_CHANGED_NEW_AREA`, `PLAYER_ENTER_COMBAT`, `PLAYER_LEAVE_COMBAT`을 추가 등록한다. 인스턴스 진입 / 특성 변경 / 장비 교체 시 force refresh 경로를 사용한다.
- `UNIT_AURA` 디바운스는 `STATS_SLOW_REFRESH_DELAY` (0.45s) → `STATS_REFRESH_DELAY` (0.15s)로 단축됐다. 트링킷 발동/물약/외부 버프 반응성 우선이다.
- `Modules/ActionBarApplier.lua`에 `DismissAllPendingGhosts()`가 추가됐다. `Modules/GhostManager:RefreshGhosts()`가 자동으로 후처리를 한다.
- `UI/ActionBarPanel.lua`의 sync 영역에 `clearGhostsButton` 행이 추가됐다. Locale 키는 `ghost_clear_all_button / ghost_clear_all_tip / ghost_clear_all_long / ghost_clear_all_none / ghost_clear_all_done`.
- `Data/BISCatalog.lua`는 12.0.5 (2026-04-23) 핫픽스 기준으로 출처 라벨 / 보스 매핑 / 트링킷 우선순위를 재검증하고 보정했다. 런타임 정책(`Data/BISCatalog.lua` 단일 소스, 4 sourceGroup, visible 후보 재번호화)은 유지된다.

## 현재 상태

프로젝트는 실제 인게임 사용 기준으로 유지되는 WoW Retail 애드온이다. 문서 세트는 루트 `README.md`를 사용자 안내로, `DOC` 아래 문서를 기술/운영 문서로 유지한다.

현재 기준 핵심 기능:

- 액션바 템플릿 저장, 적용, 비교, 부분 적용, 동기화, 최근 1회 되돌리기
- 전문기술 포인트 자동 추적 카드와 오버레이
- Midnight 전투메시지 표출 방식 관리
- 퀘스트 정리와 퀘스트 ID 상세 열기
- 캐릭터 스탯 오버레이
- 한밤(Midnight) 지도 오버레이
- 지도 전용 탭과 typography 슬라이더
- 와우 `설정 > 애드온` 경량 하위 페이지
- 드랍템 레벨정보 오버레이
- BIS 추천 장비 카탈로그 오버레이
- 파티찾기 시즌 최고기록 아이콘 오버레이
- 스탯 우선순위 표 팝업
- 블리자드 기본 UI 창 이동 자유화
- 편의기능 탭 통합

## 0. v1.7.0 BIS 카탈로그 재정비 메모

- `Data/BISCatalog.lua`가 BIS 런타임 단일 데이터 소스다. `Data/BISData_Method.lua`, `Data/BISData.lua`는 생성기 입력으로만 쓴다.
- spec 기준은 **40 spec 전체**다. 누락이 나면 먼저 `scripts/refresh_wowhead_bis.py`, `scripts/build_bis_catalog.py` 검증 실패부터 확인한다.
- 새 sourceGroup은 `mythicplus / raid / crafted / tier` 4개다. DB 기본값과 migration도 이 4개를 전제로 한다.
- 필터 적용 후 visible list 기준으로 `1순위 / 2순위 / 3순위+`를 다시 번호 매긴다. 예전처럼 전체 rank를 고정 노출하는 구조가 아니다.
- `레이드 off + 쐐기만 on` 상태에서도 각 부위의 쐐기 드랍템과 인던이 남아야 한다. 이 조건이 깨지면 release blocker로 본다.
- locale은 row에 저장된 `nameKoKR/nameEnUS`, `displaySourceKoKR/displaySourceEnUS`를 그대로 쓴다. 런타임 번역 fallback을 넣지 않는 편이 안전하다.
- 한글명은 `공식 KR 표기 > Wowhead koKR > DOC companion 검증 통과값` 우선순위로 생성한다.
- `공결탑 제나스`, `알게타르 대학` 같은 alias는 생성기에서 canonical name으로 정규화한다. 런타임에서는 canonical label만 읽는다.
- 오버레이 open/spec/filter 전환은 단일 rebuild 경로를 유지한다. `GET_ITEM_INFO_RECEIVED`는 visible row patch만 처리한다.
- crafted/tier는 Encounter Journal 랜딩 대상이 아니다. `mythicplus/raid`만 비전투 중 랜딩을 유지한다.
- v1.11.4에서 한밤 시즌 1 M+ 8개 던전 direct `JournalInstanceID`를 검증값으로 고정했다.
- v1.11.5에서 보호된 `C_EncounterJournal.SetTab` 직접 호출을 제거하고, 전투 중 자동 랜딩을 건너뛰도록 보강했다.

## 0-prev. v1.6.0 오버레이 UX 핫픽스 메모

- `UI/BISOverlay.lua`와 `UI/ItemLevelOverlay.lua`의 마우스 휠 스케일링 기준점을 타이틀바(TOPLEFT)로 고정했다. 수식: `left * oldScale / newScale`.
- `UI/MainWindow.lua`의 `RefreshLocale()`에서 `SetText()` 후 `applyTabSelectionStyles()`를 재호출해 탭 텍스트 색상 소실을 방지한다.
- `UI/BISOverlay.lua`의 `Refresh()`에서 `RebuildContent()` 직후 접힌 상태면 `ApplyCollapse()`를 다시 호출해 프레임 높이를 복원한다.
- `UI/BISOverlay.lua`와 `UI/ItemLevelOverlay.lua`의 FrameStrata를 `DIALOG` → `MEDIUM`으로 변경했다. PVEFrame과 같은 레이어에 위치시켜 캐릭터창/스킬창 등 상위 strata 창에 자연스럽게 가려지도록 한다.

## 1. 회귀 민감 메모

### BIS 추천 장비 오버레이

- `UI/BISOverlay.lua`는 폭/열 간격/스크롤 영역 민감도가 높다. 열 폭만 조정하지 말고 실제 스크롤 thumb와 마지막 열 가림 여부까지 같이 확인해야 한다.
- source 판정은 `sourceGroup` 정적 값을 우선 사용한다. 예전 `sourceLabel` 재분류 로직에 다시 기대지 않는 편이 안전하다.
- `crafted`, `tier`는 랜딩하지 않는다. 이 경로를 건드릴 때는 `openEncounterJournalForEntry()`의 조기 return을 같이 본다.
- M+ BIS hover preview는 전용 `ABProfileManagerBISTooltip`에 저장 snapshot의 full item link를 `SetHyperlink()`로 전달해 Blizzard 원본 2차 스탯을 표시한다. 이 addon-owned item tooltip은 shopping tooltip 경로를 사용해 sell price `MoneyFrame` 렌더링을 차단한다.
- 즐겨찾기/보유 상태는 캐릭터 record 안에서 전문화별로 분리한다. 즐겨찾기 섹션 이동과 보유 취소선 갱신을 함께 확인한다.
- 상단 아이템 토글이 켜져 있으면 M+ 후보는 extracted ItemBonus DB2 build `12.0.1.66838`에서 검토한 `Data/BISMythicVaultLinks.lua`의 selector `12801` preview를 자동 생성한다.
- 생성 preview 또는 수동 override full link 자체가 위대한 금고 `Myth 1/6 272`로 검증된 경우에만 해당 링크의 실제 스탯 / 실제 ilvl로 점수화한다. 던전 종료 `Hero 3/6 266` 링크만 있으면 272 기준 라벨만 표시하고 점수는 미검증 fallback으로 유지한다.
- selector preview hyperlink가 아직 로드되지 않아 snapshot이 없으면 비동기 아이템 로드 뒤 exact selector 링크를 다시 검증한다. 실패 callback은 timeout으로 정리하고 링크별 재시도는 세션 최대 2회로 제한한다. M+ 행 hover도 snapshot이 없을 때 즉시 해석을 한 번 시도한다.
- M+ 자동 검색은 검토되지 않은 bonusID를 임의 조립하지 않는다.
- M+/tier의 정적 최종 BiS 미확정 정책은 유지한다. 장황한 hover 경고는 다시 늘리지 않는다.
- 장비/가방 링크는 정렬이나 hover에서 다시 스캔하지 않는다. 보유 체크 on 시 저장용 링크를 한 번 찾고, 스크롤 중 tooltip 렌더 억제, 점수 캐시, 아이템 요청 dedupe, 분산 큐 규칙을 유지한다.
- hover/자동 큐에서 Encounter Journal UI 상태를 바꾸거나 숨은 loot scan을 다시 연결하지 않는다.
- `StatsOverlay`에 미사용 `PaperDollFrame_Set*` tooltip setter를 다시 연결하지 않는다. `Utils.SafeNumber()`가 정규화하지 못한 secret 값을 원본 그대로 반환하게 바꾸지 않는다.
- M+ Encounter Journal 랜딩은 비전투 중에만 현재 시즌 tier를 먼저 선택하고 availability guard를 통과한 경우 검증된 `JournalInstanceID`로 loot 탭을 연다.
- Encounter Journal 랜딩에서 보호된 `C_EncounterJournal.SetTab`을 직접 호출하지 않는다. 전투 중에는 자동 랜딩을 건너뛰어 Blizzard 보호 기능 차단 팝업을 방지한다.
- locale 누수는 build 단계에서 먼저 막되, 현재 `boss` 필드는 legacy 한국어 값이 남아 있을 수 있어 `UI/BISOverlay.lua`의 런타임 alias 매핑까지 같이 확인해야 한다.
- 검증된 한밤 시즌 1 M+ `JournalInstanceID`:
  - `Magisters' Terrace = 1300`
  - `Maisara Caverns = 1315`
  - `Nexus-Point Xenas = 1316`
  - `Windrunner Spire = 1299`
  - `Algeth'ar Academy = 1201`
  - `Seat of the Triumvirate = 945`
  - `Skyreach = 476`
  - `Pit of Saron = 278`

### 드랍템 레벨 오버레이

- `UI/ItemLevelOverlay.lua` 우측 패널은 `나의 문장` + `나의 열쇠` 2개 섹션이다.
- 현재 `CREST_ID_BY_GRADE`는 다음 값 기준으로 문서/코드를 맞춰둔 상태다.
  - `adv = 3383`
  - `vet = 3341`
  - `chmp = 3343`
  - `hero = 3345`
  - `myth = 3347`
- `DELVE_RESTORED_KEY_CURRENCY_ID = 3028`
- `열쇠 파편`은 여전히 안전한 itemID가 확정되지 않아 `-` fallback이 남아 있을 수 있다.

### 파티찾기 시즌 최고기록 오버레이

- `UI/MythicPlusRecordOverlay.lua`는 이동형 프레임이 아니라 `ChallengesFrame.DungeonIcons` 위에 붙는다.
- 현재 표시 규칙은 `평점 + 던전명`이다.
- 줄바꿈 override 대상:
  - `윈드러너 첨탑`
  - `삼두정의 권좌`
  - `공결탑 제나스`
  - `사론의 구덩이`
  - `마법학자의 정원`
  - `마이사라 동굴`
  - `알게타르 대학`

### BlizzardFrameManager / 지도

- `SetUserPlaced(true)`는 저장 좌표가 있는 UIPanel 프레임에만 적용할 것. 저장 좌표가 없는 기본 창을 초기부터 UserPlaced로 고정하면 은행/캐릭터/특성 창이 중앙에 겹칠 수 있다.
- WorldMapFrame에 `SetUserPlaced(true)`를 남기면 오른쪽 퀘스트 목록 패널이 숨는다. WorldMapFrame은 위치 저장 없이 드래그 전용으로만 유지한다.
- 지도 오버레이는 child/detail map에서 부모 라벨을 억지로 보여주지 않는 현재 기준을 유지하는 편이 안전하다.

## 2. 운영 메모

### profession / quest refresh

- profession/quest refresh는 보호 경로를 거친다.
- `QUEST_TURNED_IN`, `BAG_UPDATE_DELAYED`, `BAG_NEW_ITEMS_UPDATED`, `LOOT_CLOSED` 뒤 follow-up refresh가 들어간다.
- `Modules/ProfessionKnowledgeTracker.lua`는 완료 퀘스트 스냅샷이 실제로 바뀐 경우에만 `questCacheGeneration`과 요약 캐시를 무효화한다.
- `UI/ProfessionKnowledgeOverlay.lua` tooltip 라인은 refresh 때 미리 만들지 않고 hover 시점에만 계산한다.

### 전투메시지 표출 방식

- 현재는 기본 WoW 전투메시지 on/off를 건드리지 않고 `위로 / 아래로 / 부채꼴` 표출 방식과 방향성 분산만 관리한다.
- `_v2` CVar 우선, 없으면 구형 이름 fallback.
- 모드 값은 `1=위로`, `2=아래로`, `3=부채꼴`.

### TomTom waypoint 지역 컨텍스트

- 하란다르와 공허폭풍 일부 보물은 별도 지역 지도라서, 해당 지역에 들어가야 waypoint가 정상 생성된다.
- TomTom 관련 제보가 오면 지역 진입 여부와 map lineage를 먼저 확인한다.

## 3. 미완성 기능

### 스탯 오버레이 쐐기(M+) 우선순위 호환 키

- v1.10.0은 전문화별 단일 대표 우선순위를 사용하므로 M+ 전용 UI와 런타임 분기를 제거했다.
- `DB.lua`의 `mythicPlusMode` 저장 키와 getter/setter는 이전 SavedVariables 호환을 위해 유지한다.
- 콘텐츠별 우선순위를 다시 도입할 경우 검증된 별도 정책 입력과 UI 문구를 함께 설계해야 한다.

### 경매장 현행 확장팩 필터 자동 선택

- 설정 탭 체크박스 UI 숨김 처리 유지
- WoW 보안 시스템 taint 문제로 동작 불가

### 패키지에서 로드 제외한 비활성 기능

- 아래 파일들은 repo에는 남겨 두지만 현재 패키지 TOC에서는 제외한다.
  - `Data/WorldEventSchedule.lua`
  - `Modules/MerchantHelper.lua`
  - `Modules/MailHistory.lua`
  - `UI/WorldEventOverlay.lua`
- 다시 살릴 때는 단순히 파일만 고치는 것이 아니라 `ABProfileManager.toc`, `Core.lua`, `Events.lua`, 관련 DB/Locale 키 사용처를 같이 점검해야 한다.

## 4. 중요한 파일

### 핵심

- `ABProfileManager/Core.lua`
- `ABProfileManager/DB.lua`
- `ABProfileManager/Events.lua`
- `ABProfileManager/Locale.lua`
- `ABProfileManager/Locale_Additions.lua`

### 드랍 / BIS / 시즌 최고기록

- `ABProfileManager/UI/ItemLevelOverlay.lua`
- `ABProfileManager/UI/BISOverlay.lua`
- `ABProfileManager/UI/MythicPlusRecordOverlay.lua`
- `ABProfileManager/Data/ItemLevelTable.lua`
- `ABProfileManager/Data/BISCatalog.lua`
- `ABProfileManager/Data/MidnightS1MPlusDB.lua`
- `ABProfileManager/Data/BISRuntimeScoring.lua`
- `ABProfileManager/Data/StatPriorityTable.lua`
- `ABProfileManager/UI/StatPriorityDialog.lua`
- `ABProfileManager/Data/BISData.lua`
- `ABProfileManager/Data/BISData_Method.lua`
- `ABProfileManager/Data/BISMythicVaultLinks.lua`
- `ABProfileManager/Data/BISEncounterJournal.lua`
- `scripts/build_bis_catalog.py`
- `scripts/build_bis_runtime_scoring.py`
- `scripts/validate_bis_mythic_vault_links.py`
- `scripts/validate_bis_tooltip_contract.py`
- `scripts/validate_bis_encounter_journal.py`
- `scripts/rebuild_bis_database.ps1`
- `scripts/validate_bis_catalog.py`
- `scripts/validate_bis_reward_profiles.py`
- `scripts/refresh_wowhead_bis.py`
- `scripts/refresh_wowhead_mplus_fallbacks.py`
- `DOC/MidnightS1_MPlus_Addon_Master_v1.3.md`
- `DOC/MidnightS1_MPlus_Addon_DB_v1.3.lua`
- `DOC/MidnightS1_MPlus_Addon_Master_v1.7.md`
- `DOC/MidnightS1_MPlus_Addon_DB_v1.7.lua`

### profession / 지도 / 설정

- `ABProfileManager/Modules/ProfessionKnowledgeTracker.lua`
- `ABProfileManager/Modules/TomTomBridge.lua`
- `ABProfileManager/Modules/CombatTextManager.lua`
- `ABProfileManager/UI/ProfessionPanel.lua`
- `ABProfileManager/UI/ProfessionKnowledgeOverlay.lua`
- `ABProfileManager/UI/SilvermoonMapOverlay.lua`
- `ABProfileManager/UI/MapPanel.lua`
- `ABProfileManager/UI/ConfigPanel.lua`
- `ABProfileManager/UI/UtilityPanel.lua`

## 5. 검증 습관

- 먼저 `luaparser` 전체 파싱
- BIS 데이터 재생성이 필요하면 `powershell -ExecutionPolicy Bypass -File .\scripts\rebuild_bis_database.ps1`
- `python .\scripts\validate_bis_mythic_vault_links.py`
- `python .\scripts\validate_bis_tooltip_contract.py`
- `python .\scripts\validate_bis_encounter_journal.py`
- `python .\scripts\validate_bis_catalog.py`
- 그 다음 `git diff --check`
- 릴리스 작업이면 그 다음 패키징
- 로컬 배포는 작업공간 `dist/` ZIP 생성까지만 수행하고 WoW 설치 폴더로 복사하지 않음
- 원격 공개를 명시적으로 요청받은 경우에만 마지막에 푸시와 GitHub release 진행

인게임 회귀 포인트:

- profession 카드 폭과 체크박스 레이아웃
- profession overlay 상세/요약/최소
- 전투메시지 설정 체크박스와 `위로 / 아래로 / 부채꼴` 버튼 선택 상태
- 지도 오버레이가 외부 월드맵에서만 표시되는지
- 비전투 중 BIS 오버레이 드랍 출처 클릭 → 모험 안내서 loot 탭 랜딩
- 전투 중 BIS 오버레이 드랍 출처 클릭 → 자동 랜딩 생략, Blizzard 보호 기능 차단 팝업 없음
- BIS 아이템 hover 후 액션바 / 모험 안내서 / Pawn 아이템 tooltip에서 `MoneyFrame.lua` 오류가 없는지 확인
- BIS tooltip에서 런타임 링크 필요, itemID만으로 Myth 트랙 미확정, 정적 최종 BiS 아님/심크 필요 문구가 보이는지 확인
- BIS 필터 on/off와 visible rank 재계산
- BIS 즐겨찾기/보유 체크, 최상단 즐겨찾기 섹션, 보유 아이템명 취소선, 캐릭터/전문화 전환 후 상태 유지
- BIS 상단 아이템 토글 on/off에 따라 M+ selector preview 자동 생성이 활성화/비활성화되는지 확인
- selector preview 또는 수동 override full link 자체가 위대한 금고 `Myth 1/6 272`로 검증된 경우에만 실제 스탯 / 실제 ilvl 자동 점수화가 적용되는지 확인
- selector preview hyperlink가 첫 조회에서 비어 있어도 비동기 아이템 로드 뒤 snapshot이 채워지는지 확인
- snapshot이 없는 M+ 행 hover에서 preview hyperlink 즉시 해석이 가능한 경우 tooltip이 바로 채워지는지 확인
- 던전 종료 `Hero 3/6 266` 링크만 있으면 272 기준 라벨은 표시되고 점수는 미검증 fallback으로 유지되는지 확인
- 검증된 272 snapshot이 재접속 뒤에도 재사용되는지 확인
- 자동 점수 분산 큐가 rebuild를 과도하게 반복하지 않는지 확인
- `레이드 off + 쐐기만 on`에서 쐐기 행이 유지되는지
- `제작 + 티어만 on`에서 잘못된 랜딩이 없는지
- 드랍템 레벨 오버레이 우측 `나의 문장 / 나의 열쇠` 패널 수치 확인
- 시즌 최고기록 오버레이의 `평점 / 던전명` 위치와 줄바꿈 확인
- 메인 창 `스탯 우선순위 표` 버튼, 현재 전문화 강조 표시, 긴 분기 문구 줄바꿈 확인

## 6. 다음 작업자에게

- UI 퍼블리싱은 이미 사용자가 맞춘 상태를 선호하므로, overflow 보정이나 안전장치 위주로만 접근하는 편이 안전하다.
- BIS 시즌 변경 시에는 `DOC` seed를 출발점으로 삼되, 최종 truth는 외부 검증 결과와 itemID 확인이다.
- 시즌 던전 풀이 바뀌면 현재 시즌 tier preselection과 availability guard를 유지한 채 `JournalInstanceID`를 다시 검증한다.
