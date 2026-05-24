# audit-deliverables-plugin

[감리용] 설계단계 감리 산출물 작성 보조 스킬 모음.

## 포함 스킬

| 스킬 | 입력 → 출력 | 트리거 예 |
| --- | --- | --- |
| `openapi-to-interface-xlsx` | OpenAPI 3.x JSON + Interface 요약/템플릿 xlsx → 중분류(IF-DTS-PGI 등) 별 인터페이스 설계서 xlsx | "인터페이스 설계서 만들어줘", "채번 json 으로 설계서 export" |
| `hwpx-db-design` | dbml(`erd/*.dbml`) + v1.2 baseline HWPX → 시스템 헤더 표 4종 + 테이블별 명세 + audit 6행 + 인덱스 표 + ERD PNG 삽입 완성 HWPX | "DB 설계서 작성/갱신", "DBML 을 hwpx 에 옮겨줘", "TABLE ID 부여" |

## 실행

```bash
# OpenAPI → IF 설계서 xlsx
python "${CLAUDE_PLUGIN_ROOT}/skills/openapi-to-interface-xlsx/scripts/build_interface_xlsx.py" \
  --summary <Interface_summary.xlsx> --template <Interface_template.xlsx> \
  --json <openapi.json> [...] --out <출력 디렉토리>
```

`hwpx-db-design` 은 `mcp__hwp-mcp__*` MCP 도구로 HWPX 셀을 직접 채운다. SKILL.md 의 매핑 규칙(§4), audit 6행(§5), 셀 한도(§6), 검수 체크리스트(§9) 를 따른다.

## 의존성

- Python 3.10+ / `openpyxl` (OpenAPI → xlsx)
- `mcp__hwp-mcp__*` MCP 서버 (HWPX 편집)
- 입력 자산: 채번 OpenAPI JSON, `Interface_summary.xlsx`, `Interface_template.xlsx`, v1.2 baseline HWPX, `erd/*.dbml` + `erd/*.png`
