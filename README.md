# 한국 공휴일 달력 & 나만의 한 줄 메모장

- **배포 링크:** https://a01026451953-afk.github.io/holiday-memo/
- **사용한 API명:** 공공데이터포털 한국천문연구원_특일 정보 (`SpcdeInfoService/getRestDeInfo`)
- **테스트용 계정:** `test@test.com` / `123456`

## 주요 기능
- Firebase Authentication 이메일/비밀번호 로그인·회원가입·로그아웃 및 오류 처리
- 연·월별 한국 공휴일 실시간 JSON 조회
- 로그인한 사용자(`uid`)별 Cloud Firestore 한 줄 메모 저장·조회·삭제

## 실행 화면 캡처
![로그인 화면](screenshot_login.png)
![메인 공휴일 및 메모 화면](screenshot_main.png)
