---
name: impl-api-iface
description: >
  Flyway 마이그레이션과 jOOQ generated 클래스가 준비된 도메인에서 service/repository
  인터페이스, KDoc 계약 문서, TODO stub 을 만든다. 목적은 impl-api-red 가 mock 할 표면을 정의하는 것.
  실제 구현, mapper 본문, 테스트 작성은 범위 밖이다.
  "인터페이스", "repository 추상", "service 시그니처", "jOOQ 연결 자리" 요청에 사용한다.
---

# ERD → service/repository 인터페이스

4단계 파이프라인의 2단계다. 컴파일은 통과하지만 real impl 호출은 `TODO()` 로 실패하는 상태가 정상이다.

## 사전 조건

- `./gradlew generateJooq` 가 통과하는지 확인한다.
- 대상 테이블의 jOOQ `Tables.*` 클래스가 생성돼 있는지 확인한다.
- 골드 스탠다드 도메인과 기존 service/repository 패턴을 먼저 읽는다.
- 도메인 `BusinessException` / `ErrorCode` 가 이미 있는지 확인한다.

## Service 인터페이스

- 위치: `domain/<feature>/service/<Feature>Service.kt`.
- mock 단계에서 이미 있으면 새로 만들지 말고 시그니처만 점검한다.
- 신규 real 구현 표준은 controller DTO 가 아니라 도메인 model 반환이다. 페이징은 `Page<DomainModel>` 표준을 따른다.
- 단, mock/controller 계약이 이미 DTO 반환으로 굳어 있고 변경하면 controller/Swagger/프론트 계약까지 흔들리면 이 단계에서 억지로 바꾸지 않는다. DTO 반환 유지 사유를 보고하고, mapper/assembler 책임을 `impl-api-green` 에서 분리하도록 남긴다.
- 메서드명은 유스케이스 중심으로 둔다. CRUD 단어는 도메인 의미가 분명할 때만 쓴다.
- 인터페이스와 각 public 메서드에 KDoc 을 추가한다. "무엇을 보장하는 계약인지"를 쓰고 구현 방식은 쓰지 않는다.
- KDoc 에는 성공 결과, 주요 예외, 권한/상태 전제, 시간 의존 조건이 있으면 포함한다.

## Repository 인터페이스

- 위치: `domain/<feature>/repository/<Feature>Repository.kt`.
- `DSLContext`, `Record`, `SelectConditionStep` 등 jOOQ 타입을 인터페이스에 노출하지 않는다.
- service 가 실제로 필요한 단위만 추가한다. 미래 사용을 예상한 메서드는 만들지 않는다.
- 반환/입력 타입은 도메인 model 또는 primitive/id 값으로 유지한다.
- 메서드 KDoc 은 조회/저장 조건과 없을 때의 반환 규칙(null, empty list, 예외 없음)을 명확히 적는다.
- DB 테이블명, jOOQ DSL, 인덱스 같은 구현 세부사항은 KDoc 에 쓰지 않는다.

## Mapper

- 위치: `domain/<feature>/mapper/<Feature>RecordMappingExtensions.kt`.
- jOOQ record ↔ domain model 확장 함수 시그니처만 만든다.
- 본문은 `TODO("impl-api-green 에서 구현")` 로 둔다.

## Enum Converter

- `impl-api-schema` 에서 `SMALLINT` enum 컬럼을 만들었다면 Converter 와 `forcedType` 을 이 단계에서 추가한다.
- Converter 는 `Converter<Short, Foo>` 형태로 `Foo.fromCode(it.toByte())` 와 `foo.code.toShort()` 를 연결한다.
- `build.gradle` 의 jOOQ `forcedTypes` 는 테이블+컬럼 정확 매칭 regex 로 등록한다. 예: `tb_foo\\.status`.
- 등록 후 `./gradlew generateJooq` 를 다시 실행해 generated field 가 enum 타입으로 바뀌었는지 확인한다.

## Stub 구현체

- 위치: `service/impl/<Feature>ServiceImpl.kt`, `repository/impl/<Feature>RepositoryImpl.kt`.
- ServiceImpl 은 `@Service` + `EgovAbstractServiceImpl()` 상속을 지킨다.
- 모든 메서드 본문은 `TODO("impl-api-green 에서 구현")` 한 줄로 둔다.
- 기존 `Mock<Feature>ServiceImpl` 과 controller 주입은 임의로 바꾸지 않는다.

## 범위 밖

- repository 쿼리 구현
- mapper 본문 구현
- unit/E2E/integration 테스트 작성
- mock service 삭제 또는 controller real impl 전환

## 검증

```bash
./gradlew spotlessApply compileKotlin --quiet
```

## 종료

만든 파일 목록과 TODO 상태를 보고한다. 다음 단계는 `impl-api-red`.
