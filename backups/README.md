# Source Backups

이 폴더는 로컬 배포 시 생성되는 소스 백업의 기준 디렉토리입니다.

- 실제 백업 ZIP은 `backups/source/` 아래에 생성됩니다.
- `backups/source/`는 git에서 제외됩니다.
- 생성 명령:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\package_release.ps1
```
