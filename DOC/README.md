# DOC Index

이 폴더는 `ABProfileManager`의 기술 문서와 운영 문서를 유지합니다.

사용자 안내는 루트 [README.md](../README.md)를 기준으로 봅니다.

## 유지 문서

- [../README.md](../README.md)
  - 기본 사용자 안내와 기능 요약
- [../AGENTS.md](../AGENTS.md)
  - 작업자/에이전트용 저장소 운영 지침
- [releases/RELEASE_NOTES_v1.11.10.md](./releases/RELEASE_NOTES_v1.11.10.md)
  - 최신 로컬 한글 릴리스 노트 (v1.11.10)
- [releases/RELEASE_NOTES_v1.11.10_EN.md](./releases/RELEASE_NOTES_v1.11.10_EN.md)
  - 최신 로컬 영문 릴리스 노트 (v1.11.10)
- [releases/RELEASE_NOTES_v1.11.0.md](./releases/RELEASE_NOTES_v1.11.0.md)
  - 원격 GitHub 공개 최신 한글 릴리스 노트 (v1.11.0)
- [releases/RELEASE_NOTES_v1.11.0_EN.md](./releases/RELEASE_NOTES_v1.11.0_EN.md)
  - 원격 GitHub 공개 최신 영문 릴리스 노트 (v1.11.0)
- [releases/UPDATE_ANNOUNCEMENT_v1.7.7_TO_v1.11.0.md](./releases/UPDATE_ANNOUNCEMENT_v1.7.7_TO_v1.11.0.md)
  - v1.7.7 이후 누적 변경 한글 공지
- [releases/UPDATE_ANNOUNCEMENT_v1.7.7_TO_v1.11.0_EN.md](./releases/UPDATE_ANNOUNCEMENT_v1.7.7_TO_v1.11.0_EN.md)
  - v1.7.7 이후 누적 변경 영문 공지
- [releases/UPDATE_ANNOUNCEMENT_v1.10.0_TO_v1.11.10_EN.md](./releases/UPDATE_ANNOUNCEMENT_v1.10.0_TO_v1.11.10_EN.md)
  - v1.10.0 이후 누적 변경 영문 공지
- [releases/ADDON_DESCRIPTION_v1.11.10_EN.md](./releases/ADDON_DESCRIPTION_v1.11.10_EN.md)
  - 최신 외부 소개 페이지용 영문 문안
- [ARCHITECTURE.md](./ARCHITECTURE.md)
  - 현재 구조, 모듈 책임, 데이터 흐름
- [HANDOFF.md](./HANDOFF.md)
  - 다음 작업자를 위한 운영 메모, 회귀 포인트, 미완성 기능 기록
- [SECURITY_REVIEW.md](./SECURITY_REVIEW.md)
  - 입력 경로, 파괴적 작업, CVar/외부 의존성 검토
- [RELEASE_PROCESS.md](./RELEASE_PROCESS.md)
  - 패키징, 커밋, 푸시, GitHub 릴리스 절차
- [releases](./releases)
  - 현재 활성 릴리스 노트
- [archive/legacy-docs](./archive/legacy-docs)
  - 종료된 핸드오프, 구형 도구 호환 문서, 과거 작업 메모

참고:

- BIS 데이터 seed 갱신 스크립트:
  - `../scripts/refresh_wowhead_bis.py`
  - `../scripts/refresh_wowhead_mplus_fallbacks.py`
- BIS 통합 카탈로그 생성 스크립트:
  - `../scripts/build_bis_catalog.py --addon-db`
  - `../scripts/build_bis_runtime_scoring.py`
  - `../scripts/validate_bis_mythic_vault_links.py`
  - `../scripts/validate_bis_season_preview_links.py`
  - `../scripts/validate_bis_tooltip_contract.py`
  - `../scripts/validate_bis_encounter_journal.py`
  - `../scripts/validate_bis_catalog.py`
  - `../scripts/rebuild_bis_database.ps1`
- BIS v1.3 오프라인 생성 입력:
  - `MidnightS1_MPlus_Addon_Master_v1.3.md`
  - `MidnightS1_MPlus_Addon_DB_v1.3.lua`
- BIS v1.7 런타임 점수 입력:
  - `MidnightS1_MPlus_Addon_Master_v1.7.md`
  - `MidnightS1_MPlus_Addon_DB_v1.7.lua`

`../scripts/rebuild_bis_database.ps1`는 v1.3 카탈로그 입력 → v1.7 scoring 입력 → Myth preview selector/override validate → non-M+ season preview validate → tooltip contract validate → Encounter Journal validate → catalog validate → audit 순서로 실행합니다. M+/tier 추가는 v1.3 파일만 갱신할 수 있고 점수 정책은 v1.7 파일에서 관리합니다. 시즌 selector 교체 또는 예외 항목용 Myth 1/6 272 full link override 추가는 `../ABProfileManager/Data/BISMythicVaultLinks.lua`만 갱신합니다. raid/tier/crafted 시즌 preview selector 또는 예외 override는 `../ABProfileManager/Data/BISSeasonPreviewLinks.lua`만 갱신합니다. raid/crafted는 아직 기존 `BISCatalog.lua` 보존 seed이므로 완전 단일 seed 재생성은 후속 범위입니다.

현재 로컬 배포는 작업공간 `../dist/` ZIP 생성까지만 수행합니다. WoW 설치 폴더로 애드온을 복사하지 않습니다.

## 보관 문서

- [archive/release-notes](./archive/release-notes)
  - 이전 버전 릴리스 노트
