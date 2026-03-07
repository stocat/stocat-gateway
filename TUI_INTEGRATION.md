# TUI Integration Guide (Makefile 기반)

이 문서는 `Makefile`을 백엔드 엔진으로 활용하여 TUI(Terminal User Interface) 관리 도구를 개발할 때 필요한 설계 가이드라인을 제공합니다.

## 🏗️ 아키텍처 원칙
1. **Makefile = 엔진**: TUI는 직접적인 로직(명령어 조합)을 갖지 않고 오직 `make` 타겟만 호출해야 합니다.
2. **비동기 실행**: 스프링 부트 애플리케이션(`make gateway` 등)은 블로킹 작업이므로 TUI에서 별도 고루틴이나 프로세스로 실행하고 로그를 스트리밍해야 합니다.
3. **멱등성**: 인프라 기동(`make infra-up`)은 이미 떠 있는 상태에서 중복 호출해도 안전해야 합니다.

## 📋 TUI 메뉴 구성 추천

### 1단계: 메인 선택 메뉴
사용자에게 3가지 주요 모드를 제안합니다.
- **[A] All-in-One**: `make all` 호출 (인프라 -> 설정 -> 게이트웨이 순차 실행)
- **[I] Infra Only**: `make infra-up infra-wait config-all` 호출 (인프라만 준비)
- **[S] Selective Run**: 하위 메뉴로 이동

### 2단계: 서비스별 선택 메뉴
개별 서비스를 켜고 끌 수 있는 체크박스/리스트 메뉴입니다.
- **Gateway**: `make gateway`
- **Catalog Service**: `make app-catalog`
- **Order Service**: `make app-order`

---

## 🛠️ TUI에서 Makefile 호출 시 팁

### 로그 캡처 및 표시
TUI 윈도우 한쪽에 `make` 명령의 표준 출력(stdout/stderr)을 실시간으로 띄워주면 사용자 경험이 매우 좋아집니다. 파이프(`|`)를 통해 로그를 읽어올 때 컬러 코드(ANSI)를 지원하는 터미널 라이브러리를 사용하세요.

### 상태 모니터링
TUI의 배경 루프에서 주기적으로 다음 타겟을 호출하여 상태를 업데이트할 수 있습니다.
- `make ps`: Docker 컨테이너 생존 여부 확인
- `curl localhost:8080/actuator/health`: 서비스 헬스 체크 여부 확인

---

## 🚀 권장 개발 도구 및 언어
- **Go + Bubble Tea**: 가장 세련되고 강력한 TUI 개발 라이브러리 (추천)
- **Python + Textual**: 쉽고 빠르게 화려한 TUI 개발 가능
- **Bash + Gum**: 별도의 컴파일 없이 쉘 스크립트만으로 메뉴 구성 가능
