---
name: hwpx-db-design
description: 체인포털/스마트엠투엠 표준 양식의 데이터베이스 설계서를 HWPX 로 작성·갱신할 때 사용. 입력은 `erd/*.dbml` (MySQL/MariaDB) 과 v1.2 baseline HWPX(`CPS-M2M-DB-001-...hwpx`), 출력은 시스템별 헤더 표 4종 + 테이블별 명세(상단 메타 + 컬럼 표 + audit 6행 + 인덱스 표) + ERD PNG 삽입이 완성된 HWPX. 사용자가 "DB 설계서 작성/갱신", "DBML 을 hwpx 에 옮겨줘", "카탈로그/품질검사/마켓플레이스 시스템 명세 채워줘", "ERD 다이어그램 셀에 넣어줘", "table id 부여", "셀 글자수 한도", "감리 산출물 양식" 같은 요청을 하면 즉시 트리거. 단순 hwpx 셀 한두 개 수정이 아니라 dbml 기반 다수 테이블·다수 시스템을 일관된 양식으로 옮겨야 하는 모든 상황이 본 스킬 범위. SKILL.md 안의 매핑 규칙(§4), audit 6행 부여(§5), 셀 한도 정책(§6), ERD 이미지 처리(§7), 검수 체크리스트(§9)를 반드시 따라 작성.
---

# HWPX 데이터베이스 설계서 작성 스킬

## 1. 목적과 적용 대상

체인포털·데이터유통시스템 계열 프로젝트의 **데이터베이스 설계서(HWPX)** 를 v1.2 표준 양식에 맞춰 자동·반자동으로 작성한다. 입력은 dbml(`erd/*.dbml`, `erd/*.md`) 의 컬럼·인덱스 정보, 출력은 `database_in_progress.hwpx` 같은 작업 사본의 표 채움이다.

본 스킬은 다음 시스템 패밀리를 다룬다 — 다른 시스템도 같은 양식을 따르는 한 그대로 재사용 가능하다.

- 카탈로그 (CTL) · MariaDB · `data_catalog`
- 품질검사 (DQA) · MariaDB · `data_quality_diagnosis`
- 마켓플레이스 (MKT) · MySQL · `data_marketplace`

> **트리거 신호**: "DB 설계서", "데이터베이스 설계서", "감리 산출물", "v1.2 양식", "CPS-M2M-DB-xxx", "TABLE ID 부여", "데이터베이스 정의 표", "접근 권한 표", "백업·복구 절차 표", "audit 6행", "셀 글자수 한도" 등.

## 2. 작업 흐름 (Phase 개요)

각 Phase 는 산출물이 검증 가능해야 한다. Phase 사이마다 `render_hwp_page` 로 페이지 캡처해 시각 검수한다.

| Phase | 내용 | 산출물 |
|---|---|---|
| 0 | 백업·구조 파악 (양식 hwpx 의 표 인덱스·셀 너비 추출) | `*.bak.YYYYMMDD-HHMMSS.hwpx`, 셀 한도 메모 |
| 1 | 2장(개요·설계·컨벤션) 갱신 | 2.2 테이블 설계 표, 2.2 ERD 요약 표, 2.3 컨벤션 표 갱신 |
| 2 | 시스템별 헤더 표 4종 채움 | 데이터베이스 정의 / 접근 권한 / 백업·복구 / 테이블 구성 |
| 3 | 시스템별 테이블 명세 작성 (테이블당 1 표) | 상단 메타 14행 + 컬럼 표 + audit 6행 + 인덱스 표 |
| 4 | ERD 이미지 보강·삽입 | `erd/<시스템>.png` 신규 export 후 3.1/4.1/5.1 표 ERD 셀에 삽입 |
| 5 | 자체 검수 | 페이지 캡처, 일관성·셀 한도 검증, 누락 컬럼/테이블 점검 |

Phase 0→5 를 시스템 단위로 묶어 (카탈로그 → 품질검사 → 마켓플레이스 순) 진행하면 중간 산출물이 검증 가능한 형태로 누적된다.

## 3. ID 체계와 메타 정책

### 3.1 TABLE ID

`CPS-TBL-<시스템코드>-<3자리 일련번호>` — 예: `CPS-TBL-CTL-001`. 시스템 코드는 위 §1 의 약어를 따른다. 일련번호는 **dbml 의 도메인 의존성 위상정렬** 순서로 부여한다 (마스터 → 트랜잭션 → 이력/매핑/알림). 단순 알파벳 순이 아님에 주의.

### 3.2 시스템 헤더 표 4종 (시스템 첫 페이지)

각 시스템 섹션(3·4·5장 …)의 첫 페이지에는 다음 4종 표가 v1.2 baseline 과 **셀 위치·셀 너비까지 일치**해야 한다.

1. **데이터베이스 정의 표** (6열 × 4행, 라벨+값 2단) — 기관명/부서명/적용업무/관련법령/DB명 + 구축일자/DBMS 설명/DBMS 정보/운영체제 정보/수집제외 사유 + ERD 다이어그램(이미지 셀) + Table(테이블 목록).
2. **접근 권한 및 통제 표** (4열) — 계정명/접근 권한/사용 주체/용도. 계정 명명: `<DB접두>_<시스템>_<용도>` (예: `dc_catalog_app`, `dc_catalog_admin`, `dc_catalog_user`).
3. **데이터 백업 및 복구 절차 표** (6열 × 2행) — 백업 대책/위치/복구 대책/절차/담당자/보존 기간. 전 시스템 공통값을 사용한다 (백업: 매년 1월 1일 전체 / 복구: mysqldump 파일 복원 / 보존: 10년).
4. **테이블 구성 표** (3열) — 구분 / 데이터베이스 / 테이블 목록. **variant B (구분 9226 / DB 8094 / 테이블 31135 HWPUNIT)** 로 통일한다. v1.2 의 variant A/B 혼재는 작성 누락이며 신규 문서는 B 로 맞춘다.

### 3.3 테이블 단위 메타 (전 테이블 기본값)

- `data 보존 기간`: 10년 (예외: 품질검사의 결과 테이블 일부는 작성 시 조정 가능)
- `data 백업 주기`: 1년
- 초기/증가/최대 예상 건수: dbml 에는 없는 정보 — `specs/` 또는 사용자 인터뷰로 확보. 미정이면 작성자에게 묻고 진행한다.

## 4. dbml → 양식 매핑 규칙 (핵심)

이 절은 **테이블 컬럼 표** 한 행을 dbml 한 줄에서 어떻게 만들어내는지 규정한다. 모든 시스템에 동일하게 적용한다.

| 양식 컬럼 | 변환 규칙 |
|---|---|
| `no` | 1부터 순서대로. dbml 정의 순서 유지 |
| `column name` | dbml 컬럼명 그대로 (영문) |
| `컬럼명` | dbml `note` 의 첫 의미어를 한글로. **한도 7자** (필요 시 약어) |
| `type` | enum 타입 → **`varchar`** 로 일괄 변환. char/varchar/text/bigint/int/tinyint/timestamp/date/json 은 dbml 그대로 |
| `length` | varchar(N)→N, char(N)→N, tinyint(1)→1, bigint/timestamp/text/int/json/date 는 공란. **enum → 50 일괄** |
| `PK` | PK 면 `PK`. PK 아닌 FK 면 `FK`. 둘 다 아니면 공란 (v1.2 컨벤션) |
| `NN` | dbml `[not null]` 이면 `Y`, 아니면 공란 |
| `Default` | `now()` / `CURRENT_TIMESTAMP` → `SYSDATE`, `ON UPDATE CURRENT_TIMESTAMP` → `AUTO UPDATE`, `increment` PK → `AUTO_INCREMENT`, null/미지정 → `NULL`, 그 외는 그대로 |
| `정의/설명` | dbml `note` 의 핵심 의미만. **한도 한글 6자**. enum 컬럼은 의미만 적고 값 목록은 미수록 |
| `참조테이블` | dbml `ref:` 의 **테이블명만** 적는다 (`tb_member.mbr_id` ❌ → `tb_member` ✅). `.컬럼명` 표기 금지 |
| `암호화` | 일괄 `해당없음`. 별도 암호화 대상은 작성 시 명시 |

### 4.1 인덱스 표 매핑

- 1행은 항상 `PRIMARY / PK / Unique / {PK 컬럼명}` 고정.
- dbml `indexes { ... }` 절을 2행부터 옮긴다.
  - `(col1, col2) [unique, name: 'ux_xxx']` → Index name=`ux_xxx` / Index type=`INDEX` / Unique=`Unique` / 구성 컬럼=`col1, col2`
  - `(col) [name: 'ix_xxx']` → Index name=`ix_xxx` / Index type=`INDEX` / Unique=`Non-Unique` / 구성 컬럼=`col`
- FK 컬럼에 대한 자동 인덱스는 **dbml 에 명시된 것만** 옮긴다. v1.2 가 `fk_xxx` 형태로 추가한 패턴은 그대로 따른다.

### 4.2 외부 참조 처리 (체인포털 `tb_member` 등)

체인포털 외부 DB의 테이블은 본 문서에 별도 정의 표로 수록하지 **않는다**. 본 시스템 테이블에서 FK 로 참조하는 컬럼은:

- `PK` 셀: `FK` (PK 이자 FK 면 `PK`)
- `참조테이블` 셀: 외부 테이블명만 (예: `tb_member`)
- `정의/설명` 셀: dbml `note` 의 의미만 (예: "구매자 FK")

## 5. Audit 6행 부여 정책

**일반 테이블** 끝에 다음 6행을 일괄 부여한다. (v1.2 패턴 — dbml 에 위 컬럼이 명시돼 있지 않더라도 본 문서에는 항상 기재한다)

| no | column name | 컬럼명 | type | length | PK | NN | Default | 정의/설명 | 참조테이블 | 암호화 |
|---|---|---|---|---|---|---|---|---|---|---|
| N-5 | created_at | 생성일시 | timestamp | | | Y | SYSDATE | 레코드 생성 | | 해당없음 |
| N-4 | created_by | 생성자ID | varchar | 50 | | | NULL | 생성자 ID | | 해당없음 |
| N-3 | updated_at | 수정일시 | timestamp | | | Y | AUTO UPDATE | 레코드 수정 | | 해당없음 |
| N-2 | updated_by | 수정자ID | varchar | 50 | | | NULL | 수정자 ID | | 해당없음 |
| N-1 | deleted_at | 삭제일시 | timestamp | | | | NULL | 삭제 일시 | | 해당없음 |
| N   | deleted_by | 삭제자ID | varchar | 50 | | | NULL | 삭제자 ID | | 해당없음 |

### 5.1 예외: append-only 테이블

다음 패턴의 테이블은 audit 6행 일괄 부여 대신 **dbml 에 실제로 존재하는 audit 컬럼만** 적는다 (대부분 `created_at` 1행만).

- 채팅 메시지 (`tb_chat_message`)
- 첨부파일 (`tb_application_attachment`, `tb_inquiry_attachment`)
- 오류 로그 (`tb_assessment_error`)
- 알림 (`tb_notification`)

판정 기준: dbml 상에 `updated_at`/`deleted_at` 이 없고, 도메인 자체가 "한번 쓰고 갱신 안 함" 이면 append-only.

## 6. 셀 글자수 한도 정책

**왜 중요한가**: HWPX 의 셀은 너비가 고정이라 한 줄 한도를 넘으면 줄바꿈되거나 인접 셀과 시각적으로 겹쳐 보인다. 무작정 dbml note 를 그대로 넣으면 표가 깨진다.

전체 한도는 `테이블_셀_글자수_가이드.md` (본 폴더 루트) 를 그대로 따른다. 핵심 위반 케이스와 대응:

| 셀 | 한도 | 흔한 위반 | 대응 |
|---|---|---|---|
| `column name` | 한글 9자 / 영문 19자 | `data_quality_diagnosis` (22자) | 줄바꿈 허용 |
| `컬럼명` | 한글 7자 | "단어-용어 매핑 ID" (10자) | 약어 또는 줄바꿈 |
| `Default` | 영문 14자 | `CURRENT_TIMESTAMP` (17자) | `SYSDATE` 로 치환 |
| `참조테이블` | 한글/영문 10자 | `tb_member.mbr_id` (16자) | 테이블명만 — `.컬럼명` 제거 |
| `정의/설명` | 한글 6자 / 영문 14자 | enum 값 나열 | enum 값은 미수록, 의미만 |
| 시스템 헤더 "계정명" | 영문 17자 | `dc_catalog_admin` (16자) | 가능 (15자 이하 권장) |
| 3.x DB정의 "구분" | 한글 5자 | "ERD 다이어그램" (8자) | 줄바꿈 허용 ("ERD\n다이어그램") |

### 6.1 한도 초과 시 우선순위

1. **약어** (예: `CURRENT_TIMESTAMP` → `SYSDATE`)
2. **줄바꿈 허용** (v1.2 가 받아들이는 부분 — 예: 백업·복구 표 거의 모든 셀)
3. **셀 분할 / 부록 분리** (예: enum 값 목록)

새 가이드를 만들거나 기존 가이드에 추가할 때는 `테이블_셀_글자수_가이드.md` 의 §2/§3 패턴을 따라 셀 너비(HWPUNIT) 와 권장 글자수를 함께 기재한다.

## 7. ERD 이미지 처리

### 7.1 PNG 생성

dbml 파일(`erd/*.dbml`, 또는 `erd/품질검사.md`) 을 dbdiagram.io 등에서 export 하여 `erd/<시스템>.png` 와 `erd/<시스템>.svg` 를 만든다. 본 폴더의 `erd/카탈로그.png` 가 참조 샘플.

PNG 가 너무 크면(>15MB) 가독성 위주로 다시 export 한다. 인쇄 기준 A4 가로 2/3 폭 정도가 적정.

### 7.2 ERD 셀 삽입

각 시스템의 **3.1 / 4.1 / 5.1 데이터베이스 정의 표** 의 `ERD 다이어그램` 셀에 PNG 를 삽입한다. 셀 너비(HWPUNIT)에 맞춰 width 지정.

도구: `mcp__hwp-mcp__insert_hwp_image` (target_cell=해당 셀, path=`erd/<시스템>.png`, width=셀 너비 −여백)

삽입 후 `mcp__hwp-mcp__render_hwp_page` 로 해당 페이지를 캡처해 크기·잘림 여부를 확인한다.

## 8. HWPX 편집 도구 사용 패턴

HWPX 편집은 전부 `mcp__hwp-mcp__*` 도구로 수행한다. 자주 쓰는 호출 패턴:

```text
# 구조 파악
mcp__hwp-mcp__get_hwp_info        (path)
mcp__hwp-mcp__get_hwp_page_def    — 페이지 방향·여백 확인
mcp__hwp-mcp__read_hwp_text       — 본문 텍스트 위치 찾기
mcp__hwp-mcp__read_hwp_tables     — 표 인덱스·셀 좌표·너비 확인

# 채움
mcp__hwp-mcp__set_hwp_cell_text          (table_index, row, col, text)
mcp__hwp-mcp__set_hwp_paragraph_text     (단락 ID, text)
mcp__hwp-mcp__append_hwp_table_row       (table_index)
mcp__hwp-mcp__insert_hwp_table           (행수, 열수, 삽입 위치)
mcp__hwp-mcp__insert_hwp_image           (path, target_cell, width)
mcp__hwp-mcp__apply_hwp_text_style       (굵게/색/크기)

# 검수
mcp__hwp-mcp__render_hwp_page            (page) — 페이지 캡처
mcp__hwp-mcp__render_hwp_all_pages       — 전체 점검
mcp__hwp-mcp__render_hwp_html            — HTML 변환 (재검수용)
```

### 8.1 안전장치

- 작업 시작 전 `cp <원본>.hwpx <원본>.bak.$(date +%Y%m%d-%H%M%S).hwpx` 로 백업.
- 표 인덱스는 본문 위치마다 다르다. 매번 `read_hwp_tables` 로 다시 확인하고 캐시한 인덱스를 그대로 쓰지 않는다 (행 추가·표 삽입 시 변동).
- `set_hwp_cell_text` 가 빈 셀에 들어가면 셀 스타일이 초기화되는 경우가 있다. 채움 후 `render_hwp_page` 로 폰트·정렬을 즉시 확인한다.

## 9. 자체 검수 체크리스트

작업 종료 전 다음 항목을 모두 통과해야 한다.

- [ ] 모든 테이블 상단 메타 14행이 채워졌는가 (시스템/서비스, 작성자, TABLE ID, table name, 테이블 명, 중요도, 초기/증가/최대 건수, 보존·백업 주기)
- [ ] 컬럼 표 모든 행에 PK/FK 표기가 일관되는가 (`PK`, `FK`, 공란 중 하나만)
- [ ] audit 6행이 일반 테이블에 모두 부여됐는가 (append-only 예외 테이블 제외)
- [ ] 외부 참조 컬럼의 `참조테이블` 셀이 테이블명만 적혀 있는가 (`.컬럼명` 없음)
- [ ] enum 컬럼은 `type=varchar`, `length=50` 으로 통일됐는가
- [ ] `Default` 셀에 `CURRENT_TIMESTAMP` 같은 한도 초과 값이 남아 있지 않은가
- [ ] 인덱스 표 1행이 `PRIMARY / PK / Unique / <PK 컬럼>` 고정인가
- [ ] 시스템별 헤더 표 4종 (DB 정의·접근권한·백업복구·테이블 구성) 이 채워졌는가
- [ ] 3.x/4.x/5.x 데이터베이스 정의 표 ERD 다이어그램 셀에 PNG 가 삽입됐는가
- [ ] 페이지 렌더링 결과(`render_hwp_page`) 상 셀이 잘리거나 인접 셀과 겹치지 않는가
- [ ] v1.2 baseline 의 페이지 방향(`landscape="WIDELY"`/`NARROWLY"`) 과 일치하는가

## 10. 산출물 경로 규약

본 폴더 기준 산출물 위치는 다음과 같다.

- 작업본: `database_in_progress.hwpx` (또는 본 작업용 신규 파일)
- 백업: `<원본>.bak.YYYYMMDD-HHMMSS.hwpx` (작업 폴더 또는 `work/`)
- 최종 산출: `CPS-M2M-DB-<NNN>-<문서명>.hwpx`
- ERD 자산: `erd/<시스템>.dbml` (또는 `.md`) + `erd/<시스템>.png` + `erd/<시스템>.svg`
- 셀 한도 가이드: `테이블_셀_글자수_가이드.md`
- 양식 가이드: `설계단계_감리_산출물_작성_가이드.md`

## 11. 범위 밖 (Out of scope)

- 1장 문서 개요 본문은 본 스킬에서 갱신하지 않는다 (v1.2 본문 유지 가정).
- 표지·사용권한·제·개정 이력은 별도 시점에 갱신.
- 실제 운영값(계정 비밀번호·구체 IP·실 운영자 이름) 은 placeholder 유지 — 인수 단계에서 운영팀이 채움.
- 데이터 마이그레이션·실 운영 모니터링·백업 자동화 등 운영 절차는 본 설계서 범위 밖.

## 12. 후속 스킬과의 관계

본 스킬은 산출물(HWPX)을 직접 편집한다. 사전 단계인 **설계(spec)** 와 **계획(plan)** 은 superpowers 의 `brainstorming` / `writing-plans` 에서 다루고, 실제 다수-task 실행은 `subagent-driven-development` / `executing-plans` 에 위임할 수 있다. 본 스킬은 그 plan 의 각 task 가 무엇을 어떻게 채워야 하는지에 대한 **도메인 규칙 사전** 역할이다.
