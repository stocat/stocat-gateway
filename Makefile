## 기본 변수
CONSUL_ADDR ?= http://localhost:8500
# 옵션 1) JWT_SECRET: 최종 저장할 시크릿(그대로 저장)
JWT_SECRET ?=
# 옵션 2) JWT_PASSPHRASE: 제공 시, sha256(passphrase)의 바이너리를 base64로 인코딩해 파생 시크릿으로 저장
JWT_PASSPHRASE ?= stocat-jwt

.PHONY: help compose-up compose-down consul-wait consul-jwt consul-routes consul-init gateway dev all

help:
	@echo "사용 가능한 명령(타깃):"
	@echo "  compose-up       docker-compose 로 Consul 기동(detached)"
	@echo "  compose-down     docker-compose 종료"
	@echo "  consul-wait      Consul 리더 선출될 때까지 대기"
	@echo "  consul-jwt       Consul KV에 JWT 시크릿 저장"
	@echo "                   - JWT_SECRET 제공 시 그대로 저장"
	@echo "                   - JWT_PASSPHRASE 제공 시 sha256(passphrase) → base64로 파생하여 저장"
	@echo "                   - 둘 다 없으면 강한 랜덤 시크릿 자동 생성하여 저장"
	@echo "  consul-routes    Consul KV에 routes.yaml 등록"
	@echo "  consul-init      JWT 시크릿과 routes.yaml 모두 등록"
	@echo "  gateway          게이트웨이 모듈 실행 (:gateway:bootRun)"
	@echo "  dev              Consul 기동 + routes 등록 + (시크릿 등록) + 게이트웨이 실행"
	@echo "  all              compose-up → consul-wait → routes → jwt → gateway 순서로 전체 실행"
	@echo ""
	@echo "변수: CONSUL_ADDR=$(CONSUL_ADDR)  JWT_SECRET=[hidden]  JWT_PASSPHRASE=[hidden]"

compose-up:
	docker-compose up -d

compose-down:
	docker-compose down

consul-wait:
	@echo "[consul-wait] Consul이 준비될 때까지 대기합니다: $(CONSUL_ADDR)"
	@until curl -fsS $(CONSUL_ADDR)/v1/status/leader > /dev/null; do \
		echo "  - 대기 중..."; \
		sleep 1; \
	done
	@echo "[consul-wait] Consul OK"

consul-jwt:
	@echo "[consul-jwt] JWT 시크릿을 결정합니다 (우선순위: JWT_SECRET > JWT_PASSPHRASE > 랜덤)"
	@SECRET="$(JWT_SECRET)"; \
	if [ -z "$$SECRET" ] && [ -n "$(JWT_PASSPHRASE)" ]; then \
		SECRET=$$(printf '%s' '$(JWT_PASSPHRASE)' | openssl dgst -sha256 -binary | base64); \
		echo "[consul-jwt] JWT_PASSPHRASE로부터 파생 시크릿 생성(sha256→base64)"; \
	fi; \
	if [ -z "$$SECRET" ]; then \
		SECRET=$$(openssl rand -base64 48); \
		echo "[consul-jwt] 랜덤 시크릿 생성(base64, 48바이트)"; \
	fi; \
	curl --fail --show-error --silent \
		--request PUT \
		--data-binary "$$SECRET" \
		$(CONSUL_ADDR)/v1/kv/config/common/secrets/jwt-secret \
		&& echo "\n[consul-jwt] Consul KV에 jwt-secret 저장 완료"

consul-routes:
	@echo "[consul-routes] routes.yaml을 Consul KV에 저장합니다 ($(CONSUL_ADDR))"
	curl --fail --show-error --silent \
		--request PUT \
		--data-binary @consul/routes.yaml \
		$(CONSUL_ADDR)/v1/kv/config/gateway/routes.yaml \
		&& echo "\n[consul-routes] routes.yaml 저장 완료 (consul/routes.yaml)"

consul-init: consul-jwt consul-routes

gateway:
	./gradlew :gateway:bootRun

dev: compose-up consul-wait consul-routes consul-jwt gateway

all: compose-up consul-wait consul-routes consul-jwt gateway
