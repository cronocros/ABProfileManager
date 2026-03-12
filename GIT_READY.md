# Git Upload Ready

현재 폴더는 `v1.3.3` 배포 기준으로 깃 업로드와 릴리스 생성이 가능한 상태를 설명하는 문서입니다.

## 현재 준비 상태

- 로컬 git 저장소 초기화
- `.gitignore` 적용
- 배포용 ZIP 생성 스크립트 준비
- 릴리스 ZIP 생성 위치: `dist/`
- 소스 백업 ZIP 생성 위치: `backups/source/`

## 기본 배포 순서

```powershell
git add .
git commit -m "Release v1.3.3"
git push origin main
gh release create v1.3.3 "dist/ABProfileManager-v1.3.3.zip" --title "v1.3.3" --notes-file "RELEASE_NOTES_v1.3.3.md"
```

## 배포 ZIP 다시 만들기

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\package_release.ps1
```

생성 결과:

```text
dist\ABProfileManager-v1.3.3.zip
backups\source\ABProfileManager-source-v1.3.3-<timestamp>.zip
```
