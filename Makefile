## 기본 변수
CONSUL_ADDR ?= http://localhost:8500
JWT_PASSPHRASE ?= stocat-jwt

# ANSI 색상 코드 (TUI/터미널 가독성용)
BLUE   = \033[1;34m
GREEN  = \033[1;32m
YELLOW = \033[1;33m
RED    = \033[1;31m
RESET  = \033[0m

.PHONY: help infra-up infra-down infra-wait config-jwt config-routes config-all \
        gateway log-gateway stop-gateway \
        app-catalog log-catalog stop-catalog \
        app-order log-order stop-order \
        all stop-all ps test-ws

help:
	@echo "$(BLUE)Stocat Gateway 및 서비스 관리 도구$(RESET)"
	@echo "사용 가능한 명령:"
	@echo "  $(GREEN)infra-up$(RESET)        Consul 등 인프라 컨테이너 실행"
	@echo "  $(GREEN)infra-down$(RESET)      모든 컨테이너 종료 및 삭제"
	@echo "  $(GREEN)config-all$(RESET)      JWT 시크릿 및 라우트 설정을 Consul에 등록"
	@echo ""
	@echo "실행 관련 (백그라운드):"
	@echo "  $(GREEN)gateway$(RESET)         API 게이트웨이 실행"
	@echo "  $(GREEN)app-catalog$(RESET)     Catalog 서비스 실행"
	@echo "  $(GREEN)app-order$(RESET)       Order 서비스 실행"
	@echo ""
	@echo "로그 확인 (실시간):"
	@echo "  $(BLUE)log-gateway$(RESET)     Gateway 로그 보기"
	@echo "  $(BLUE)log-catalog$(RESET)     Catalog 로그 보기"
	@echo "  $(BLUE)log-order$(RESET)       Order 로그 보기"
	@echo ""
	@echo "종료 관련:"
	@echo "  $(RED)stop-gateway$(RESET)    Gateway 종료"
	@echo "  $(RED)stop-catalog$(RESET)    Catalog 종료"
	@echo "  $(RED)stop-order$(RESET)      Order 종료"
	@echo "  $(RED)stop-all$(RESET)        모든 백그라운드 서비스 종료"
	@echo ""
	@echo "기타:"
	@echo "  $(YELLOW)all$(RESET)             인프라 + 설정 + 게이트웨이 순차 기동 (All-in-One)"
	@echo "  $(YELLOW)ps$(RESET)              컨테이너 상태 확인"

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

# --- 3. Applications (애플리케이션 계층 - 자바) ---
define start_app
	@echo "$(BLUE)[app] $(1) 을 백그라운드에서 실행합니다...$(RESET)"
	@mkdir -p logs
	@nohup ./gradlew :$(1):bootRun > logs/$(1).log 2>&1 &
	@echo "$(GREEN)[app] $(1) 실행 명령 전송 완료 (로그: logs/$(1).log)$(RESET)"
endef

define stop_app
	@echo "$(RED)[stop] $(1) 서비스를 종료합니다...$(RESET)"
	-@pkill -f ":$(1):bootRun" || echo "이미 종료되었거나 실행 중이지 않습니다."
endef

define show_log
	@echo "$(BLUE)[logs] $(1) 실시간 로그를 출력합니다... (종료: Ctrl+C)$(RESET)"
	@if [ -f logs/$(1).log ]; then \
		tail -f logs/$(1).log; \
	else \
		echo "$(RED)[error] 로그 파일이 없습니다. 서비스가 실행 중인지 확인하세요.$(RESET)"; \
	fi
endef

gateway:
	$(call start_app,gateway)

log-gateway:
	$(call show_log,gateway)

stop-gateway:
	$(call stop_app,gateway)

app-catalog:
	$(call start_app,services:demo-catalog)

log-catalog:
	$(call show_log,services:demo-catalog)

stop-catalog:
	$(call stop_app,services:demo-catalog)

app-order:
	$(call start_app,services:demo-order)

log-order:
	$(call show_log,services:demo-order)

stop-order:
	$(call stop_app,services:demo-order)

stop-all:
	@echo "$(RED)[stop] 모든 백그라운드 Spring Boot 서비스를 종료합니다...$(RESET)"
	-@pkill -f "bootRun" || echo "실행 중인 프로세스가 없습니다."

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
