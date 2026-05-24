---
name: impl-api-red
description: >
  도메인 API 구현 전후 언제든 실행 가능한 outside-in 패턴 구현 스킬이다.
  사용자와 짧게 인터뷰해 가장 가치 있는 E2E 시나리오 1개를 고르고,
  그 E2E 를 지탱하는 ServiceImpl unit 테스트와 repository integration 테스트를 작성한다.
  이미 같은 위험을 충분히 덮는 E2E 가 있으면 새 테스트 작성을 반려하고 근거를 보고한다.
  "테스트 먼저", "RED", "outside-in", "TDD", "E2E 부터" 요청에 사용한다.
---

# 인터뷰 → E2E 1개 → 관련 unit/integration

이 스킬은 outside-in 패턴을 구현한다. 도메인에서 가장 가치 있는 HTTP 사용자 흐름 1개를 바깥 경계(E2E)에서 먼저 고정하고, 그 흐름이 의존하는 service 규칙과 repository 영속성 계약을 안쪽 테스트로 내려가며 고정한다.

이 스킬은 구현 전 RED 단계뿐 아니라 구현 도중/구현 후 회귀 보호망 보강에도 실행할 수 있다. 단, 이미 같은 사용자 흐름과 위험을 충분히 덮는 E2E 가 있으면 새 E2E 를 만들지 말고 반려한다.

## 사전 자료 수집

사용자에게 묻기 전에 코드에서 읽을 수 있는 사실을 먼저 확인한다.

- `service/mock/Mock<Feature>ServiceImpl.kt`: seed, 상태 전이, 필터, 멱등 규칙
- `controller/web/*Controller.kt`: endpoint, swagger 설명, 권한 힌트
- `controller/dto/request|response/*.kt`: 필드, validation, 예시
- `exception/*ErrorCode.kt`, `*BusinessException.kt`: 기존 도메인 예외
- `model/*Status.kt`, `*Type.kt`: enum 값과 전이 후보
- 해당 도메인 Flyway SQL: NULL, 타입, FK, unique, 기본값
- 인접 E2E/unit/integration 테스트: base class, 인증 fixture, cleanup 패턴, Testcontainers 설정
- 현재 도메인의 기존 E2E: 새 시나리오가 중복인지 판단

관련 Notion 도구가 있으면 도메인명으로 검색하고, 발견한 기획 내용이 코드와 충돌하면 사용자에게 확인한다.

## E2E 충분성 판단

기존 E2E 를 먼저 훑고 아래 조건을 모두 만족하면 새 테스트 작성을 반려할 수 있다.

- 사용자가 요청한 핵심 사용자 흐름과 같은 endpoint 조합을 이미 검증한다.
- HTTP status, 응답 핵심 필드, DB side effect 중 회귀 위험이 큰 지점이 이미 검증된다.
- service unit 과 repository integration 이 같은 규칙을 더 낮은 레벨에서 보강한다.
- 새 테스트가 실패 원인 구분 없이 같은 wiring 만 반복할 가능성이 높다.

반려할 때는 “이미 덮는 테스트 파일/테스트명”, “덮는 계약”, “남은 공백이 있으면 대체로 추가할 unit/integration” 을 짧게 보고한다.

## 인터뷰

- 가장 중요한 사용자 흐름 1개를 고르기 위해 짧게 질문한다.
- 후보는 endpoint 단위가 아니라 사용자가 실제로 수행하는 흐름으로 잡는다. 예: “presigned 발급 → complete → 문의 등록”.
- 성공 조건, 실패 조건, 권한/상태 전제, 시간 의존 규칙을 확인한다.
- 코드에서 읽은 사실을 근거로 질문한다. 예: "mock 은 비공개 문의를 목록에서 제외하는데 real 도 유지할까요?"
- 답변끼리 충돌하면 즉시 짚고 최종 결정을 받는다.
- 확정된 E2E 1개와 관련 unit/integration 범위를 간단한 목록으로 정리해 사용자 확인을 받는다.

## E2E RED

- 위치: `src/e2eTest/kotlin/.../domain/<feature>/<Feature>E2ETest.kt`.
- 테스트 클래스 최상단 KDoc 에 이 E2E 가 어떤 사용자 흐름과 어떤 회귀 위험을 검증하는지 적는다.
- 합의한 사용자 흐름 1개만 작성한다. 단일 흐름 안에서 자연스럽게 이어지는 여러 HTTP 호출은 허용한다.
- 권한 실패, 비정상 상태, 예외 시나리오는 인터뷰에서 “핵심 사용자 흐름”으로 확정된 경우에만 E2E 로 둔다.
- 기존 E2E base, 인증 헬퍼, cleanup 방식을 재사용한다.
- JSON 요청은 기존 프로젝트 E2E 컨벤션을 따른다. 새 helper 를 만들기 전에 유사 테스트를 찾는다.
- 검증은 HTTP 상태, 응답 핵심 필드 1~3개, 필요한 DB side effect 정도로 제한한다.
- 테스트명은 기존 한글 backtick 컨벤션을 따른다.

## Unit 테스트

- 위치: `src/test/kotlin/.../domain/<feature>/service/impl/<Feature>ServiceImplTest.kt`.
- 테스트 클래스 최상단 KDoc 에 어떤 service 메서드/도메인 규칙을 검증하는 unit 테스트인지 적는다.
- JUnit 5 + mockito-kotlin 을 우선한다. 기존 도메인이 다른 패턴이면 그 패턴을 따른다.
- repository, mapper, 외부 client 는 mock 처리한다.
- `Clock` 은 `Clock.fixed(..., ZoneOffset.UTC)` 로 고정한다.
- E2E 흐름이 지나가는 service 메서드만 대상으로 한다.
- 해당 흐름의 happy path 1건과 핵심 예외/상태 분기 2~4건 정도를 기준으로 한다.
- 한 테스트는 한 규칙만 검증한다. 단정이 과하게 늘면 케이스를 나눈다.

## Integration 테스트

- 위치: `src/integrationTest/kotlin/.../domain/<feature>/repository/<Feature>RepositoryIntegrationTest.kt`.
- 테스트 클래스 최상단 KDoc 에 어떤 repository/DB 계약을 검증하는 integration 테스트인지 적는다.
- E2E 흐름이 의존하는 repository 메서드만 대상으로 한다.
- jOOQ, Flyway, converter, nullable/default/unique/FK 같은 DB 계약을 검증한다.
- Testcontainers, cleanup, seed 방식은 인접 integration 테스트를 재사용한다.
- service 규칙을 integration 에서 반복하지 않는다. DB 입출력 계약과 query 조건에 집중한다.

## 실행 확인

```bash
./gradlew test --tests "*<Feature>ServiceImplTest"
./gradlew integrationTest --tests "*<Feature>RepositoryIntegrationTest"
./gradlew e2eTest --tests "*<Feature>E2ETest"
```

구현 전이라면 실패하는 RED 가 정상이다. 구현 후 보강 목적이라면 통과해도 정상이다. 어느 경우든 테스트가 실제 production 경로를 타는지, mock/단정이 느슨하지 않은지 확인한다.

## 범위 밖

- ServiceImpl/RepositoryImpl/mapper 구현
- interface 시그니처 변경
- 인터뷰로 고른 1개 흐름과 직접 관련 없는 추가 E2E 시나리오 작성
- 광범위한 리팩터링이나 테스트 인프라 재설계

## 종료

작성/반려한 테스트 파일, 확정된 도메인 규칙, 실행 결과를 보고한다.

작성한 테스트는 `Unit`, `Integration`, `E2E` 로 나누고 테스트 하나당 한 줄로 요약한다. 각 줄에는 테스트명과 고정한 계약을 함께 적는다.

구현 전 실패 상태라면 다음 단계는 `impl-api-green`, 구현 후 통과 상태라면 회귀 보호망 보강 완료로 정리한다.
