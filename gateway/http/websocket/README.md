# WebSocket 연결 테스트 가이드

이 디렉토리(`gateway/http/websocket`)는 로컬 또는 개발 환경에서 Gateway를 통해 WebSocket API(`asset-websocket-api` 등)가 정상적으로 연결되고, JWT 인증을 통과하며 실시간 스트림 데이터를 수신하는지 테스트하기 위한 도구를 제공합니다.

JetBrains IDE(IntelliJ 등)의 내장 `.http` 웹소켓 클라이언트는 실시간 스트림 데이터를 화면에 지속적으로 렌더링하는 데 한계가 있어, CLI 기반의 `wscat` 툴을 사용하도록 구성했습니다.

## 요구 사항
- Node.js (내부적으로 일회용 패키지 실행 도구인 `npx`를 사용합니다)
- 발급받은 JWT Access Token

## 테스트 방법 (Makefile 사용)

터미널을 열고 현재 디렉토리(`gateway/http/websocket`)에서 아래 명령어를 실행하세요. 별도의 토큰 입력 없이 자동으로 임시 계정을 만들고 로그인하여 웹소켓에 연결합니다.

```bash
make test-rate
```

### 실행 과정
1. 백그라운드 스크립트(`connect.sh`)가 랜덤 이메일로 1회성 회원가입을 호출합니다.
2. 가입한 이메일로 로그인(`auth/login`) API를 호출하여 JWT Access Token을 탈취(?)합니다.
3. `npx`를 통해 `wscat` 클라이언트를 실행하며 토큰을 쿼리 파라미터(`?access_token=`)에 심어 연결을 시도합니다.
4. 연결이 성공하면 터미널 화면에 실시간 환율 데이터 스트림이 출력되기 시작합니다.

### 종료 방법
스트림 수신을 종료하고 빠져나오려면 터미널에서 `Ctrl + C`를 누르세요.

---

## 💡 연결 실패 시 체크리스트
- **401 Unauthorized**: 토큰이 만료되었거나 올바르지 않은 토큰입니다. (또는 Gateway의 서명키 불일치)
- **404 Not Found**: 라우팅 설정(`routes.yaml`)에 `/asset-ws/**` 경로가 없거나 백엔드 WebSocket 서버가 켜져 있지 않은 상태입니다.
- **연결 끊김**: 백엔드 서버에서 구독 메시지가 없으면 연결을 스스로 끊도록 구현되어 있을 수 있습니다.
