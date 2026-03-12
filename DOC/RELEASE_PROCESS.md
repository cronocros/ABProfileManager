# Release Process

버전 기준: `v1.3.11`

## 패키징

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\package_release.ps1
```

생성 결과:

```text
dist\ABProfileManager-v1.3.11.zip
backups\source\ABProfileManager-source-v1.3.11-<timestamp>.zip
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
git commit -m "Release v1.3.11"
git push origin main
```

## GitHub 릴리스

```powershell
gh release create v1.3.11 "dist/ABProfileManager-v1.3.11.zip" --title "v1.3.11" --notes-file "RELEASE_NOTES_v1.3.11.md"
```

## 문서 체크

- 루트 `README.md`
- `ABProfileManager/README_USER.md`
- `ABProfileManager/ADDON_INTRO.txt`
- `DOC/ARCHITECTURE.md`
- `DOC/HANDOFF.md`
- `DOC/SECURITY_REVIEW.md`
- `CHANGELOG.md`
- `RELEASE_NOTES_v1.3.11.md`

## 보관 원칙

- 최신 릴리스 노트만 루트에 유지
- 이전 릴리스 노트는 `DOC/archive/release-notes/`로 이동
- 바이너리 백업 ZIP은 로컬/릴리스 자산으로 관리하고 git에는 포함하지 않음
