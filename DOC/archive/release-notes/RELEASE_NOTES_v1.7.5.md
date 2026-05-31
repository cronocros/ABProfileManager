# ABProfileManager v1.7.5

배포일: `2026-05-29`

WoW 기본 창 이동 기능과 오류 표시 완화를 정리한 안정화 릴리스입니다. 전투부대 은행, 캐릭터 창, 특성 창처럼 Blizzard UIPanel 레이아웃에 함께 묶이는 창들이 서로 열릴 때 중앙에 겹쳐지는 문제를 줄이고, ABPM 내부에서 잡을 수 있는 오류는 팝업 대신 세션 로그에 모읍니다.

직접 다운로드: `https://github.com/cronocros/ABProfileManager/releases/download/v1.7.5/ABProfileManager-v1.7.5.zip`
로컬 패키지: `dist/ABProfileManager-v1.7.5.zip`

## 주요 변경

### Blizzard 창 이동 안정화

- **저장 좌표가 없는 UIPanel 창은 Blizzard 기본 배치에 맡김**
  이전에는 이동 기능을 켜는 것만으로 일부 UIPanel 창이 `UserPlaced` 상태가 되어 여러 기본 창이 같은 중앙 좌표에 겹칠 수 있었습니다.
- **전투부대 은행/은행 창을 UIPanel 보호 대상으로 명시**
  은행을 연 상태에서 캐릭터 창이나 다른 기본 창을 열 때 은행 위치가 갑자기 중앙으로 재정렬되는 상황을 줄였습니다.
- **실제 UIPanel 등록 여부를 런타임 감지**
  `UIPanelWindows`에 등록된 Blizzard 창은 수동 목록 누락 여부와 관계없이 같은 안전 규칙을 적용합니다.
- **기존 저장 좌표 1회 초기화**
  이전 버전에서 잘못 저장된 기본 창 좌표가 계속 겹침을 재현하지 않도록 Blizzard 창 이동 좌표 저장소를 `layoutVersion=2`로 전환하면서 한 번 비웁니다.
- **초기화 동작 보정**
  위치 초기화는 UIPanel 창을 강제로 중앙에 두지 않고 `SetUserPlaced(false)` 후 Blizzard의 기본 배치 계산에 돌려보냅니다.

### 오류 표시 완화

- **ABPM 내부 보호 오류 로그 추가**
  `SafeCall`, 모듈 초기화, 주요 이벤트, 설정 탭 버튼 콜백, 메인 탭 전환 콜백에서 잡힌 오류를 세션 로그에 모읍니다.
- **`/abpm log`와 `/abpm errors`로 확인**
  디버그 로그가 꺼져 있어도 보호된 ABPM 오류는 확인할 수 있습니다. 같은 오류가 반복되면 횟수로 묶어 표시합니다.
- **PrivateAuras 반복 assertion 방어 포함**
  Blizzard PrivateAuras의 private dispel/public buff 충돌 assertion은 좁은 조건에서만 막아 오류 팝업 반복을 줄입니다.
- **전역 Lua 오류 숨김은 적용하지 않음**
  다른 애드온이나 Blizzard 자체 오류까지 숨기지 않도록 `scriptErrors` 전역 CVar는 건드리지 않습니다.

## 인게임 확인 권장

- 편의기능 탭에서 Blizzard 창 이동 기능을 켠 뒤 은행/전투부대 은행을 열고 캐릭터 창, 특성 창, 전문기술 창을 차례로 열어 겹침 여부 확인
- 기존 저장 좌표가 초기화된 뒤 필요한 기본 창을 다시 드래그해 저장되는지 확인
- ABPM 메인 창 설정 탭에서 `ABPM 보호 오류` 카운트가 표시되는지 확인
- `/abpm log`와 `/abpm errors`가 디버그 로그와 보호 오류 로그를 함께 보여주는지 확인
- PrivateAuras 관련 Lua 오류 팝업이 반복되던 상황에서 팝업이 줄어드는지 확인

## 이전 버전에서 업그레이드

- 기존 액션바 템플릿, 전문기술 진행, 오버레이 설정은 유지됩니다.
- Blizzard 기본 창 이동 기능의 저장 좌표만 안정화 목적으로 한 번 초기화됩니다.
- 별도 설정 초기화는 필요하지 않습니다.
