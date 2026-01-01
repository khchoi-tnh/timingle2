#!/bin/bash

# timingle 백엔드 통합 테스트 스크립트

API_BASE="http://localhost:8080/api/v1"

echo "============================================================"
echo "🚀 timingle 백엔드 통합 테스트"
echo "============================================================"

# 1. Health Check
echo ""
echo "1️⃣  Health Check"
curl -s $API_BASE/../health | python3 -m json.tool
echo ""

# 2. 사용자 등록
echo "2️⃣  사용자 등록"
RESPONSE=$(curl -s -X POST $API_BASE/auth/register \
  -H "Content-Type: application/json" \
  -d '{"phone":"01055556666","name":"통합테스터"}')

echo "$RESPONSE" | python3 -m json.tool

TOKEN=$(echo "$RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['access_token'])" 2>/dev/null)

if [ -z "$TOKEN" ]; then
  echo "❌ 사용자 등록 실패"
  exit 1
fi

echo "✅ Access Token: ${TOKEN:0:50}..."
echo ""

# 3. 이벤트 생성
echo "3️⃣  이벤트 생성"
EVENT_RESPONSE=$(curl -s -X POST $API_BASE/events \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "title":"통합 테스트 이벤트",
    "description":"WebSocket 및 채팅 테스트",
    "start_time":"2026-01-05T14:00:00Z",
    "end_time":"2026-01-05T16:00:00Z",
    "location":"테스트 룸"
  }')

echo "$EVENT_RESPONSE" | python3 -m json.tool

EVENT_ID=$(echo "$EVENT_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['id'])" 2>/dev/null)

if [ -z "$EVENT_ID" ]; then
  echo "❌ 이벤트 생성 실패"
  exit 1
fi

echo "✅ Event ID: $EVENT_ID"
echo ""

# 4. 이벤트 목록 조회
echo "4️⃣  이벤트 목록 조회"
curl -s -X GET "$API_BASE/events" \
  -H "Authorization: Bearer $TOKEN" | python3 -m json.tool
echo ""

# 5. 이벤트 확정
echo "5️⃣  이벤트 확정"
curl -s -X POST "$API_BASE/events/$EVENT_ID/confirm" \
  -H "Authorization: Bearer $TOKEN" | python3 -m json.tool
echo ""

# 6. 이벤트 상세 조회
echo "6️⃣  이벤트 상세 조회 (확정 상태 확인)"
curl -s -X GET "$API_BASE/events/$EVENT_ID" \
  -H "Authorization: Bearer $TOKEN" | python3 -m json.tool
echo ""

# 7. WebSocket 정보
echo "7️⃣  WebSocket 연결 정보"
echo "WebSocket URL: ws://localhost:8080/api/v1/ws?event_id=$EVENT_ID"
echo "Authorization: Bearer $TOKEN"
echo ""

# 8. 채팅 메시지 조회
echo "8️⃣  채팅 메시지 조회"
curl -s -X GET "$API_BASE/events/$EVENT_ID/messages" \
  -H "Authorization: Bearer $TOKEN" | python3 -m json.tool
echo ""

echo "============================================================"
echo "✅ 통합 테스트 완료!"
echo "============================================================"
echo ""
echo "📌 다음 단계:"
echo "1. wscat으로 WebSocket 테스트:"
echo "   wscat -c 'ws://localhost:8080/api/v1/ws?event_id=$EVENT_ID' \\"
echo "     -H 'Authorization: Bearer $TOKEN'"
echo ""
echo "2. 메시지 전송:"
echo '   {"type":"message","message":"안녕하세요!"}'
echo ""
