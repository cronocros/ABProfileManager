# Git Upload Ready

현재 폴더는 깃 업로드 준비가 끝난 상태를 기준으로 정리한 문서입니다.

## 현재 준비 상태

- 로컬 git 저장소 초기화
- `.gitignore` 적용
- 배포용 ZIP 생성 스크립트 추가
- 릴리스 ZIP 생성 위치: `dist/`

## 원격 저장소를 만든 뒤 할 일

리포 URL이 준비되면 아래 순서로 진행하면 됩니다.

```powershell
git remote add origin <REPO_URL>
git add .
git commit -m "Release v1.0.2"
git push -u origin main
```

## 배포 ZIP 다시 만들기

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\package_release.ps1
```

생성 결과:

```text
dist\ABProfileManager-v1.0.2.zip
```
