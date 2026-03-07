## 기본 변수
CONSUL_ADDR ?= http://localhost:8500
JWT_PASSPHRASE ?= stocat-jwt

# ANSI 색상 코드 (TUI/터미널 가독성용)
BLUE   = \033[1;34m
GREEN  = \033[1;32m
YELLOW = \033[1;33m
RED    = \033[1;31m
RESET  = \033[0m

.PHONY: help infra-up infra-down infra-wait config-jwt config-routes config-all gateway app-catalog app-order all ps test-ws

help:
	@echo "$(BLUE)Stocat Microservices 관리 도구$(RESET)"
	@echo "사용 가능한 명령:"
	@echo "  $(GREEN)infra-up$(RESET)        Consul 등 인프라 컨테이너 실행"
	@echo "  $(GREEN)infra-down$(RESET)      모든 컨테이너 종료 및 삭제"
	@echo "  $(GREEN)config-all$(RESET)      JWT 시크릿 및 라우트 설정을 Consul에 등록"
	@echo "  $(GREEN)gateway$(RESET)         API 게이트웨이 실행"
	@echo "  $(GREEN)app-catalog$(RESET)     Catalog 서비스 실행"
	@echo "  $(GREEN)app-order$(RESET)       Order 서비스 실행"
	@echo "  $(YELLOW)all$(RESET)             인프라 + 설정 + 게이트웨이를 한 번에 실행 (All-in-One)"
	@echo "  $(YELLOW)test-ws$(RESET)         웹소켓 자동화 테스트 도구 위치 안내"

# --- 1. Infrastructure (인프라 계층) ---
infra-up:
	@echo "$(BLUE)[infra] 인프라를 기동합니다...$(RESET)"
	docker-compose up -d

infra-down:
	@echo "$(RED)[infra] 모든 구성을 종료합니다...$(RESET)"
	docker-compose down

infra-wait:
	@echo "$(BLUE)[infra] Consul 준비 대기 중: $(CONSUL_ADDR)$(RESET)"
	@until curl -fsS $(CONSUL_ADDR)/v1/status/leader > /dev/null; do \
		echo "  - 대기 중..."; \
		sleep 1; \
	done
	@echo "$(GREEN)[infra] Consul 준비 완료!$(RESET)"

# --- 2. Configuration (설정 계층) ---
config-jwt:
	@echo "$(BLUE)[config] JWT secret 생성 및 등록 중...$(RESET)"
	@SECRET=$$(printf '%s' '$(JWT_PASSPHRASE)' | openssl dgst -sha256 -binary | base64); \
	curl --fail --silent --request PUT --data-binary "$$SECRET" \
		$(CONSUL_ADDR)/v1/kv/config/common/secrets/jwt-secret
	@echo "$(GREEN)[config] JWT secret 등록 완료$(RESET)"

config-routes:
	@echo "$(BLUE)[config] API Routes 등록 중...$(RESET)"
	@curl --fail --silent --request PUT --data-binary @consul-config/routes.yaml \
		$(CONSUL_ADDR)/v1/kv/config/gateway/routes.yaml
	@echo "$(GREEN)[config] Routes 등록 완료 (consul-config/routes.yaml)$(RESET)"

config-all: config-jwt config-routes

# --- 3. Applications (애플리케이션 계층) ---
gateway:
	@echo "$(BLUE)[app] Gateway 실행 중...$(RESET)"
	./gradlew :gateway:bootRun

app-catalog:
	@echo "$(BLUE)[app] Catalog 서비스 실행 중...$(RESET)"
	./gradlew :services:demo-catalog:bootRun

app-order:
	@echo "$(BLUE)[app] Order 서비스 실행 중...$(RESET)"
	./gradlew :services:demo-order:bootRun

# --- 4. Orchestration (복합 실행) ---
all: infra-up infra-wait config-all gateway

ps:
	@docker-compose ps
	@echo "$(YELLOW)------------------------------------------------$(RESET)"
	@echo "Consul UI: http://localhost:8500"

test-ws:
	@echo "$(YELLOW)웹소켓 테스트 가이드는 다음 경로를 참고하세요:$(RESET)"
	@echo "  - Location: gateway/http/websocket/"
	@echo "  - Command: cd gateway/http/websocket && make test-rate"
