# telegram-notification-plugin

Claude Code의 이벤트(작업 완료, 알림 등)를 텔레그램으로 받아볼 수 있는 플러그인입니다.

## 동작 방식

Claude Code에서 `Stop` 또는 `Notification` 이벤트가 발생하면 다음 정보를 수집해 웹훅으로 전송합니다.

- 이벤트 타입 (`stop` / `notification`)
- 사용자 및 호스트명 (`user@hostname`)
- 현재 git 브랜치
- 작업 디렉토리

웹훅 서버에서 해당 데이터를 받아 텔레그램 메시지로 전달합니다.

## 사전 요구사항

- [Claude Code](https://docs.anthropic.com/ko/docs/claude-code) 설치
- `bash`, `curl`, `node` 설치
- 텔레그램 봇 및 웹훅 서버 설정

## 설치 방법

### 1. 플러그인 디렉토리 복사

```bash
# Claude Code 설정 디렉토리 아래 plugins 폴더에 복사
cp -r telegram-notification-plugin ~/.claude/plugins/telegram-notification-plugin
```

### 2. hooks.json 등록

`~/.claude/settings.json`의 `hooks` 섹션에 아래 내용을 추가합니다.

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.claude/plugins/telegram-notification-plugin/scripts/notify.sh stop",
            "timeout": 30
          }
        ]
      }
    ],
    "Notification": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.claude/plugins/telegram-notification-plugin/scripts/notify.sh notification",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
```

> `${CLAUDE_PLUGIN_ROOT}` 환경변수를 지원하는 플러그인 매니저를 사용하는 경우, 경로를 `${CLAUDE_PLUGIN_ROOT}/scripts/notify.sh`로 유지하면 됩니다.

### 3. 웹훅 URL 설정

`scripts/notify.sh` 파일을 열어 웹훅 URL을 본인의 서버로 변경합니다.

```bash
# 기존
curl -s -X POST https://juno71w.duckdns.org/webhook \

# 변경
curl -s -X POST https://your-server.example.com/webhook \
```

### 4. 스크립트 실행 권한 부여

```bash
chmod +x ~/.claude/plugins/telegram-notification-plugin/scripts/notify.sh
```

## 디렉토리 구조

```
telegram-notification-plugin/
├── .claude-plugin/
│   └── plugin.json        # 플러그인 메타데이터
├── hooks/
│   └── hooks.json         # Claude Code 훅 설정
├── scripts/
│   └── notify.sh          # 웹훅 전송 스크립트
└── README.md
```

## 웹훅 페이로드 예시

```json
{
  "cwd": "/Users/username/my-project",
  "event_type": "stop",
  "user": "username@MacBook-Pro.local",
  "branch": "main"
}
```
