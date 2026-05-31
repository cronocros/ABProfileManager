# ABProfileManager v1.7.6

배포일: `2026-05-29`

스탯 오버레이 특화 툴팁을 보정한 핫픽스입니다. 특화 행에 마우스를 올렸을 때 더 이상 고정된 짧은 설명만 표시하지 않고, 현재 전문화의 실제 특화 주문 툴팁 설명을 표시합니다.

직접 다운로드: `https://github.com/cronocros/ABProfileManager/releases/download/v1.7.6/ABProfileManager-v1.7.6.zip`
로컬 패키지: `dist/ABProfileManager-v1.7.6.zip`

## 주요 변경

- **스탯 오버레이 특화 툴팁을 전문화별 설명으로 변경**
  현재 전문화의 특화 주문 ID를 조회한 뒤 Blizzard tooltip data를 ABPM 전용 툴팁에 렌더링합니다.
- **전역 GameTooltip 사용 없이 표시**
  기존 MoneyFrame taint 방어 정책을 유지하기 위해 `ABProfileManagerTooltip`에 텍스트 라인을 수동 렌더링합니다.
- **기존 DR 구간 안내 유지**
  특화 설명 아래에 평점 기여/DR 구간 안내는 기존처럼 함께 표시됩니다.

## 인게임 확인 권장

- 스탯 오버레이를 켠 뒤 `특화` 행에 마우스오버
- 여러 전문화로 전환 후 각 전문화의 특화 이름과 설명이 바뀌는지 확인
- 치명/가속/유연/방어스탯 툴팁과 DR 구간 안내가 기존처럼 표시되는지 확인

## 이전 버전에서 업그레이드

- 저장 데이터 변경은 없습니다.
- 별도 설정 초기화는 필요하지 않습니다.
