---
name: mock-api-impl
description: >
  DTO 설계가 끝났고 이제 해당 endpoint 를 동작시킬 mock 서비스 구현체를 만들어야 할 때 쓴다.
  사용자가 "mock 서비스 구현해줘", "이 DTO 로 mock 만들자", "구현체 작성", "응답 시드 박아줘",
  "controller 가 비어 있으니 채워줘" 같은 요청을 하면 즉시 트리거. 적은 수(2~3 건)의 시드로 우선 컴파일/구조부터
  맞추는 단계이며, 데이터 다양화/케이스 확장은 mock-api-expand 의 책임이라 이 단계에서는 의도적으로 다루지 않는다.
  Spring + Kotlin + EgovAbstractServiceImpl 패턴 강제.
---

# DTO → mock service 구현

이 스킬은 "DTO 가 확정된 endpoint 에 대해 in-memory 시드 기반 mock 서비스 구현체를 만든다"는 단일 작업만 다룬다.
시드 다양화 · 데이터 매트릭스 확장 · helper 함수 분리는 의도적으로 다루지 않는다 (그건 mock-api-expand 의 영역).

## 사전 확인

- 대상 service interface 가 존재하는지, 메서드 시그니처가 DTO 와 일치하는지 확인. 인터페이스가 없으면 먼저 만든다.
- 같은 도메인에 이미 다른 mock 구현체가 있는지 본다. 있으면 그 패턴/import 위치를 그대로 따른다.
- 도메인 BusinessException(`<Feature>BusinessException` sealed class) 과 not-found 변형이 이미 있는지 확인. 없으면
  사용자에게 한번 더 묻고 추가한다 — 도메인 예외는 이 스킬이 단독으로 신설할 대상이 아니다.

## 위치와 골격

- 파일 경로: `domain/<feature>/service/mock/Mock<Feature>ServiceImpl.kt`
- 클래스 골격: `@Service` 가 붙은 `EgovAbstractServiceImpl()` 상속 + 도메인 service 인터페이스 구현.
- 시드는 클래스 프로퍼티의 `Map<Long, Mock<Feature>>` 한 곳에 모은다. 외부에서 들어오는 ID 로 바로 lookup 하고,
  미존재 시 도메인 NotFoundException 을 던진다.
- 시드 ID 는 1, 2, 3 처럼 사람이 외우기 쉬운 작은 정수로 시작. 2001, 8420 같은 임의 숫자는 디버깅/Swagger try-out
  과정에서 마찰을 키운다.

## 시드 작성 원칙

- 이번 단계의 목표는 "컴파일이 되고, Swagger 에서 한 번 호출해보면 화면이 그려진다" 까지다. 케이스 다양성(상태 enum
  전수, 결제 상태 조합 등)은 다음 스킬에서 다룬다.
- 시드 2~3건이면 충분. 그 중 하나는 사용자가 첨부한 이미지의 실제 값과 정확히 일치시킨다 — Swagger example,
  프론트 mocking, QA 시나리오가 모두 그 시드를 기준으로 정렬되기 때문이다.
- 시간 필드는 `Instant.parse("...Z")` 로 고정 값 시드. `Instant.now()` 절대 사용 금지(테스트가 흔들린다).
- 화면에 안 보여도 응답에 들어가는 보조 필드(타임존 등)는 기본값을 활용해 간결하게.

## 검증

작성 후:

```
./gradlew spotlessApply compileKotlin --quiet
```

가능하면 `./gradlew bootRun` 로 띄워 Swagger 에서 endpoint 를 직접 호출해보고 응답이 채워지는지 확인하길 권장.
컴파일 통과 후 자동 커밋하지 말고, 사용자에게 커밋 여부를 묻는다.

## 다음 단계

골격과 한두 건의 시드가 안정화되면 데이터 다양성을 채워야 할 시점이다. `mock-api-expand` 스킬로 넘어가
상태 enum × 단계 × 결제 조합을 매트릭스로 펼친다.
mock 이 충분히 화면 계약을 설명하고 실제 DB 구현으로 넘어가려면 `impl-api-schema` 로 전환한다. 이때 기준 자료는 확정된 DTO, controller endpoint, mock seed 의 상태/단계/관계 규칙이다.
