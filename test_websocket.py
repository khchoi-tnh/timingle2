#!/usr/bin/env python3
"""
WebSocket 통합 테스트 스크립트
사용법: python3 test_websocket.py
"""

import asyncio
import websockets
import json
import requests
import sys

API_BASE = "http://localhost:8080/api/v1"
WS_URL = "ws://localhost:8080/api/v1/ws"

def register_user(phone, name):
    """사용자 등록"""
    response = requests.post(f"{API_BASE}/auth/register", json={
        "phone": phone,
        "name": name
    })
    if response.status_code == 201:
        data = response.json()
        print(f"✅ 사용자 등록 성공: {data['user']['name']}")
        return data['access_token']
    else:
        print(f"❌ 사용자 등록 실패: {response.text}")
        return None

def create_event(token, title):
    """이벤트 생성"""
    response = requests.post(f"{API_BASE}/events",
        headers={"Authorization": f"Bearer {token}"},
        json={
            "title": title,
            "description": "테스트 이벤트",
            "start_time": "2026-01-01T10:00:00Z",
            "end_time": "2026-01-01T12:00:00Z",
            "location": "서울"
        }
    )
    if response.status_code == 201:
        data = response.json()
        print(f"✅ 이벤트 생성 성공: {data['title']} (ID: {data['id']})")
        return data['id']
    else:
        print(f"❌ 이벤트 생성 실패: {response.text}")
        return None

async def test_websocket_chat(token, event_id, user_name):
    """WebSocket 채팅 테스트"""
    uri = f"{WS_URL}?event_id={event_id}"
    headers = {"Authorization": f"Bearer {token}"}

    try:
        async with websockets.connect(uri, extra_headers=headers) as websocket:
            print(f"✅ [{user_name}] WebSocket 연결 성공 (Event ID: {event_id})")

            # 메시지 전송
            message = {
                "type": "message",
                "message": f"안녕하세요! {user_name}입니다."
            }
            await websocket.send(json.dumps(message))
            print(f"📤 [{user_name}] 메시지 전송: {message['message']}")

            # 메시지 수신 대기
            try:
                response = await asyncio.wait_for(websocket.recv(), timeout=5.0)
                data = json.loads(response)
                print(f"📥 [{user_name}] 메시지 수신: {data['sender_name']}: {data['message']}")
                return True
            except asyncio.TimeoutError:
                print(f"⏱️  [{user_name}] 메시지 수신 타임아웃")
                return False

    except Exception as e:
        print(f"❌ [{user_name}] WebSocket 오류: {str(e)}")
        return False

def get_messages(token, event_id):
    """채팅 메시지 조회"""
    response = requests.get(f"{API_BASE}/events/{event_id}/messages",
        headers={"Authorization": f"Bearer {token}"}
    )
    if response.status_code == 200:
        messages = response.json()
        print(f"✅ 메시지 조회 성공: {len(messages)}개 메시지")
        for msg in messages:
            print(f"  - {msg['sender_name']}: {msg['message']}")
        return True
    else:
        print(f"❌ 메시지 조회 실패: {response.text}")
        return False

async def main():
    print("=" * 60)
    print("🚀 timingle WebSocket 통합 테스트 시작")
    print("=" * 60)

    # 1. 사용자 등록
    print("\n1️⃣  사용자 등록 테스트")
    token1 = register_user("01011112222", "테스터1")
    token2 = register_user("01033334444", "테스터2")

    if not token1 or not token2:
        print("❌ 사용자 등록 실패. 테스트 중단.")
        return

    # 2. 이벤트 생성
    print("\n2️⃣  이벤트 생성 테스트")
    event_id = create_event(token1, "WebSocket 테스트 이벤트")

    if not event_id:
        print("❌ 이벤트 생성 실패. 테스트 중단.")
        return

    # 3. WebSocket 채팅 테스트
    print("\n3️⃣  WebSocket 채팅 테스트")

    # 두 사용자 동시 연결 및 메시지 전송
    tasks = [
        test_websocket_chat(token1, event_id, "테스터1"),
        test_websocket_chat(token2, event_id, "테스터2")
    ]
    results = await asyncio.gather(*tasks)

    # 4. 메시지 조회 (ScyllaDB에서)
    print("\n4️⃣  채팅 메시지 조회 테스트 (ScyllaDB)")
    await asyncio.sleep(2)  # Worker가 저장할 시간 대기
    get_messages(token1, event_id)

    # 결과 요약
    print("\n" + "=" * 60)
    if all(results):
        print("✅ 모든 테스트 통과!")
    else:
        print("⚠️  일부 테스트 실패")
    print("=" * 60)

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\n\n⚠️  테스트 중단됨")
        sys.exit(0)
