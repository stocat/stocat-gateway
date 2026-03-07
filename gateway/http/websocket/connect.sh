#!/bin/bash

# 1. 랜덤 사용자 정보 생성 (중복 가입 방지)
SUFFIX=$RANDOM
EMAIL="test${SUFFIX}@example.com"
NICKNAME="tester${SUFFIX}"
PASSWORD="password"
GATEWAY_URL="http://127.0.0.1:8080"

echo "============================================================"
echo "[1/3] 임시 계정으로 회원가입 진행 중... ($EMAIL)"
curl -s -X POST $GATEWAY_URL/auth/signup \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\", \"password\":\"$PASSWORD\", \"nickname\":\"$NICKNAME\"}" > /dev/null

echo "[2/3] 로그인 및 JWT 토큰 발급 중..."
LOGIN_RES=$(curl -s -X POST $GATEWAY_URL/auth/login \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\", \"password\":\"$PASSWORD\"}")

# Python 내부 모듈을 사용하여 안전하게 토큰 파싱 (jq 의존성 제거)
TOKEN=$(echo "$LOGIN_RES" | python3 -c "import sys, json; print(json.load(sys.stdin).get('data', {}).get('accessToken', ''))" 2>/dev/null)

if [ -z "$TOKEN" ]; then
  echo "[에러] 토큰 발급에 실패했습니다."
  echo "서버 응답: $LOGIN_RES"
  exit 1
fi

echo "[3/3] 토큰 발급 완료! 웹소켓 연결을 시작합니다. (종료: Ctrl+C)"
echo "Target: ws://localhost:8080/asset-ws/ws/exchange-rates"
echo "============================================================"

# wscat 실행 (발급받은 토큰 사용)
npx -y wscat -c "ws://localhost:8080/asset-ws/ws/exchange-rates?access_token=$TOKEN"
