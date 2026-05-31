# ABProfileManager v1.10.0

배포일: `2026-05-31`

한밤 시즌 1 BIS v1.3 오프라인 입력과 40개 전문화 단일 대표 스탯 우선순위를 반영한 릴리스입니다.

직접 다운로드: `https://github.com/cronocros/ABProfileManager/releases/download/v1.10.0/ABProfileManager-v1.10.0.zip`
로컬 패키지: `dist/ABProfileManager-v1.10.0.zip`

## 주요 변경

- **v1.3 오프라인 생성 입력**
  `DOC/MidnightS1_MPlus_Addon_Master_v1.3.md`와 `DOC/MidnightS1_MPlus_Addon_DB_v1.3.lua`를 BIS 카탈로그 오프라인 생성 입력으로 추가했습니다.
- **DB return 위치 정상화**
  v1.3 DB의 중간 `return DB`를 제거하고 EOF의 최종 `return DB` 하나만 유지합니다.
- **40개 전문화 단일 대표 우선순위**
  전문화별 단일 대표 스탯 우선순위를 스탯 오버레이, 스탯 우선순위 표, BIS 정책 메타에 반영했습니다.
- **영문 스탯 우선순위 표**
  애드온 언어가 영어일 때 스탯 우선순위 표는 영문 우선순위 텍스트를 표시합니다.
- **단일 대표 정책 정리**
  숨겨져 있던 M+ 전용 우선순위 토글의 런타임 분기와 개요 표시를 제거했습니다. 이전 설정 호환 키는 유지합니다.
- **3130 BIS row 유지**
  총 `3130`행을 유지합니다: `mythicplus 2554`, `raid 285`, `crafted 91`, `tier 200`.
- **런타임 점수 정책 범위 분리**
  v1.3 점수 정책은 카탈로그 메타데이터까지만 생성합니다. 실제 `itemLink` 기반 점수 엔진 연결은 후속 설계 범위입니다.
- **v1.9.0 기능 유지**
  캐릭터별·전문화별 즐겨찾기/보유 상태, 최상단 즐겨찾기 섹션, 보유 아이템명 취소선을 유지합니다.
- **체크 표시와 취소선 가독성 개선**
  즐겨찾기/보유 체크 표시는 Blizzard 기본 체크 텍스처를 사용하며, 보유 아이템명 취소선은 전면 레이어에서 표시합니다.
- **한국어 BIS 트랙 표기**
  한국어 UI의 `Hero/Myth` 표기를 `영웅/신화`로 현지화했습니다.

## 인게임 확인 권장

- 스탯 오버레이와 `스탯 우선순위 표`의 40개 전문화 단일 대표 우선순위
- BIS 필터 조합과 visible rank 재계산
- `레이드 off + 쐐기만 on`에서 쐐기 행과 던전명 유지
- 즐겨찾기/보유 상태 저장, 즐겨찾기 섹션 이동, 보유 아이템명 취소선
- M+ 아이템 hover의 M0 Champion 1/6 `246` preview
- crafted/tier 비랜딩과 M+/raid Encounter Journal guard
- BIS hover 뒤 액션바/모험 안내서/Pawn tooltip의 `MoneyFrame.lua` 오류 부재

## 이전 버전에서 업그레이드

- 별도 설정 초기화는 필요하지 않습니다.
- v1.9.0에서 저장한 즐겨찾기/보유 상태는 그대로 사용합니다.
- 실제 링크 기반 점수 엔진은 이번 릴리스에 연결되지 않습니다.
