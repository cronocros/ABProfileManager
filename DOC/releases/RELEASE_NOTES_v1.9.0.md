# ABProfileManager v1.9.0

배포일: `2026-05-31`

BIS 오버레이에 캐릭터별·전문화별 즐겨찾기/보유 상태와 M+ M0 툴팁 미리보기를 추가한 릴리스입니다.

직접 다운로드: `https://github.com/cronocros/ABProfileManager/releases/download/v1.9.0/ABProfileManager-v1.9.0.zip`
로컬 패키지: `dist/ABProfileManager-v1.9.0.zip`

## 주요 변경

- **즐겨찾기/보유 체크**
  BIS 행 아이콘 앞 체크박스로 상태를 지정하며 캐릭터별·전문화별로 저장합니다.
- **즐겨찾기 섹션**
  즐겨찾기 아이템은 `무기` 위 최상단 `즐겨찾기` 섹션으로 이동합니다.
- **보유 표시**
  보유 아이템명은 취소선으로 표시합니다.
- **M+ M0 툴팁 미리보기**
  M+ 아이템 hover preview는 Encounter Journal 신화 던전(M0) Champion 1/6 `246` 기준을 사용합니다.
- **기존 안전 정책 유지**
  `GameTooltip:SetHyperlink()` 직접 호출 금지, source filter, crafted/tier 비랜딩, M+/raid Encounter Journal guard를 유지합니다.

## 인게임 확인 권장

- 캐릭터/전문화 전환 후 즐겨찾기·보유 상태 유지
- 즐겨찾기 섹션 이동과 보유 아이템명 취소선
- M+ 아이템 hover의 M0 Champion 1/6 `246` preview
- 모든 source filter 조합과 crafted/tier 비랜딩
- BIS hover 뒤 액션바/모험 안내서/Pawn tooltip의 `MoneyFrame.lua` 오류 부재

## 이전 버전에서 업그레이드

- BIS 즐겨찾기/보유 상태용 SavedVariables가 필요할 때 자동 추가됩니다.
- 별도 설정 초기화는 필요하지 않습니다.
