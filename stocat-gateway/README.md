# stocat-gateway — Consul Service Discovery + Spring Cloud Gateway

Consul 기반 서비스 디스커버리와 Spring Cloud Gateway(WebFlux)로 구성된 경량 API 게이트웨이
`gateway`는 Consul에 등록된 서비스 목록을 읽어 동적으로 라우트를 생성하고, `services` 하위의 샘플 서비스들이 Consul에 자체 등록됩니다.

- Gateway: Spring Cloud Gateway(Server WebFlux)
- Service Registry: HashiCorp Consul (Docker Compose로 Dev 모드 실행)
- Sample Services: `demo-catalog`(8081), `demo-order`(8082)
- Java 21, Spring Boot 3.5, Spring Cloud 2025.0

## 아키텍처
![img.png](img.png)


간단히 말해 각 서비스는 기동 시 Consul에 등록되고(헬스체크 포함), Gateway는 Consul Discovery를 통해 서비스 목록을 구독하여 라우트를 동적으로 생성합니다. 기본 설정에서는 서비스 ID 기준으로 `/{serviceId}/**` 패턴의 라우트가 만들어집니다.

참고: 기본 라우트는 서비스 ID 접두어가 그대로 백엔드로 전달됩니다. 백엔드가 접두어 없이 경로를 받길 원한다면 `StripPrefix=1` 같은 기본 필터를 Discovery Locator에 추가하세요.

## 실행 방법(Quick Start)
1) Consul 띄우기
- `docker-compose up -d consul`
- UI: http://localhost:8500 (Services 탭에서 등록 상태 확인)

2) 서비스 기동(각 터미널에서)
- `./gradlew :services:demo-catalog:bootRun`
- `./gradlew :services:demo-order:bootRun`

3) 게이트웨이 기동
- `./gradlew :gateway:bootRun`

4) 동작 확인
- 서비스 직접 헬스체크
  - `curl http://localhost:8081/actuator/health`
  - `curl http://localhost:8082/actuator/health`
- 게이트웨이 라우팅(접두어 포함)
  - 기본값으로는 `/demo-catalog/**`, `/demo-order/**` 경로가 생성됩니다.
  - 백엔드가 접두어를 기대하지 않는 경우 Discovery Locator에 `StripPrefix` 필터를 추가하세요.

## 주요 설정 포인트
- Consul Dev 모드: `docker-compose.yml`에서 `hashicorp/consul:1.21.1`를 Dev 모드로 실행합니다.
- 서비스 등록과 헬스체크
  - 각 서비스 `application.yml`
    - `spring.cloud.consul.discovery.register=true`
    - `health-check-path=/actuator/health` 및 `health-check-interval=10s`
- 게이트웨이 동적 라우팅
  - `gateway/src/main/resources/application.yml`
    - `spring.cloud.gateway.server.webflux.discovery.locator.enabled=true`
    - `lower-case-service-id=true`

필요 시 Discovery Locator에 기본 필터를 부여하여 경로 접두어 제거 등 공통 처리를 적용할 수 있습니다(예: `StripPrefix=1`).

## 폴더 구조
- `gateway/` — Spring Cloud Gateway 모듈
- `services/demo-catalog/`, `services/demo-order/` — 샘플 서비스 모듈
- `docker-compose.yml` — 로컬 Consul 실행 정의


## 왜 Consul인가
- 단순하고 견고한 서비스 레지스트리/키밸류 스토어
- Health 체크/세션 TTL 기반 등록 상태 관리
- 멀티런타임/멀티플랫폼 환경에서의 호환성

## 관련 파일
- `gateway/build.gradle` — Consul Discovery, Gateway(WebFlux) 의존성
- `gateway/src/main/resources/application.yml` — Discovery Locator 설정
- `services/*/src/main/resources/application.yml` — 서비스 등록/헬스체크 설정
- `docker-compose.yml` — Consul Dev 모드 실행

---
이 README는 Consul 기반 서비스 디스커버리 데모를 소개하고 빠르게 실행/확인할 수 있도록 작성되었습니다. 추가로 샘플 엔드포인트가 필요하면 각 서비스에 컨트롤러를 추가해 라우팅 동작을 쉽게 확인할 수 있습니다.
