# ABProfileManager v1.7.2

WoW Patch 12.0.5 — Secret Number 호환성 핫픽스.

직접 다운로드: `https://github.com/cronocros/ABProfileManager/releases/download/v1.7.2/ABProfileManager-v1.7.2.zip`
로컬 패키지: `dist/ABProfileManager-v1.7.2.zip`

## 변경 내용

### 버그 수정

- **StatsOverlay: PaperDoll setter taint 크래시 수정**
  `PreparePaperDollTooltip`에서 Blizzard의 `PaperDollFrame_Set*` setter 호출을 `pcall`로 감쌌습니다. WoW 12.0.5+에서 addon 실행 컨텍스트에서 이 함수들을 직접 호출하면 `"attempt to perform arithmetic on a secret number value (execution tainted by 'ABProfileManager')"` 에러가 발생합니다. 실패 시 자체 커스텀 툴팁으로 fallback하므로 스탯 행 기능은 정상 유지됩니다.

- **StatsOverlay: Secret number 안전 변환 처리**
  `safeNumber()`가 기존 `tonumber(value)` 대신 `tonumber(tostring(value))` 패턴을 사용합니다. `tostring` 단계가 WoW 12.0.5+의 secret number 플래그를 제거하여 API 반환값으로 인한 산술/비교 연산에서 taint 전파를 방지합니다.

## 기술 세부 사항

WoW Patch 12.0.5 (Midnight)는 "secret number" 보안 메커니즘을 도입했습니다. 특정 API 반환값에 내부 플래그가 붙어 addon-tainted 실행 컨텍스트에서 테이블 키 또는 산술 피연산자로 직접 사용할 수 없게 됩니다. 두 수정 모두 이 엔진 변경에 대한 방어적 대응입니다.

## 이전 버전에서 업그레이드

- 기존 저장 데이터(`ABPM_DB`) 그대로 유지됩니다.
- 별도 설정 재조정이 필요하지 않습니다.
