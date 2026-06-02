# ABProfileManager

월드 오브 워크래프트 Retail에서 액션바 복구, 전문기술 포인트 점검, 한밤(Midnight) 지도 길찾기, BIS 추천 장비 카탈로그, 드랍 템렙 표, 파티찾기 시즌 최고기록 확인까지 한 창과 몇 개의 오버레이로 정리하는 애드온입니다.

제작: `밍밍이와코코`
연락처: `crono1232@gmail.com`

## 현재 버전

- 로컬 패치: `v1.11.4`
- 지원 클라이언트: WoW Retail Patch 12.0.5/12.0.7 계열 (`Interface: 120005, 120007`)
- 저장소: `https://github.com/cronocros/ABProfileManager`
- 원격 GitHub 공개 최신 릴리스: `v1.11.0` (`https://github.com/cronocros/ABProfileManager/releases/latest`)
- 원격 GitHub 직접 다운로드: `https://github.com/cronocros/ABProfileManager/releases/download/v1.11.0/ABProfileManager-v1.11.0.zip`
- 로컬 패키지: `dist/ABProfileManager-v1.11.4.zip`
- 이전 로컬 패키지: `dist/archive/`
- 최신 로컬 한글 릴리스 노트: [DOC/releases/RELEASE_NOTES_v1.11.4.md](./DOC/releases/RELEASE_NOTES_v1.11.4.md)
- 최신 로컬 영문 릴리스 노트: [DOC/releases/RELEASE_NOTES_v1.11.4_EN.md](./DOC/releases/RELEASE_NOTES_v1.11.4_EN.md)
- v1.7.7 이후 누적 업데이트 공지: [한글](./DOC/releases/UPDATE_ANNOUNCEMENT_v1.7.7_TO_v1.11.0.md) / [English](./DOC/releases/UPDATE_ANNOUNCEMENT_v1.7.7_TO_v1.11.0_EN.md)
- 에이전트 작업 기준: [AGENTS.md](./AGENTS.md)

## 요약

- 특성 전환이나 캐릭터 변경 뒤 엉킨 액션바를 템플릿으로 복구
- 전문기술 포인트와 1회성 보물을 자동 추적
- 한밤(Midnight) 지도에서 포탈, 시설, 던전, 구렁 위치를 텍스트 오버레이로 확인
- 던전/레이드/M+/제작 드랍 아이템 레벨 표와 우측 `나의 문장 / 나의 열쇠` 패널 제공
- 한밤 시즌 1 기준 전클래스/전특성 `쐐기 / 레이드 / 제작 / 티어` BIS 추천 장비 카탈로그 제공
- 파티찾기 시즌 최고기록 던전 아이콘 위에 `평점 + 던전명` 오버레이 제공
- 한밤 시즌 1 v1.7 기준 40개 전문화 단일 대표 `스탯 우선순위 표` 제공
- 첫 설치 언어는 WoW 클라이언트 기준 적용: 한국어 클라이언트는 한국어, 영어/미지원 클라이언트는 영어
- 영어(enUS) 선택 시 클래스/특성/출처/던전명이 애드온 locale을 따르도록 locale 경로 보강

## v1.11.4 로컬 패치 핵심 정리

- M+ 드랍 출처 클릭 시 현재 시즌 tier를 먼저 선택하고, 사용 가능 여부를 확인한 뒤 검증된 `JournalInstanceID`로 Encounter Journal loot 탭에 랜딩합니다.
- 한밤 시즌 1 던전 ID는 `Magisters' Terrace 1300`, `Maisara Caverns 1315`, `Nexus-Point Xenas 1316`, `Windrunner Spire 1299`, `Algeth'ar Academy 1201`, `Seat of the Triumvirate 945`, `Skyreach 476`, `Pit of Saron 278`입니다.
- selector preview hyperlink가 아직 로드되지 않아 snapshot이 비어 있으면 비동기 아이템 로드 뒤 exact selector 링크를 다시 검증합니다. 실패 callback은 timeout으로 정리하고 링크별 재시도는 세션에서 최대 2회로 제한합니다.
- M+ 행 hover도 저장 snapshot이 없을 때 preview hyperlink의 즉시 해석을 한 번 시도합니다.
- 로컬 패키지는 `dist/ABProfileManager-v1.11.4.zip`이며, 원격 GitHub 공개 최신 릴리스는 계속 `v1.11.0`입니다.

## v1.11.3 로컬 패치 핵심 정리

- 가방에 없는 M+ 후보도 내장된 시즌 selector `12801`로 `Myth 1/6 · 272` preview item string을 자동 생성합니다.
- selector는 Midnight 시즌 1 M+10 금고 그룹의 첫 단계이며, `272`, `Myth 1/6`, 2차 스탯 반환을 오프라인 검증했습니다.
- 생성 preview도 클라이언트가 실제 `272`로 확인한 경우에만 tooltip/stat 스냅샷으로 저장하고 점수화합니다.
- 한 번 저장한 스냅샷은 기존처럼 계정 SavedVariables에서 재사용합니다.
- selector 또는 item string 템플릿이 바뀌면 이전 스냅샷 캐시는 자동 초기화합니다.
- 실제 다른 템렙으로 해석된 preview는 같은 세션에서 반복 재시도하지 않습니다.
- `Data/BISMythicVaultLinks.lua`의 수동 full link는 예외 항목용 override로 유지합니다.

## v1.11.2 로컬 패치 핵심 정리

- BIS 목록 스크롤 중 행 hover tooltip 생성을 잠시 억제해 연속 렌더링 부하를 줄였습니다.
- 상단 아이템 토글을 켜면 검증된 `Myth 1/6 · 272` full link를 한 번 읽고 계정 SavedVariables의 tooltip/stat 스냅샷으로 저장합니다.
- 이후 tooltip과 자동 점수화는 저장된 스냅샷을 사용하므로 매 hover마다 링크나 가방을 다시 스캔하지 않습니다.
- 가방 최고 링크 우선 정렬을 제거했습니다. 보유 체크 시에는 저장용 링크를 한 번만 찾습니다.
- 가방/장비 변경 이벤트가 BIS 전체 rebuild를 일으키지 않게 정리했습니다.
- 정확한 272 full link가 없는 후보는 수치를 추측하지 않고 미검증 안내를 표시합니다.

## v1.11.1 로컬 패치 핵심 정리

- BIS 아이템 tooltip 수동 렌더러가 Blizzard tooltip line color와 품질 색을 보존합니다.
- BIS 오버레이 상단 아이템 토글을 켜면 `Data/BISMythicVaultLinks.lua`에 등록된 M+ 후보의 검증 full link를 자동 점수화합니다.
- 자동 검색 full link 자체가 위대한 금고 `Myth 1/6 272`로 검증된 경우에만 그 링크의 실제 스탯 / 실제 ilvl로 점수화합니다.
- 던전 종료 `Hero 3/6 266` 링크만 있으면 `Myth 1/6 272` 기준 라벨은 표시하지만 점수는 미검증 fallback으로 유지합니다.
- `itemID`만으로 `itemLink`/bonusID를 조립하지 않습니다.
- 실제 장비/가방 링크가 있으면 자동 검색 링크보다 우선합니다.
- hover/자동 큐에서 Encounter Journal UI 상태를 변경하지 않아 `MoneyFrame` secret-number taint 경로를 차단합니다.
- 점수 캐시, 아이템 요청 dedupe, 분산 큐를 사용해 rebuild 스로틀 부담을 줄였습니다.
- `scripts/rebuild_bis_database.ps1`를 추가했습니다. v1.3 카탈로그 입력 → v1.7 scoring 입력 → curated Myth link validate → catalog validate → audit 순서로 실행합니다.
- 검증 링크 DB는 추측값 없이 시작합니다. 실제 `Myth 1/6 272` full link를 확보하면 `Data/BISMythicVaultLinks.lua`만 갱신합니다.

## v1.11.0 핵심 정리

- `DOC/MidnightS1_MPlus_Addon_Master_v1.7.md`와 `DOC/MidnightS1_MPlus_Addon_DB_v1.7.lua`의 컴팩트 런타임 점수 코어를 반영했습니다.
- 정적 후보 풀은 v1.3 기준 총 `3130`행을 그대로 유지합니다: `mythicplus 2554`, `raid 285`, `crafted 91`, `tier 200`.
- 장비 또는 가방에서 실제 `itemLink`를 찾은 후보끼리는 v1.7 코어가 실제 아이템 레벨과 스탯으로 계산한 점수를 슬롯 정렬에 우선 적용합니다.
- 실제 링크가 없는 후보는 기존 정적 순서를 유지하므로 필터, 즐겨찾기, 레이드/제작 보존 동작은 그대로입니다.
- 장비/가방 스캔은 오버레이 rebuild마다 한 번만 수행합니다.
- 40개 전문화 스탯 우선순위 표와 BIS 정책 메타를 v1.7 기준으로 갱신했습니다.

## v1.10.0 핵심 정리

- `DOC/MidnightS1_MPlus_Addon_Master_v1.3.md`와 `DOC/MidnightS1_MPlus_Addon_DB_v1.3.lua`를 BIS 카탈로그 오프라인 생성 입력으로 추가했습니다.
- v1.3 DB는 중간 `return DB`를 제거하고 최종 `return DB` 하나만 EOF에 두도록 정상화했습니다.
- 40개 전문화에 단일 대표 스탯 우선순위를 반영했습니다.
- 스탯 우선순위 표는 애드온 언어가 영어일 때 영문 우선순위 텍스트를 표시합니다.
- BIS 카탈로그는 총 `3130`행을 유지합니다: `mythicplus 2554`, `raid 285`, `crafted 91`, `tier 200`.
- v1.3 런타임 점수 정책은 카탈로그 메타데이터만 생성합니다. 실제 `itemLink` 기반 점수 엔진 연결은 후속 설계 범위입니다.
- v1.9.0의 캐릭터별·전문화별 즐겨찾기/보유 기능은 그대로 유지합니다.

## v1.9.0 핵심 정리

- BIS 행 아이콘 앞에 캐릭터별·전문화별 즐겨찾기/보유 체크박스를 추가했습니다.
- 즐겨찾기 아이템은 `무기` 위 최상단 `즐겨찾기` 섹션으로 이동하고, 보유 아이템명은 취소선으로 표시합니다.
- M+ 아이템 hover 미리보기는 Encounter Journal 신화 던전(M0) Champion 1/6 `246` 기준을 사용합니다.
- `GameTooltip:SetHyperlink()` 금지, source filter, crafted/tier 비랜딩, M+/raid Encounter Journal guard 정책은 유지합니다.

## v1.8.0 핵심 정리

- BIS M+/티어 후보를 새 DOC DB 기준으로 재생성했습니다.
- 레이드/제작 행은 기존 카탈로그에서 보존하고, 런타임 데이터 소스는 계속 `Data/BISCatalog.lua` 하나만 사용합니다.
- M+ 행은 던전 종료 영웅 3/6 266과 위대한 금고·Voidcore 신화 1/6 272 후보를 표시하지만, 정적 `itemLink`/bonusID는 만들지 않습니다.
- BIS 오버레이 헤더와 툴팁에 스탯 우선순위, 런타임 링크 필요 여부, Myth 트랙 미검증, "정적 최종 BiS 아님/심크 필요" 상태를 분리 표시합니다.
- crafted/tier 비랜딩, M+/raid Encounter Journal 랜딩, visible row만 갱신하는 기존 정책을 유지합니다.

## v1.7.6 핵심 정리

- 스탯 오버레이에서 `특화` 행에 마우스를 올렸을 때 현재 전문화의 실제 특화 주문 툴팁을 표시합니다.
- 특화 설명은 Blizzard tooltip data를 ABPM 전용 툴팁에 수동 렌더링해 기존 GameTooltip/MoneyFrame taint 방어 정책을 유지합니다.
- 특화 툴팁 아래의 평점 기여/DR 구간 안내는 기존처럼 유지됩니다.

## v1.7.5 핵심 정리

- Blizzard 기본 창 이동 기능을 보정했습니다.
  - 저장 좌표가 없는 캐릭터/은행/특성 등 UIPanel 창은 Blizzard 기본 배치에 맡깁니다.
  - 전투부대 은행/은행 창은 UIPanel 창으로 명시해 다른 기본 창을 열 때 중앙 겹침이 생기는 상황을 줄였습니다.
  - 이전 버전에서 저장된 Blizzard 창 좌표는 안정화를 위해 한 번 초기화됩니다.
- ABPM 내부 보호 오류 로그를 추가했습니다.
  - 메인 탭 전환, 설정 탭 버튼, 이벤트/모듈 초기화의 보호 오류는 `/abpm log` 또는 `/abpm errors`에서 확인할 수 있습니다.
  - 반복되는 같은 오류는 횟수로 묶어 표시합니다.
- Blizzard PrivateAuras의 반복 assertion 팝업은 좁은 조건에서만 막도록 방어 모듈을 추가했습니다.
- 다른 애드온이나 Blizzard 자체 오류까지 숨기지 않기 위해 전역 `scriptErrors` CVar는 변경하지 않습니다.

## v1.7.4 핵심 정리

- 액션바 / 모험 안내서 / Pawn 비교 툴팁에서 발생할 수 있던 `MoneyFrame.lua secret number` taint 오류를 막았습니다.
  - ABPM 내부 hover 설명은 전용 툴팁 프레임을 사용합니다.
  - BIS 아이템 hover는 `GameTooltip:SetHyperlink()` 대신 `C_TooltipInfo.GetHyperlink()` 텍스트를 수동 렌더링하고 판매가 라인은 건너뜁니다.
- WoW 12.0.7 계열 클라이언트 대응을 위해 TOC Interface를 `120005, 120007`로 갱신했습니다.
- 쐐기 BIS 항목에 던전 종료 / 위대한 금고 보상 트랙과 대표 아이템 레벨 안내를 추가했습니다.
- 메인 창에 **`스탯 우선순위 표`** 버튼을 추가했습니다.
  - Patch 12.0.5 기준 40개 전문화의 1차/2차 스탯 우선순위를 표시합니다.
  - 영웅 특성, 레이드/쐐기, 단일/광역 분기가 있으면 표 안에 그대로 표시합니다.
- 언어 기본값을 WoW 클라이언트 기준으로 바꿨습니다.
  - 한국어 클라이언트는 계속 한국어가 기본입니다.
  - 영어 클라이언트와 현재 미지원 locale은 첫 설치 시 영어로 열립니다.
  - 이전 버전에서 영어 클라이언트에 한국어가 저장된 경우 한 번만 영어로 자동 보정합니다.
- v1.7.3의 스탯 오버레이 전투/인스턴스 안정화와 고스트 일괄 정리 변경은 그대로 포함됩니다.

## v1.7.0 핵심 정리

- BIS 오버레이를 `overall BIS 1개 + runtime fallback` 방식에서 **정적 BIS 카탈로그** 방식으로 전면 교체했습니다.
- `쐐기 / 레이드 / 제작 / 티어` 4개 sourceGroup이 모두 독립 필터로 동작합니다.
- 필터 적용 후 남아 있는 후보를 기준으로 **1순위 / 2순위 / 3순위+**를 다시 번호 매깁니다.
- `레이드 off + 쐐기만 on` 상태에서도 각 부위의 쐐기 드랍 아이템과 인던명이 그대로 남습니다.
- 한글명은 `공식 KR 표기 > Wowhead koKR > DOC companion 검증값` 우선순위로 고정했고, 영어/한글 locale 누수를 빌드 검증 대상으로 넣었습니다.
- BIS 런타임은 `Data/BISCatalog.lua`만 읽고, 웹 조회/병합/정규화를 하지 않습니다.
- spec 수는 기존 39 기준을 정리하고 **40 spec** 전체로 고정했습니다. `포식자 악마사냥꾼(1382)`도 포함됩니다.
- BIS 툴팁은 커서 근처에 열리고, 드랍처/보스/트랙 요약을 WoW 기본 아이템 색상 흐름을 해치지 않는 방식으로 표시합니다.
- BIS / 드랍템 / 전문기술 오버레이 상단 버튼은 hover 설명을 공통 적용했고, 전문기술 오버레이에도 `L / 접기 / 보기 전환` 헤더 조작을 맞췄습니다.
- 드랍템 레벨 오버레이는 locale별 행 라벨(`+2`, `Tier 11`)을 분리하고, 구렁 최고 단계는 현재 시즌 기준 `11단계`까지만 유지합니다.

## 핵심 기능

- 액션바 템플릿 저장, 복제, 비교, 부분 적용, 동기화, 최근 1회 되돌리기
- 전문기술 포인트 자동 추적
  - 주간 퀘스트
  - 전문기술 논문
  - 주간 드랍
  - 평판/풍요 지식서 일부
  - 1회성 보물
- 전문기술 오버레이
  - `상세 / 요약 / 최소` 3단 보기
  - 슬라이더 기반 글자 크기 조절
  - 드래그 이동과 위치 저장
  - 상단 `L / 접기 / 보기 전환` 버튼과 hover 설명
  - 상단 요약은 사용자 문장 중심 안내와 정확한 목요일 오전 8시 리셋 잔여 시간 표시
  - tooltip 범례를 `범례: 완료 | 미완료` 한 줄로 정리
  - TomTom 설치 시 미완료 1회성 보물 waypoint 선택
- 전체 typography
  - 메인 창, tooltip, 스탯 오버레이, 전문기술 오버레이, 지도 오버레이 글자 크기를 1pt 단위 슬라이더로 조절
- 한밤(Midnight) 지도 탭
  - 지도 오버레이 전용 탭 분리
  - 포탈 / 시설 / 전문기술 / 평판상인 / 던전·공격대 / 구렁 필터
  - 실버문 외 영원노래 숲, 하란다르, 보이드스톰 포탈 위치 라벨 확장
- 전투메시지 설정
  - `위로 / 아래로 / 부채꼴` 모드 선택
  - 방향성 분산 on/off
  - 로그인/월드 진입 직후 retry 경로 포함
- 캐릭터 스탯 오버레이
  - `캐릭터 직업 - 특성(아이템레벨)` 헤더
  - 치명/가속/특화/유연과 특성 우선순위 표시
  - 메인 창 `스탯 우선순위 표`에서 40개 전문화 전체 우선순위 확인
  - 탱커 방어스탯(회피/반격/막기) 표시 여부 설정
  - 마우스 휠 스케일 조절과 저장
- 퀘스트 정리
  - 안전 정리 대상
  - 남겨둘 퀘스트
  - 전체 포기 대상
  - 퀘스트 ID 클릭으로 해당 퀘스트 상세 열기
- BIS 추천 장비 오버레이
  - 전클래스/전특성, 한밤 시즌 1 기준 정적 카탈로그 사용
  - 부위별 `1순위 / 2순위 / 3순위+` 강조
  - `쐐기 / 레이드 / 제작 / 티어` 필터
  - 필터 후 살아남은 후보 전체 표시
  - `아이템명 / 드랍 출처 / 트랙·검증 상태 / 우선순위` 중심 렌더
  - 아이콘 앞 즐겨찾기/보유 체크박스와 캐릭터별·전문화별 저장
  - 즐겨찾기 최상단 섹션, 보유 아이템명 취소선 표시
  - 헤더에 현재 전문화 스탯 우선순위와 정적 BiS 검증 상태 표시
  - `mythicplus`, `raid`는 가능할 때 Encounter Journal loot 탭 랜딩
  - `crafted`, `tier`는 랜딩하지 않음
  - 상단 아이템 토글 on 시 내장 selector `12801`로 M+ `Myth 1/6 272` preview 자동 생성
  - 생성 preview 또는 수동 override full link가 실제 `272`로 검증된 경우에만 실제 스탯 / 실제 ilvl 자동 점수화
  - 던전 종료 `Hero 3/6 266` 링크만 있으면 272 기준 라벨만 표시하고 미검증 fallback 유지
  - 임의 bonusID 조립 금지. 검토된 시즌 selector만 `Data/BISMythicVaultLinks.lua`에서 관리
  - 검증 preview는 한 번 스캔해 SavedVariables snapshot으로 저장하고 재사용
  - 스크롤 중 행 hover tooltip 렌더 억제로 끊김 완화
  - 아이템 hover 시 전용 안전 툴팁으로 Base ItemID, 보상 프로필, 런타임 링크 검증 상태 표시
  - 커서 앵커 툴팁, 드랍처/보스 보강, 챔피언/영웅/신화 트랙 색상 요약
  - 마우스 휠 스케일 조절과 위치 저장/복원
- 드랍 아이템 레벨 오버레이
  - 던전 / 레이드 / M+ / 제작 탭별 드랍 템렙 표
  - `단/난이도 | 클리어보상 | 드랍문장 | 위대한 금고` 4열 표
  - 우측 고정 `나의 문장` 패널
  - `나의 열쇠` 패널에서 오늘의 풍요 4개, 열쇠 파편, 복원된 열쇠 확인
  - 구렁 탭 `보물지도 사용` 행과 위치 저장/복원
  - 쐐기 섹션 헤더에 챔피언/영웅/신화 최고 강화 레벨 요약 표시
- 파티찾기 시즌 최고기록 아이콘 오버레이
  - 신화+ 던전 탭의 시즌 최고기록 던전 아이콘 위에 `평점 + 던전명` 표시
  - 긴 한글 던전명은 지정 규칙으로 줄바꿈
  - Utility 탭 체크박스로 on/off

## 설치

`ABProfileManager` 폴더를 아래 경로에 넣으면 됩니다.

```text
World of Warcraft\_retail_\Interface\AddOns\ABProfileManager\
```

확인 파일:

```text
World of Warcraft\_retail_\Interface\AddOns\ABProfileManager\ABProfileManager.toc
```

## 빠른 시작

1. `/abpm` 입력
2. `현재 접속 캐릭터` 탭에서 템플릿 저장
3. `액션바` 탭에서 비교 또는 적용 범위 선택
4. 필요한 경우 동기화 또는 되돌리기 실행
5. `전문기술` 탭과 오버레이로 이번 주 포인트 진행 확인
6. `지도` 탭에서 지도 오버레이와 지도 글자 크기 조정
7. `편의기능` 탭에서 BIS / 드랍템 / 시즌 최고기록 오버레이 on/off
8. `설정` 탭에서 전체 글자 크기와 전투메시지 모드 조정

## 현재 포함된 화면

- `현재 접속 캐릭터`
- `액션바`
- `전문기술`
- `지도`
- `설정`
- `퀘스트`
- `편의기능`

설정은 와우 `설정 > 애드온 > ABProfileManager` 아래에서도 경량 하위 페이지로 접근할 수 있습니다.

## BIS / 드랍 메모

- BIS 정보는 참고용입니다. 실제 템은 게임 내에서 직접 확인하는 전제를 유지합니다.
- 정적 후보 데이터는 `Data/BISCatalog.lua` 하나만 사용합니다.
- 생성 파이프라인은 `DOC/MidnightS1_MPlus_Addon_Master_v1.3.md` + `DOC/MidnightS1_MPlus_Addon_DB_v1.3.lua` + 기존 raid/crafted row + Wago DB2 검증을 거쳐 `koKR/enUS/itemID/sourceGroup/rank`를 고정합니다.
- v1.3 DB는 EOF의 최종 `return DB` 하나만 유지합니다.
- 현재 카탈로그는 총 `3130`행입니다: `mythicplus 2554`, `raid 285`, `crafted 91`, `tier 200`.
- `BISData_Method.lua`, `BISData.lua`는 더 이상 런타임 병합 대상이 아니라 생성용 seed 입력입니다.
- 새 DOC DB는 TOC에 직접 로드하지 않고 `scripts/build_bis_catalog.py --addon-db`의 오프라인 입력으로만 사용합니다.
- v1.7 컴팩트 코어는 `Data/MidnightS1MPlusDB.lua`로 로드하고, `Data/BISRuntimeScoring.lua` 어댑터를 통해 검증 snapshot을 점수화합니다.
- 상단 아이템 토글을 켜면 M+ 후보는 `Data/BISMythicVaultLinks.lua`의 내장 selector `12801`로 `Myth 1/6 272` preview item string을 만들고 계정 SavedVariables snapshot으로 저장합니다.
- 생성 preview 또는 수동 override full link 자체가 위대한 금고 `Myth 1/6 272`로 검증된 경우에만 snapshot의 실제 스탯 / 실제 ilvl로 점수화합니다.
- 던전 종료 `Hero 3/6 266` 링크만 있으면 272 기준 라벨은 표시하지만 점수는 미검증 fallback으로 유지합니다.
- M+ 자동 검색은 임의 bonusID를 조립하지 않습니다. 오프라인으로 검토한 시즌 selector `12801`만 사용합니다.
- 필터 적용 후 남은 후보만 다시 정렬하므로, `레이드 off`, `쐐기만 on`, `제작 + 티어만 on` 모두 실제 후보 목록이 유지됩니다.
- `공결탑 제나스`, `알게타르 대학` 같은 source alias는 생성기에서 canonical name으로 정규화합니다.
- 제작과 티어 항목은 Encounter Journal 랜딩 대상이 아닙니다.
- M+ Encounter Journal 랜딩은 현재 시즌 tier를 먼저 선택하고 사용 가능 여부를 확인한 뒤 검증된 `JournalInstanceID`를 사용합니다: `Magisters' Terrace 1300`, `Maisara Caverns 1315`, `Nexus-Point Xenas 1316`, `Windrunner Spire 1299`, `Algeth'ar Academy 1201`, `Seat of the Triumvirate 945`, `Skyreach 476`, `Pit of Saron 278`.
- BIS 아이템 캐시가 늦게 들어오면 visible row를 우선 갱신하고, selector preview hyperlink가 아직 로드되지 않은 경우 비동기 아이템 로드 뒤 exact selector 링크를 다시 검증합니다. 실패 callback은 timeout으로 정리하고 링크별 재시도는 세션에서 최대 2회로 제한합니다. 저장 snapshot이 없는 M+ 행 hover도 즉시 해석을 한 번 시도합니다. 스크롤 중 tooltip 렌더 억제, 점수 캐시, 아이템 요청 dedupe, 분산 큐로 연속 rebuild 부담을 줄였습니다.
- 즐겨찾기/보유 체크는 캐릭터별·전문화별로 저장됩니다. 즐겨찾기는 `무기` 위 별도 섹션으로 이동하고 보유 아이템명은 취소선으로 표시합니다.
- 쐐기 BIS 항목은 대표 보상 프로필(`던전 종료 영웅 3/6 266`, `위대한 금고/Voidcore 신화 1/6 272`)과 아이템 레벨을 함께 표시합니다.
- M+ 자동 검색 큐는 내장 selector preview를 우선 만들고 `Data/BISMythicVaultLinks.lua`의 수동 full link override를 먼저 적용합니다. 자동 점수는 preview 자체가 위대한 금고 `Myth 1/6 272`로 검증된 경우에만 해당 링크의 실제 스탯 / 실제 ilvl로 계산합니다.
- 정적 카탈로그는 `itemID`만으로 영웅/신화 트랙이나 최종 BiS를 확정하지 않으며, 실제 `itemLink`/bonusID와 심크 검증이 필요하다는 메타를 표시합니다.
- `scripts/build_bis_runtime_scoring.py`는 v1.7 코어를 설치하고 40개 전문화 스탯 표와 BIS 정책 메타를 갱신합니다.
- BIS hover 툴팁은 전역 `GameTooltip:SetHyperlink()`를 직접 호출하지 않고, 안전한 전용 툴팁으로 검증된 tooltipData 텍스트만 렌더링합니다. 수동 렌더러는 Blizzard tooltip line color와 품질 색을 보존합니다.
- hover/자동 큐는 Encounter Journal UI 상태를 바꾸거나 숨은 loot scan을 하지 않습니다. M+/raid 행 클릭은 공개 열기 경로만 사용합니다.
- `scripts/rebuild_bis_database.ps1`는 v1.3 카탈로그 입력 → v1.7 scoring 입력 → Myth preview selector/override validate → catalog validate → audit 순서로 실행합니다.
- M+/tier 추가는 v1.3 파일만 갱신할 수 있고, 점수 정책은 v1.7 파일에서 관리합니다. raid/crafted는 아직 기존 `BISCatalog.lua` 보존 seed이므로 완전 단일 seed 재생성은 후속 범위입니다.
- 시즌 selector 교체 또는 예외 항목용 `Myth 1/6 272` full link override 추가는 `Data/BISMythicVaultLinks.lua`만 갱신하고 `python .\scripts\validate_bis_mythic_vault_links.py`로 확인합니다.
- 갱신 스크립트:
  - `scripts/refresh_wowhead_bis.py`
  - `scripts/refresh_wowhead_mplus_fallbacks.py`
  - `scripts/build_bis_catalog.py --addon-db`
  - `scripts/build_bis_runtime_scoring.py`
  - `scripts/validate_bis_catalog.py`
  - `scripts/rebuild_bis_database.ps1`

## 현재 제약

- 실제 액션바 변경 허용 범위는 `1-132`, `145-180`입니다.
- 바 모델은 현재 `1~9번 바`까지 지원합니다.
- `9번 바`는 비행 중 페이지 전환 바입니다.
- `10~12번` 특수 바는 현재 별도 매핑하지 않습니다.
- 전체 퀘스트 포기는 포기 가능한 퀘스트만 대상으로 합니다.
- 제작 주문, catch-up 같은 일부 profession 예외 획득원은 아직 별도 자동 집계하지 않습니다.
- 전투메시지 설정은 기본 WoW 전투메시지 on/off를 대신하지 않습니다.
- `열쇠 파편`은 Blizzard API에서 안전한 itemID가 확정되지 않아 `-`로 표시될 수 있습니다.

## 문서

- 기본 사용자 안내: 이 문서
- 배포용 소개 텍스트: [ABProfileManager/ADDON_INTRO.txt](./ABProfileManager/ADDON_INTRO.txt)
- 에이전트 작업 지침: [AGENTS.md](./AGENTS.md)
- Claude 호환 안내: [CLAUDE.md](./CLAUDE.md)
- 문서 색인: [DOC/README.md](./DOC/README.md)
- 서브 에이전트 팀: [sub/README.md](./sub/README.md)
- 아키텍처: [DOC/ARCHITECTURE.md](./DOC/ARCHITECTURE.md)
- 인수인계: [DOC/HANDOFF.md](./DOC/HANDOFF.md)
- 보안 검토: [DOC/SECURITY_REVIEW.md](./DOC/SECURITY_REVIEW.md)
- 배포 절차: [DOC/RELEASE_PROCESS.md](./DOC/RELEASE_PROCESS.md)
- 이전 릴리스 노트: [DOC/archive/release-notes/](./DOC/archive/release-notes/)
