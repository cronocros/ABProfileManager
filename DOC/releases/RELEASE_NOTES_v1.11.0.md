# ABProfileManager v1.11.0

배포일: `2026-06-01`

한밤 시즌 1 v1.7 컴팩트 런타임 점수 코어를 BIS 오버레이에 연결한 릴리스입니다.

직접 다운로드: `https://github.com/cronocros/ABProfileManager/releases/download/v1.11.0/ABProfileManager-v1.11.0.zip`
로컬 패키지: `dist/ABProfileManager-v1.11.0.zip`

## 주요 변경

- **v1.7 런타임 점수 코어 연결**
  `DOC/MidnightS1_MPlus_Addon_DB_v1.7.lua`를 런타임 코어로 설치하고 ABPM 어댑터를 추가했습니다.
- **실제 itemLink 기반 정렬**
  장비 또는 가방에서 실제 링크를 찾은 후보끼리는 실제 아이템 레벨과 스탯으로 계산한 v1.7 점수를 슬롯 정렬에 우선 적용합니다.
- **정적 fallback 유지**
  실제 링크가 없는 후보는 기존 정적 순서를 유지합니다. 필터, 즐겨찾기, 보유 체크, 레이드/제작 보존 동작은 바뀌지 않습니다.
- **3130 BIS row 유지**
  정적 후보 풀은 `mythicplus 2554`, `raid 285`, `crafted 91`, `tier 200`을 유지합니다.
- **스캔 비용 제한**
  장비/가방 링크 인덱스는 오버레이 rebuild마다 한 번만 생성합니다.
- **40개 전문화 우선순위 갱신**
  스탯 오버레이, 스탯 우선순위 표, BIS 정책 메타를 v1.7 기준으로 갱신했습니다.
- **생성/검증 분리**
  `scripts/build_bis_runtime_scoring.py`를 추가하고, 검증기가 v1.3 정적 풀과 v1.7 런타임 코어를 각각 검사하도록 보강했습니다.

## 인게임 확인 권장

- BIS 오버레이 열기, 전문화 전환, 모든 source filter 조합
- `레이드 off + 쐐기만 on` 상태의 쐐기 행과 던전명 유지
- 즐겨찾기/보유 상태 영속성, 즐겨찾기 섹션, 보유 아이템명 취소선
- 실제 보유 아이템이 있는 슬롯의 정렬과 hover 툴팁
- crafted/tier 비랜딩과 M+/raid Encounter Journal guard
- 스탯 우선순위 표의 40개 전문화 표시

## 업그레이드

- 설정 초기화는 필요하지 않습니다.
- v1.9.0 이후 저장한 즐겨찾기/보유 상태는 그대로 사용합니다.
- 정적 후보 풀은 유지되며 실제 링크가 있을 때만 런타임 점수가 추가 적용됩니다.
