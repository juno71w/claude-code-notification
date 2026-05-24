---
name: impl-api-green
description: >
  impl-api-red 가 남긴 RED 테스트를 ServiceImpl/RepositoryImpl/mapper 구현으로 GREEN 으로 만든다.
  관련 repository integration 테스트와 E2E 를 함께 GREEN 으로 만들고, 필요한 최소 회귀 시나리오만 보강한다.
  새 unit 케이스 추가나 인터페이스 변경은 원칙적으로 impl-api-red/iface 로 되돌아갈 신호다.
  "GREEN", "impl 채워줘", "RED 풀어줘", "통합 테스트", "회귀" 요청에 사용한다.
---

# RED → GREEN + 회귀 확장

4단계 파이프라인의 마지막 단계다. outside-in 으로 작성된 unit, repository integration, E2E 를 가장 좁은 실패부터 차례로 GREEN 으로 만든다.

## 사전 조건

- `./gradlew test --tests "*<Feature>ServiceImplTest"` 가 RED 인지 확인한다.
- `./gradlew integrationTest --tests "*<Feature>RepositoryIntegrationTest"` 가 RED 인지 확인한다.
- `./gradlew e2eTest --tests "*<Feature>E2ETest"` 가 RED 인지 확인한다.
- 일부 테스트가 이미 GREEN 이어도 이전 구현, DTO/controller-only 동작, no-op stub 때문이면 허용한다. 구현을 깨도 실패하지 않는 느슨한 단정이면 `impl-api-red` 로 되돌린다.
- 골드 스탠다드 도메인의 ServiceImpl, RepositoryImpl, mapper, integration test 패턴을 읽는다.
- 구현 전에 [green-implementation-conventions.md](references/green-implementation-conventions.md) 를 읽고, inquiry 도메인의 테스트 코드가 요구하는 책임 경계를 기준으로 삼는다.

## 1단계: 기존 RED GREEN

- 가장 단순한 happy path unit 하나를 고른다.
- ServiceImpl 은 트랜잭션 경계, repository 호출, 도메인 model 조율만 담당한다.
- 상태 전이, 불변식, 계산은 가능하면 domain model 메서드로 둔다.
- RepositoryImpl 은 jOOQ DSLContext 와 generated `Tables.*`/record 를 사용한다.
- mapper 의 record ↔ model 본문을 채운다.
- 단일 unit 테스트를 실행해 GREEN 확인 후 다음 케이스로 이동한다.
- 관련 unit 이 GREEN 이 되면 repository integration 을 GREEN 으로 만들고, 마지막에 E2E happy path 를 실행한다.

```bash
./gradlew test --tests "*<Feature>ServiceImplTest"
./gradlew integrationTest --tests "*<Feature>RepositoryIntegrationTest"
./gradlew e2eTest --tests "*<Feature>E2ETest"
```

## 구현 규칙

- ServiceImpl 은 `@Service` + `EgovAbstractServiceImpl()` 상속을 유지한다.
- 읽기 메서드는 `@Transactional(readOnly = true)`, 변경 메서드는 `@Transactional` 을 둔다.
- ServiceImpl 은 트랜잭션 스크립트 패턴으로 작성하지 않는다. 비즈니스 로직은 도메인 모델 안에 두고, ServiceImpl 은 orchestration 만 담당한다.
- 시간은 주입받은 `Clock` 의 `clock.instant()` 만 사용한다.
- repository 는 row-count, integrity, query predicate 같은 persistence 계약 실패를 도메인 예외로 변환한다. ServiceImpl 은 인증, 권한, 상태 정책 같은 orchestration 실패를 도메인 예외로 변환한다.
- controller 를 mock impl 에서 real impl 로 전환하거나 mock 파일을 삭제할 때는 사용자 확인을 받는다.
- RED 테스트를 의미 왜곡 없이 만족할 수 없으면 억지 구현하지 말고 `impl-api-iface` 또는 `impl-api-schema` 로 되돌릴 mismatch 를 보고한다.

## 2단계: 회귀 확장

- 1단계가 모두 GREEN 이 되기 전에는 시작하지 않는다.
- integration 테스트는 `src/integrationTest/.../<Feature>RepositoryIntegrationTest.kt` 에 둔다.
- integration 은 RepositoryImpl + mapper + DB 결합만 검증한다. ServiceImpl 분기를 반복 검증하지 않는다.
- 기존 Testcontainers/base class/cleanup 패턴을 재사용한다.
- enum byte 변환, DATETIME UTC 왕복, query predicate, soft-delete, guarded mutation 등 DB 결합 위험을 우선 검증한다.
- E2E 추가가 필요하면 우선순위는 보호 endpoint 의 인증 실패, 사용자 소유 리소스의 ownership 실패, workflow 리소스의 invalid state, controller binding 위험이 큰 validation 실패 순서로 고른다.
- E2E 예외 매트릭스를 unit 과 중복해서 넓히지 않는다.

## 범위 밖

- RED 단계에서 합의하지 않은 unit 테스트 대량 추가
- service/repository 인터페이스 변경
- mock impl 임의 삭제
- unrelated refactor

## 최종 검증

```bash
./gradlew spotlessApply
./gradlew test integrationTest e2eTest
```

실패하면 가장 좁은 테스트로 되돌아가 원인을 분리한다.

## 종료

GREEN 전환 결과, 추가한 integration/E2E 케이스, 구현 파일 목록을 보고한다. 자동 커밋/푸시는 하지 않는다.
