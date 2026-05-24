# JSON (OpenAPI 3.x) → Interface 설계서 Excel 셀 매핑 명세

이 문서는 OpenAPI 스펙(JSON) 1개 이상과 `Interface_summary.xlsx`(중분류 분류표), `Interface_template.xlsx`(시트 양식)를 입력으로 받아, 중분류별 인터페이스 설계서 xlsx 를 생성하는 변환 규칙을 정의한다.

## 1. 입출력 구조

| 입력 | 설명 |
| --- | --- |
| `*.json` (1개 이상) | OpenAPI 3.x 스펙. operation `summary` 안에 `[IF-XXX-YYY-NN]` 형태의 Interface ID 가 포함되어 있다고 가정. |
| `Interface_summary.xlsx` | 시트명 `요약표`. 컬럼 순서: `No, 대분류, 중분류, Interface ID, Interface 명, 설명, 비고` (1행 빈 행 + 2행 헤더). 중분류는 첫 행에만 값이 있는 병합 셀 패턴. |
| `Interface_template.xlsx` | 시트명 `템플릿` 을 복제하여 IF 1건당 1시트로 채운다. |

| 출력 | 설명 |
| --- | --- |
| `<중분류명>.xlsx` | 중분류 prefix(예: `IF-DTS-PGI`)에 매칭되는 인터페이스만 모은 워크북. 첫 시트는 해당 중분류의 요약, 이후 IF-ID 하나당 시트 한 개. |

## 2. Interface ID 정규화

- summary 의 `[IF-DTS-MDB-010]` 와 summary xlsx 의 `IF-DTS-MDB-10` 은 동일 인터페이스로 본다.
- 매칭 키: prefix(`IF-XXX-YYY`) + 끝자리 수(정수). 0-padding 무시.
- **시트명·표기 형식은 `Interface_summary.xlsx` 의 형식을 우선** (예: `IF-DTS-MDB-10`).
- 시트명은 Excel 제약(31자) 이내, 슬래시/콜론 등 금지 문자 제거.

## 3. 중분류 그룹핑

- prefix 기준 그룹핑: `IF-DTS-PGI-01` → 그룹 `IF-DTS-PGI`.
- 중분류명(파일명/요약 시트 표시용)은 `Interface_summary.xlsx` 의 `중분류` 컬럼에서 가져온다.
  - 원본 표기: `PG 연동 체계 구축\n(DTS-PGI)` — 줄바꿈은 공백 1개로 치환, 괄호와 prefix 매칭으로 그룹 식별.
  - 파일명 sanitization: `/`, `\`, `:`, `*`, `?`, `"`, `<`, `>`, `|`, 줄바꿈 제거.

## 4. 시트 생성

각 IF 마다 `템플릿` 시트를 복제(셀 값/스타일/병합/행높이/열너비 유지)한 뒤 다음 셀을 채운다.

### 4.1 헤더 (Row 2~5)

| 셀 | 값 | OpenAPI 매핑 |
| --- | --- | --- |
| `D2` | Interface ID (정규화 후) | summary 에서 추출 |
| `L2` | Interface 명 | `Interface_summary.xlsx` 의 `Interface 명` 컬럼 값. summary xlsx 에 매칭 행이 없으면 JSON `summary` 에서 `[IF-…]` 제거 후 trim 한 값을 fallback 으로 사용. |
| `D3` | 데이터 송신처 | `tags[0]` 에서 역할 추출 (`[Buyer]` / `[Seller]` / `[Admin]` / `[Public]` / `[Internal]`). 매핑: Buyer→구매자, Seller→판매자, Admin→관리자, Public→외부 호출자, Internal→내부 서비스. 매칭 안 되면 빈 칸. |
| `L3` | 데이터 수신처 | OpenAPI `info.title` (예: `Data Catalog API` → `데이터 카탈로그`). 사용자가 매뉴얼 매핑 제공 가능. |
| `D4` | 프로토콜 | 고정값 `HTTP`. |
| `L4` | 발생주기 | 고정값 `수동호출`. |
| `D5` | URL | `{METHOD} {servers[0].url 또는 placeholder}{path}` (예: `GET {API}/api/v1/...`). servers 가 localhost 면 placeholder `{API}` 로 치환. |

### 4.2 Request Headers (Row 7~)

- 헤더 라벨 행: Row 7 (이미 템플릿에 있음).
- 데이터 행: Row 8 이하. 추출 대상 = `parameters[*]` 중 `in == "header"` 또는 `in == "path"`. (path variable 은 URL 의 일부지만 호출 측 입력값이라는 점에서 헤더 섹션에 모아 표기) 없으면 빈 행 1개 유지.
- 비고(N) 컬럼에 `header` / `path` 로 위치 구분 표기.
- 컬럼 매핑:
  | 컬럼 | 값 |
  | --- | --- |
  | A (번호) | 1부터 |
  | B (데이터명) | `name` |
  | E (설명) | `description` |
  | I (형태) | `schema.type` 의 첫 글자 대문자 (`string`→`String`, `integer`→`Number`, `array`→`Array`, `object`→`Object`, `boolean`→`Boolean`). format 이 `date-time`/`date` 면 `String`. |
  | K (크기) | `가변` 고정. `maxLength` 가 있으면 그 값. |
  | M (데이터) | `description` 보조 또는 `enum` 나열 또는 `example`. |
  | N (비고) | required=true 면 `필수`. |

### 4.3 Request Parameters (Row 9~)

- 라벨 행: Row 9 (`Request Parameters`), 헤더 행: Row 10.
- 데이터 행 시작: Row 11.
- 대상 = `parameters[*]` 중 `in == "query"` + `requestBody.content` 의 첫 미디어 타입의 schema 펼침. (path variable 은 §4.2 Request Headers 로 옮김)
  - query parameter → schema 평탄화 없이 1줄에 1개.
  - requestBody schema 가 object 이면 properties 순서대로 1줄에 1개. nested 는 §4.5 트리 규칙 그대로 적용.
- 컬럼 매핑:
  | 컬럼 | 값 |
  | --- | --- |
  | A (번호) | 1부터 증가 |
  | B (데이터명) | `name` (parameter) 또는 property key (requestBody) |
  | E (설명) | `description` |
  | I (형태) | §4.2 와 동일 규칙 |
  | K (크기) | `가변` (기본) / `maxLength` |
  | M (데이터) | 형식·유효값 정보만. 우선순위: `enum` 콤마 나열 → `format`(date / date-time / int32 / int64 등) → description 에 명시된 패턴(예: `YYYY-MM-DD`). **`example` 값(인명·상품명 등 구체 샘플)은 사용하지 않음**. |
  | N (필수) | required=true 면 `Y`, 아니면 `N` |
  | P (비고) | path/query 구분 표기 (`path`/`query`/`body`), 기본값(default)이 있으면 `기본값: X` 추가 |

### 4.4 Response Parameters 표제 행 정의

- 라벨 행: Request Parameters 마지막 데이터 행 + 2 (한 줄 띄움) 위치에 `Response Parameters` 라벨 셀(A컬럼).
- 그 다음 줄: `번호 / 데이터명 / 설명 / 형태 / 크기 / 데이터 / 비고` 헤더.
- 그 다음 줄부터 데이터.

> **주의**: 템플릿의 Request/Response 영역은 행 수가 고정되어 있지 않으므로, parameter 개수만큼 행을 삽입하고 헤더 셀(라벨 행)을 동적으로 이동시켜야 한다. 구현은 "필요한 만큼 행 insert + 표제 셀을 다시 그림" 으로 처리한다.

### 4.5 Response Parameters 트리 표기

응답 스키마(주로 `responses["200"].content["application/json"].schema`)를 다음 규칙으로 펼친다. (대부분 표준 응답 envelope `{code, message, data}` 패턴을 따른다고 가정)

#### 4.5.1 컬럼 사용

| depth | A 컬럼 라벨 | 이름이 들어가는 컬럼 |
| --- | --- | --- |
| 0 (top-level) | 1, 2, 3 … (순서) | B |
| 1 (top-level 항목의 직접 자식) | `D{n}` (n=부모 top-level 번호) | C |
| 2+ | `D{n}-{seq}` (seq 는 #n 하위 전체 descendants 의 문서 순서 일련번호) | D, E, F … (depth 만큼 우측) |

예: top-level `data`(번호 3)가 객체이고 그 자식으로 `eslipTotal`, `eslipTotalPages`, `eslipsData(Array<Obj>)`, `tssTruckNo(Object)` 가 있고 `eslipsData` 의 항목이 `timestamp, service_key, …` 를 가질 때:

```
A=3,  B=data,             형태=Object
A=D3, C=eslipTotal,       형태=Number
A=D3, C=eslipTotalPages,  형태=Array
A=D3, C=eslipsData,       형태=Array
A=D3-1, D=timestamp,      형태=String   ← eslipsData[].timestamp
A=D3-2, D=service_key,    형태=String
...
A=D3-N, C=tssTruckNo,     형태=Object   ← data 직접 자식이지만 라벨은 D3-N (이미지 예시 따름)
```

규칙:
- 직접 자식이 primitive(String/Number/Boolean) 면 라벨 `D{n}`, 이름 컬럼 C.
- 직접 자식이 Object/Array 이면 라벨 `D{n}`, 이름 컬럼 C. **그 하위로 descend** 할 때는 seq 카운터를 증가시키며 `D{n}-{seq}` 사용.
- 다시 위로 올라와 또 다른 직접 자식을 만나면, 그 자식이 처음 등장한 객체가 아니라면(즉 같은 #n 의 후속 descendants 가 이미 펼쳐졌으면) `D{n}-{seq}` 라벨 + 이름 컬럼 C(=depth1) 로 유지. (이미지 예시의 `tssTruckNo = D3-11` 케이스를 재현)
- 더 단순한 대안(`D{n}` 만 사용)이 필요하면 옵션 `--simple-tree` 플래그로 전환 가능 — 단, 기본은 위 규칙.

#### 4.5.2 셀 값

| 컬럼 | 값 |
| --- | --- |
| 데이터명 (B/C/D…) | property key |
| 설명 (E) | `description` (없으면 빈 값) |
| 형태 (I) | §4.2 매핑. `array` 는 항상 `Array`, `object` 는 `Object`. |
| 크기 (K) | `가변` (기본), `maxLength` 가 있으면 사용 |
| 데이터 (M) | 형식·유효값 정보만. `enum` 콤마 나열 → `format` → description 의 패턴. **`example` 값(구체 샘플)은 사용하지 않음**. 응답 envelope `code` 같이 관용적으로 쓰는 값(`200, 400, 401, …`)은 예외. |
| 비고 (N) | 필요한 보조 설명만 (예: 단위, 참고 사항). **응답 항목에는 필수 여부(`필수`)를 표기하지 않음** — 응답은 항상 서버가 채워 보내므로 의미가 적음. |

### 4.6 `설명` 영역 (예시 응답)

- 템플릿의 마지막 `설명` 라벨 행 + 1 칸에 다음 텍스트를 넣는다.
  ```
  서비스 리턴값: Response OK(200), BadRequest(400)

  예시 응답:
  <responses["200"].content["application/json"].example 또는 schema 의 example 값들로 합성한 JSON>
  ```
- example 이 없으면 `schema.properties.*.example` 을 조합해 합성. 합성도 어려우면 라벨만 남기고 본문은 비움.

## 5. 요약(첫) 시트

각 출력 xlsx 의 첫 시트 `요약` 에 해당 중분류 IF 목록을 표 형태로 둔다.

| 컬럼 | 값 |
| --- | --- |
| Interface ID | 정규화된 ID |
| Interface 명 | summary 에서 추출한 명칭 |
| Method/URL | `{METHOD} {path}` |
| 설명 | summary xlsx 의 `설명` |

## 6. 미발견 처리

- summary xlsx 에 있는데 어떤 JSON 에도 매칭되는 operation 이 없는 IF: 해당 시트는 헤더만 채우고 본문은 비움, 시트명 끝에 `(미구현)` suffix.
- JSON 에 있는데 summary xlsx 에 없는 IF: 경고 로그 + 별도 xlsx `_unmapped.xlsx` 에 모음.

## 7. 셀 스타일

- 템플릿 시트의 모든 셀 스타일(폰트, 정렬, 테두리, 배경색), 병합 셀, 행/열 크기를 그대로 복제.
- openpyxl `copy_worksheet` + 셀 단위로 `font/fill/border/alignment` 를 `copy.copy()` 한다 (openpyxl 의 깊은 복사 이슈 회피).

## 8. CLI 사용 예

```
python build_interface_xlsx.py \
  --summary Interface_summary.xlsx \
  --template Interface_template.xlsx \
  --json 카탈로그_채번.json 마켓플레이스_채번.json 품질검사_채번.json \
  --out ./output \
  [--simple-tree]
```

생성물 예:
```
output/
  PG 연동 체계 구축 (DTS-PGI).xlsx
  과금 체계 및 리워드 체계 고도화 (DTS-BRS).xlsx
  ...
  _unmapped.xlsx  (있을 때만)
```
