# telegram-notification-plugin

Claude Code 의 `Stop` / `Notification` 이벤트를 텔레그램으로 받아보는 알림 플러그인.

## 동작

`hooks/hooks.json` 이 두 이벤트에 `scripts/notify.sh` 를 연결한다. 스크립트는 훅 페이로드에 `event_type`, `user@host`, `branch` 를 덧붙여 웹훅(`https://juno71w.duckdns.org/webhook`) 으로 POST 한다. 웹훅 서버가 텔레그램 봇으로 전달한다.

## 설치

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

## 의존성

`bash`, `curl`, `node`, `git`. 외부 웹훅 서버 URL 은 `scripts/notify.sh` 에 하드코딩되어 있어 다른 서버로 바꾸려면 직접 수정한다.
