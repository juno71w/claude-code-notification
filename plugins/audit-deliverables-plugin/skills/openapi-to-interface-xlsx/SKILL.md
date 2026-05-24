---
name: openapi-to-interface-xlsx
description: OpenAPI 3.x JSON 스펙 한두 개 이상과 Interface_summary.xlsx(요약표), Interface_template.xlsx(시트 양식)를 입력받아 중분류(예: IF-DTS-PGI, IF-DCS-CAT)별로 인터페이스 설계서 xlsx 파일을 자동 생성한다. 사용자가 "인터페이스 설계서 만들어줘", "중분류별 엑셀로 뽑자", "OpenAPI 로 설계서 만들기", "summary 랑 template 으로 IF 시트 생성", "채번 json 으로 설계서 export" 같은 요청을 하면 즉시 트리거. 셀 매핑 규칙은 references/mapping.md 에 명세되어 있으며, 그대로 변환 스크립트(scripts/build_interface_xlsx.py)에 구현되어 있다.
---

# openapi-to-interface-xlsx

## 무엇을 하는가

OpenAPI 3.x JSON(예: `마켓플레이스_채번.json`, `카탈로그_채번.json`, `품질검사_채번.json`) 안의 operation 들을 `summary` 안에 박힌 Interface ID(`[IF-XXX-YYY-NN]`) 기준으로 골라낸 뒤, **중분류 prefix(예: `IF-DTS-PGI`) 별로 하나의 xlsx 파일**을 생성한다. 한 xlsx 안에는 요약 시트 + IF-ID 시트들이 들어간다.

각 IF 시트는 `Interface_template.xlsx` 의 `템플릿` 시트와 동일한 셀 배치(헤더 4행 + Request Headers + Request Parameters + Response Parameters + 설명) 를 가지며, 행 수는 실제 파라미터 개수에 맞춰 동적으로 늘어난다.

## 언제 사용하는가

- 사용자가 `Interface_summary.xlsx` + `*.json` (OpenAPI 채번) + `Interface_template.xlsx` 세 가지 파일을 들고 와 "설계서로 변환" 을 요청할 때
- "중분류별로 엑셀 쪼개줘", "IF 시트 자동 생성" 같은 요청
- 이미 한 번 생성했고 JSON 만 갱신된 상태에서 재실행이 필요할 때

## 사용 흐름

1. 입력 파일 위치 확인
   - `--summary`: `Interface_summary.xlsx` (시트명 `요약표`)
   - `--template`: `Interface_template.xlsx` (시트명 `템플릿`)
   - `--json`: 채번된 OpenAPI JSON 1개 이상
   - `--out`: 출력 디렉토리
2. 매핑 규칙 확인이 필요하면 [`references/mapping.md`](references/mapping.md) 를 참조한다. 사용자가 매핑을 바꿔달라고 하면 이 파일을 수정한 뒤 스크립트도 함께 손본다.
3. 스크립트 실행 (이 SKILL.md 와 같은 디렉토리의 `scripts/build_interface_xlsx.py`):
   ```bash
   python "${CLAUDE_PLUGIN_ROOT}/skills/openapi-to-interface-xlsx/scripts/build_interface_xlsx.py" \
     --summary  <Interface_summary.xlsx 경로> \
     --template <Interface_template.xlsx 경로> \
     --json     <openapi1.json> [<openapi2.json> ...] \
     --out      <출력 디렉토리>
   ```
   `${CLAUDE_PLUGIN_ROOT}` 가 없는 환경이라면 SKILL.md 의 위치를 기준으로 `scripts/build_interface_xlsx.py` 의 절대경로를 직접 계산해서 실행한다.
4. 출력 검증: 첫 시트(요약) 가 의도대로 채워졌는지, 한두 개 IF 시트의 Request/Response/설명 영역이 정확한지를 사용자에게 보여주고 피드백을 받는다.

## 산출물

```
<out>/
  PG 연동 체계 구축 (DTS-PGI).xlsx        # 중분류별 1 파일
  과금 체계 및 리워드 체계 고도화 (DTS-BRS).xlsx
  ...
  _unmapped.xlsx                          # JSON에 있지만 summary에 없는 IF (있을 때만)
```

각 xlsx 의 첫 시트는 `요약` (해당 중분류의 IF 목록), 이후 시트는 IF-ID 하나당 한 개. summary 에는 있지만 JSON 에 매칭되는 operation 이 없는 IF 는 시트명에 `(미구현)` 이 붙고 본문은 빈 채로 생성된다.

## 매핑 규칙 핵심

| Excel 셀 | 출처 |
| --- | --- |
| `D2` 인터페이스ID | summary xlsx 의 `Interface ID` (2자리 형식 유지) |
| `L2` 인터페이스명 | summary xlsx 의 `Interface 명` |
| `D3` 데이터 송신처 | OpenAPI `tags[0]` 의 `[Buyer]`/`[Seller]`/`[Admin]`/`[Public]`/`[Internal]` → 한글 매핑 |
| `L3` 데이터 수신처 | `info.title` 키워드 매핑 (Marketplace→마켓플레이스 등) |
| `D4` 프로토콜 | `HTTP` 고정 |
| `L4` 발생주기 | `수동호출` 고정 |
| `D5` URL | `{METHOD} {API}{path}` (localhost servers 는 `{API}` 마스킹) |
| Request Headers/Params | `parameters[*]` + `requestBody` 첫 미디어 schema 평탄화 |
| Response Params | depth 별 컬럼(B→C→D), A 라벨은 `D{n}` 또는 `D{n}-{seq}` (자세한 규칙은 mapping.md §4.5) |
| 데이터(M) 컬럼 | enum / format 같은 형식 정보만. 구체 example 값은 사용하지 않음 |
| 비고(N) 컬럼 (응답) | 필수 여부 표기하지 않음 |

자세한 규칙은 항상 [`references/mapping.md`](references/mapping.md) 가 정답.

## ID 정규화

- summary xlsx: `IF-DTS-MDB-10` (2자리)
- JSON summary: `[IF-DTS-MDB-010]` (3자리)
- 매칭은 prefix + 끝자리 정수로 비교 (`010 == 10`). 표기 형식은 summary xlsx 의 것을 우선 사용.

## 의존성

- Python 3.10+
- `openpyxl` (대부분의 환경에 이미 설치되어 있음. 없으면 `pip install openpyxl`)

## 한계 / 주의

- 응답 envelope 가정 없이 `responses["200"].content["application/json"].schema` 의 top-level 부터 펼친다. 만약 사용자의 시스템이 `{code, message, data}` envelope 을 쓰는데 JSON 에 그게 빠져 있으면, top-level 이 곧 data 본문이 된다.
- 셀 스타일은 템플릿의 프로토타입 행에서 복사. 행 삽입 방식이 아니라 시트를 새로 그리는 방식이라 템플릿에 들어있는 예시 시트(IF-CCS-ESL-001 등) 의 모양과 100% 동일하지는 않을 수 있음 — 시각적 검토가 필요한 부분.
- 매핑 규칙이 사용자/프로젝트마다 다를 수 있으니 첫 실행 후에는 반드시 한두 시트를 열어 검토하고 `mapping.md` 를 갱신한다.
