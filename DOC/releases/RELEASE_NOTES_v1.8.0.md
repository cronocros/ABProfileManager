# ABProfileManager v1.8.0

배포일: `2026-05-31`

BIS 오버레이 데이터와 표기 정책을 새 한밤 시즌 1 M+/티어 DOC DB 기준으로 갱신한 릴리스입니다. 레이드/제작 row는 기존 카탈로그에서 보존하고, 런타임 데이터 소스는 계속 `Data/BISCatalog.lua` 하나만 사용합니다.

직접 다운로드: `https://github.com/cronocros/ABProfileManager/releases/download/v1.8.0/ABProfileManager-v1.8.0.zip`
로컬 패키지: `dist/ABProfileManager-v1.8.0.zip`

## 주요 변경

- **M+/티어 BIS 후보 재생성**
  `DOC/MidnightS1_MPlus_Addon_DB_v1.0.lua`를 오프라인 입력으로 사용해 40개 전문화 M+/티어 후보를 재생성했습니다.
- **레이드/제작 데이터 보존**
  새 DOC DB에 없는 레이드 row와 기존 제작 row는 현재 `Data/BISCatalog.lua`에서 보존했습니다.
- **정적 Myth 링크 추측 금지**
  M+ row는 던전 종료 Hero 3/6 266, 위대한 금고·Voidcore Myth 1/6 272 후보를 표시하지만 정적 `itemLink`, `itemString`, bonusID를 생성하지 않습니다.
- **검증 메타 표시**
  BIS row와 전문화 정책에 런타임 링크 필요, Myth 트랙 미검증, 정적 최종 BiS 아님, 스탯 우선순위 검증 상태를 추가했습니다.
- **BIS 오버레이 정리**
  헤더에는 현재 전문화 스탯 정책을 표시하고, 행에는 출처와 트랙/검증 상태를 더 넓은 compact list로 표시합니다.
- **안전 툴팁 정책 유지**
  `GameTooltip:SetHyperlink()` 직접 호출 없이 검증된 tooltipData만 전용 툴팁에 렌더링하며, 링크가 없으면 Base ItemID와 경고 메타를 표시합니다.

## 검증

- `scripts/build_bis_catalog.py --addon-db`
- `scripts/validate_bis_catalog.py`
- `scripts/audit_bis_data.py`
- 전체 Lua 정적 파싱
- `git diff --check`
- `scripts/package_release.ps1`

## 인게임 확인 권장

- BIS 오버레이 열기/닫기와 전문화 전환
- 모든 source 필터 조합
- `레이드 off + 쐐기만 on`
- 아이템 hover tooltip의 런타임 링크/심크 필요/신화 트랙 미검증 문구
- M+/raid 드랍 출처 클릭 시 Encounter Journal 랜딩
- crafted/tier 클릭 시 비랜딩
- 드루이드 4특성 헤더와 필터 겹침 여부

## 이전 버전에서 업그레이드

- 저장 데이터 변경은 없습니다.
- 별도 설정 초기화는 필요하지 않습니다.
