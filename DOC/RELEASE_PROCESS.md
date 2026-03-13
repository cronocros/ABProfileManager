# Release Process

## 패키징

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\package_release.ps1
```

생성 결과:

```text
dist\ABProfileManager-v<version>.zip
backups\source\ABProfileManager-source-v<version>-<timestamp>.zip
```

## 기본 검증

```powershell
@'
from luaparser import ast
import pathlib
for path in pathlib.Path("ABProfileManager").rglob("*.lua"):
    ast.parse(path.read_text(encoding="utf-8"))
print("ok")
'@ | python -

git diff --check
```

## 커밋/푸시

```powershell
git add .
git commit -m "Release v<version>"
git push origin main
```

## GitHub 릴리스

```powershell
gh release create v<version> "dist/ABProfileManager-v<version>.zip" --title "v<version>" --notes-file "RELEASE_NOTES_v<version>.md"
```

## 문서 체크

- 루트 `README.md`
- `ABProfileManager/ADDON_INTRO.txt`
- `DOC/ARCHITECTURE.md`
- `DOC/HANDOFF.md`
- `DOC/SECURITY_REVIEW.md`
- `CHANGELOG.md`
- `RELEASE_NOTES_v<version>.md`

## 보관 원칙

- 사용자 안내는 루트 `README.md` 하나를 기준으로 유지
- `ABProfileManager/ADDON_INTRO.txt`는 기술 문서가 아니라 배포 패키지용 소개 자산으로 유지
- 중복 TODO 문서와 플레이스홀더 문서는 장기 유지 대상이 아님
- 최신 릴리스 노트만 루트에 유지
- 이전 릴리스 노트는 `DOC/archive/release-notes/`로 이동
- 바이너리 백업 ZIP은 로컬/릴리스 자산으로 관리하고 git에는 포함하지 않음
