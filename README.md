# telegram-notification-plugin

Claude Code의 이벤트(작업 완료, 알림 등)를 텔레그램으로 받아볼 수 있는 플러그인입니다.

## 동작 방식

Claude Code에서 `Stop` 또는 `Notification` 이벤트가 발생하면 다음 정보를 수집해 웹훅으로 전송합니다.

- 이벤트 타입 (`stop` / `notification`)
- 사용자 및 호스트명 (`user@hostname`)
- 현재 git 브랜치
- 작업 디렉토리

웹훅 서버에서 해당 데이터를 받아 텔레그램 메시지로 전달합니다.

## 설치방법
```
/plugin marketplace add https://github.com/juno71w/claude-code-notification.git
```

## 응답 예시
```
🎉 event: 알림
👤 user: parkjunho@bagjunhoui-Macmini.local
📂 path: ~/Desktop/plugin-practice/claude-code-util
🌿 branch: main
🪪 session: #bd7e0ff2
🤖 reply: Claude Code needs your attention
```