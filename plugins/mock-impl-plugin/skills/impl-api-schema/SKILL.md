---
name: impl-api-schema
description: >
  mock controller/DTO 가 준비된 도메인을 실제 DB 구현으로 옮기는 첫 단계.
  ERD 를 확정하고 Flyway 마이그레이션 SQL 을 작성한 뒤 generateJooq 까지 통과시킨다.
  service/repository 인터페이스, 테스트, 구현은 후속 impl-api-* 스킬 범위다.
  "테이블부터", "ERD", "Flyway", "mock 말고 실제 DB" 요청에 사용한다.
---

# 응답 DTO → ERD + Flyway

4단계 파이프라인의 1단계다. 목표는 후속 단계가 의존할 테이블 스펙과 jOOQ generated 클래스를 만드는 것.

## 사전 조건

- 대상 도메인의 controller 와 request/response DTO 를 확인한다. 없으면 `mock-api-dto` 또는 `mock-api-impl` 로 돌린다.
- 골드 스탠다드 도메인을 사용자에게 한 번만 묻는다. 답이 없으면 최근 마이그레이션 중 가장 가까운 도메인을 골라 패턴을 따른다.
- 같은 도메인의 기존 마이그레이션이 있으면 ALTER, 없으면 init 마이그레이션으로 간다.

## 작업

- DTO 의 nested `List<T>` 는 1:N 자식 테이블 후보로 본다.
- 시간 필드는 `DATETIME` UTC 저장. `Instant` DTO 필드 하나당 DB 컬럼 하나로 대응한다.
- FK 는 `<referenced_table>_id BIGINT NOT NULL` 형태를 기본으로 하되, 기존 도메인 컨벤션을 우선한다.
- audit 컬럼(`created_at`, `updated_at`) 포함 여부와 타입은 골드 스탠다드 도메인을 따른다.
- Flyway 파일은 기존 repo 구조를 우선한다. 독립 feature 는 `src/main/resources/db/migration/<feature>/V<n>__<feature>_init.sql`, 상위 bounded context 안의 기능이면 해당 context 디렉터리(예: `support`)에 둔다.
- 버전 번호는 선택한 migration 디렉터리의 마지막 번호 +1 로 잡는다.
- MariaDB 11 기준으로 snake_case, ENGINE/CHARSET, 코멘트 스타일은 기존 migration 을 본뜬다.

## Enum 컬럼

- enum 은 MariaDB native `ENUM` 이 아니라 `SMALLINT` 로 저장한다.
- 도메인 enum 은 `enum class Foo(val code: Byte)` + `fromCode(code: Byte?): Foo` 컨벤션을 전제로 한다.
- 컬럼 코멘트에 enum 출처를 남긴다. 예: `상태 (FooStatus.code)`.
- jOOQ Converter 와 `forcedType` 등록은 `impl-api-iface` 범위다. 여기서는 DB 컬럼 타입만 확정한다.
- 기존 native ENUM 을 ALTER 해야 하고 실데이터가 있으면 ordinal 변환 위험을 사용자에게 먼저 알린다.

## 범위 밖

- service/repository 인터페이스 작성
- mapper, converter, forcedType 작성
- 테스트 작성
- 인덱스/제약 최적화에 가까운 튜닝

## 검증

```bash
./gradlew generateJooq
```

통과 후 generated table 의 컬럼명과 타입만 가볍게 확인한다.

## 종료

만든 SQL 파일과 핵심 테이블/컬럼을 1~2줄로 보고한다. 자동 커밋은 하지 않는다. 다음 단계는 `impl-api-iface`.
