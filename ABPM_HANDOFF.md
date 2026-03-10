# ABPM Handoff

## 현재 상태

프로젝트는 직접 적용 가능한 WoW Retail 애드온 구조를 갖추고 있다.  
현재 기준 버전은 `v1.0.6`이며, 핵심 기능 구현과 인게임 동작 확인이 끝난 상태다.
1차 출시와 GitHub 업로드까지 완료된 상태다.

## 이미 구현된 핵심 기능

- 템플릿 저장 / 복제 / 적용 / 삭제
- 최근 1회 작업 되돌리기
- 문자열 내보내기 / 가져오기
- 전체/부분 적용
- 전체/부분 비우기
- 비교 / 동기화
- 비행 바 `9번 바` 처리
- 전투 중 대기열
- 현재 특성 전환
- 퀘스트 정리 / 전체 퀘스트 포기
- 미니맵 버튼
- 캐릭터 스탯 오버레이
- 설정 탭
- 와우 `설정 > AddOns` 연동 시도

## 최근 반영 사항

- 스탯 오버레이는 평점 컬럼과 퍼센트 괄호 열을 고정 폭으로 잡아 한 자리수/두 자리수 퍼센트도 소수점 위치가 어긋나지 않도록 보정
- 스탯 퍼센트는 항상 소수 둘째 자리까지 표시
- 스탯 값 영역 툴팁은 Blizzard 캐릭터 스탯 setter를 우선 재사용해 특화 등 스펙별 설명을 최대한 원문에 가깝게 표시
- 템플릿 작업 영역을 `왼쪽 정보 / 오른쪽 버튼 세로 배치`로 변경
- `전체 액션바 비우기` 버튼 추가
- 템플릿 목록 이동 버튼은 현재 선택 기준으로 이전 / 다음 템플릿을 고른다.
- 템플릿 복제 기능 추가
- 최근 1회 되돌리기 기능 추가
- 상태 메시지를 `● 성공`, `◆ 실패`, `● 안내` 포맷으로 통일
- 현재 캐릭터 정보에 직업/특성 아이콘 추가
- 현재 특성 버튼에 `▶` 식별 표시 추가
- 동기화 버튼 높이와 문구 정리
- `적용 가능한 칸만 맞추기` 동기화 버튼 추가
- 고스트 슬롯은 드래그 해제 / 다른 액션으로 덮어쓰기 가능하게 보강
- 수동으로 바꾼 고스트 슬롯은 자동 재시도로 다시 살아나지 않도록 정리
- 메인 타이틀과 설정 영역에 버전 표시 추가
- 템플릿 삭제 버튼을 저장/복제/새로고침 상단 행으로 이동
- 템플릿 정보에 특성명, 기록된 액션 수, 주문/매크로/아이템 통계 추가
- 전체 액션바 비우기는 2차 검증 패스로 남은 칸을 다시 비우도록 보강
- 미니맵 버튼을 더 작은 사각 `AB` 버튼형으로 원복
- 같은 이름 템플릿 저장 시 덮어쓰기 확인창 추가
- 제작자명 표기를 `밍밍이와코코`로 통일
- 비교 결과 미리보기 제한을 제거하고 전체 스크롤 표시로 변경
- 상태 메시지 중복 포맷 경로 정리
- 동기화 버튼은 현재 선택 범위 기준으로 설명이 가변 생성됨
- hover 시 툴팁, 클릭 시 하단 요약 설명을 표시
- 퀘스트 탭 추가
  - 후보 새로고침
  - 안전 정리 실행
  - 전체 퀘스트 포기
  - 숨김/작업/현상금 계열 항목은 후보에서 제외
- 문자열 import 길이/줄 수/중복 슬롯/액션 종류 검증 추가
- 템플릿 이름 단일행 정화 추가
- 전체 퀘스트 포기는 항상 확인 모달을 거치도록 보강
- 치명 / 가속 / 특화 / 유연 텍스트 오버레이 추가
- 스탯 오버레이는 투명 배경 + 드래그 이동 + 위치 저장을 지원
- 스탯 오버레이 마지막 줄에 현재 특성의 PvE 일반 스탯 우선순위 표시 추가
- 우선순위 표는 `Midnight 12.0.1` 기준 일반 PvE 가이드 기준으로 단순화해 내장
- 유연 퍼센트는 총 유연 보너스 기준으로 계산하도록 보정
- 오버레이는 라벨/값 2열 구조로 리팩토링해 가독성 개선
- 탱커 특성은 회피 / 무막 / 막기 방어 확률을 추가 표시
- 스탯 표기는 `평점(퍼센트)` 형식으로 압축하고 줄/열 간격을 더 좁게 조정
- 2차 스탯은 rating 기준 `30 / 39 / 47 / 54 / 66%` DR 구간에 따라 퍼센트 숫자만 단계적으로 색상 변경
- 특성 우선순위 줄은 민트 계열 색상으로 표시
- 스탯 값 영역에 마우스 오버 툴팁과 DR 구간 안내 추가
- 설정 탭에 스탯 오버레이 표시 체크박스 추가

## 현재 잔여 메모

1. 하단 요약창 오른쪽 끝 정렬
- 사용자 요청으로 후순위 보류

2. 정적 문법 검사
- 이 작업 환경에는 `lua`/`luac`가 없어 자동 검사를 돌리지 못함

3. 이후 작업 성격
- 현재는 신규 기능보다 유지보수/마감/버그 수정 단계

4. 바 모델 메모
- 현재 적용/선택 바 모델은 `1~9번 바`까지만 사용한다.
- `9번 바`는 비행 중 페이지 전환 바다.
- `10~12번` 특수 바는 현재 별도 매핑하지 않는다.

## 릴리스 자산

- 저장소: `https://github.com/cronocros/ABProfileManager`
- 배포 ZIP: `dist/ABProfileManager-v1.0.6.zip`
- 릴리스 노트: `RELEASE_NOTES_v1.0.6.md`
- 소스 백업 ZIP: `backups/source/ABProfileManager-source-v1.0.6-<timestamp>.zip`
- 변경 이력: `CHANGELOG.md`

## 중요한 파일

- 부트스트랩
  - `ABProfileManager/Core.lua`
  - `ABProfileManager/DB.lua`
  - `ABProfileManager/Events.lua`
  - `ABProfileManager/Commands.lua`

- UI
  - `ABProfileManager/UI/MainWindow.lua`
  - `ABProfileManager/UI/ProfilePanel.lua`
  - `ABProfileManager/UI/ActionBarPanel.lua`
- `ABProfileManager/UI/ConfigPanel.lua`
- `ABProfileManager/UI/QuestPanel.lua`
- `ABProfileManager/UI/TransferDialog.lua`
  - `ABProfileManager/UI/MinimapButton.lua`
- `ABProfileManager/UI/StatsOverlay.lua`
- `ABProfileManager/Data/StatPriorities.lua`
- `ABProfileManager/UI/Widgets.lua`
- `ABProfileManager/README_USER.md`
- `ABProfileManager/ADDON_INTRO.txt`

- 로직
- `ABProfileManager/Modules/ProfileManager.lua`
- `ABProfileManager/Modules/UndoManager.lua`
- `ABProfileManager/Modules/ActionBarScanner.lua`
  - `ABProfileManager/Modules/ActionBarApplier.lua`
  - `ABProfileManager/Modules/RangeCopyManager.lua`
  - `ABProfileManager/Modules/SlotMapper.lua`
  - `ABProfileManager/Modules/TemplateSyncManager.lua`
  - `ABProfileManager/Modules/TemplateTransfer.lua`
  - `ABProfileManager/Modules/GhostManager.lua`
  - `ABProfileManager/Modules/QuestManager.lua`

## 다음 LLM용 작업 방식

1. 먼저 인게임에서 깨지는 실제 UI를 기준으로 수정한다.
2. 겹침 문제는 개별 박스보다 `MainWindow`의 높이와 `content`/`statusBox` 기준부터 본다.
3. 액션바 관련 수정은 `RangeCopyManager`, `SlotMapper`, `ActionBarPanel` 세 파일을 같이 본다.
4. 템플릿 관련 수정은 `ProfilePanel`과 `ProfileManager`를 같이 본다.
5. 상태 메시지 포맷은 `Utils.FormatStatusMessage()`를 기준으로 유지한다.
6. import 관련 작업은 `Modules/TemplateTransfer.lua`의 입력 제한을 먼저 확인한다.
7. 스탯 오버레이 관련 수정은 `UI/StatsOverlay.lua`, `UI/ConfigPanel.lua`, `DB.lua`, `Events.lua`를 같이 본다.
8. 유연 수치 문제를 볼 때는 `GetCombatRatingBonus + GetVersatilityBonus` 합산 경로를 먼저 확인한다.
9. DR 색상 문제를 볼 때는 표시 퍼센트가 아니라 `GetCombatRatingBonus()` 기준값으로 판단한다.
10. 버전 표시는 `GetAddOnMetadata(..., "Version")` 경로를 기준으로 유지한다.
11. 스탯 툴팁 문제를 볼 때는 `UI/StatsOverlay.lua`의 `PaperDollFrame_Set*` 재사용 경로를 먼저 확인한다.

## 다음 LLM에게 바로 줄 수 있는 요약 프롬프트

```text
프로젝트는 WoW Retail 애드온 ABProfileManager다.
현재 구현 범위는 액션바 템플릿 저장/적용/비교/동기화/문자열 import-export/특성 전환/비행 바 지원/전투 중 대기열/퀘스트 정리까지 포함한다.

현재 코드 기준 문서는 README.md, ABPM_FINAL_DESIGN.md, ABPM_HANDOFF.md 이다.
최신 기준 문서를 우선하라.

현재는 출시 완료 상태이며, 남은 작업은 유지보수와 선택적 개선이다.
보안 설계 기준은 SECURITY_REVIEW.md를 우선 참고하라.
특히 봐야 할 파일:
- UI/MainWindow.lua
- UI/ProfilePanel.lua
- UI/ActionBarPanel.lua
- UI/MinimapButton.lua
- UI/Widgets.lua

현재 사용자가 중점적으로 보는 문제는:
- 하단 요약창 폭/정렬
- 액션바 범위 요약 overflow
- 미니맵 버튼은 현재 해결된 상태
- 전체 창 세로 높이와 패널 간 간격
- 최근 1회 되돌리기 동작 검증

수정 시 한국어 기본 UI를 유지하고, 톤앤매너는 어두운 청색 바탕 + 금색 포인트 + 섹션 제목 앞 ● 기호를 유지하라.
```
