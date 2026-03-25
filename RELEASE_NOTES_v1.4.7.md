# ABProfileManager v1.4.7

릴리스 날짜: `2026-03-26`

## 요약

드랍템 레벨정보 오버레이 정식 추가 및 미동작 기능 비활성화 정리.

- 드랍템 레벨정보 오버레이: 파티찾기(PVE) 창 연동, 열 순서·색상 정리
- 월드이벤트 오버레이, 상점 도안 음영처리, 우편 자동완성 비활성화 (백그라운드 완전 중단)
- 편의기능 탭 (BlizzardFrameManager, 유틸리티) 통합
- 디버그 로그 팝업에 ScrollFrame 추가 및 설정 탭 "로그 보기" 버튼 추가

## 상세 변경

### 1. 드랍템 레벨정보 오버레이 (UI/ItemLevelOverlay.lua)

- **파티찾기창(PVEFrame) 전용**: CharacterFrame·KeystoneFrame 의존 제거, PVEFrame 열릴 때만 표시
- **열 순서 변경**: 클리어보상 → 드랍문장 → 위대한금고 순서로 재정렬
- **색상 정리**: 챔피언=파랑(#47ADFF), 영웅=보라(#B85AFF), 신화=빨강(#FF3333)
- **ilvl 숫자 흰색**, 등급명과 단계(1/6 등)는 해당 색상으로 인라인 처리
- 구렁 데이터 및 쐐기 11/12단 클리어보상·위대한금고 수치 추가

### 2. 비활성 기능 완전 차단 (Core.lua, Events.lua)

미동작 확인된 3개 기능을 이벤트 등록·모듈 초기화에서 주석 처리 — 백그라운드 활동 없음:

| 기능 | 비활성 이유 |
|------|-------------|
| WorldEventOverlay (월드이벤트) | Midnight 이벤트 스케줄 미확정, 퀘스트 기반 자동감지 미동작 |
| MerchantHelper (도안 음영) | Midnight `GetItemSpell` spellID 부정확 (483 반환) |
| MailHistory (우편 자동완성) | WoW taint — SendMailNameEditBox 접근 차단 |

코드 파일은 유지하며 주석 해제 시 즉시 재활성화 가능.

### 3. 디버그 로그 팝업 개선 (Commands.lua)

- `UIPanelScrollFrameTemplate` 기반 ScrollFrame으로 긴 로그 스크롤 가능
- "로그 지우기" 버튼 추가
- 설정 탭(ConfigPanel)에 "로그 보기" 버튼 추가 (debugCheck 우측)

### 4. 문서 업데이트

- DOC/HANDOFF.md: 비활성 모듈 섹션 분리, v1.4.7 기준으로 갱신
- DOC/ARCHITECTURE.md: 버전 기준 업데이트
- ADDON_INTRO.txt: 버전 업데이트

## 참고

- 로컬 패키지: `dist/ABProfileManager-v1.4.7.zip`
- 비활성 기능 재개 방법: `Core.lua`와 `Events.lua`의 주석 해제
- 미완성 기능 기록: [DOC/HANDOFF.md](./DOC/HANDOFF.md)
