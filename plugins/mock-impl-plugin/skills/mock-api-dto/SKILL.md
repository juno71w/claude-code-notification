---
name: mock-api-dto
description: >
  API endpoint 가 이미 정의돼 있고 사용자가 화면 이미지(피그마, 디자인 캡처, UI 스크린샷)를 첨부하면서
  "이 화면대로 응답 DTO 만들자", "응답 구조 잡아줘", "필드 정리해줘", "데이터 모델 짜줘", "이 화면 API 응답 어떻게 할까"
  같은 요청을 보낼 때 즉시 트리거. 화면의 panel/카드 단위로 nested DTO 를 묶고 @field:Schema · 도메인 enum ·
  Instant 컨벤션을 강제하기 위한 워크플로우. mock API 작업의 1단계로, 사용자가 이미지를 보여주는 거의 모든
  상황에서 우선 사용한다. mock-api-impl, mock-api-expand 와 짝을 이루는 DTO 설계 단계.
---

# 이미지 → DTO 설계

endpoint 는 이미 살아 있고, 화면에 맞춰 응답 본문만 새로 만드는 좁은 작업에만 쓴다.
신규 endpoint 설계 · DB 스키마 변경 · 비즈니스 로직 작성은 이 스킬의 범위 밖이다.

## 사전 확인

- 이미지가 어떤 endpoint 와 연결되는지 사용자에게 확인. `openapi.local.yml`, 같은 도메인 컨트롤러 / 기존 DTO 를
  먼저 훑어 재사용 가능한 자산이 있는지 파악한다. 도메인 enum / 모델은 가능하면 신규 작성보다 재사용을 택한다.
- URL 자체가 바뀌어야 할 것 같으면 임의로 바꾸지 말고 멈춰서 사용자에게 경고. 주소 변경은 항상 사용자 결정.
  - 명백한 영어 철자 오타(예: `approaval` → `approval`)도 같은 규칙으로 다룬다 — 발견 시 자동 보정하지 말고
    사용자에게 보고한 뒤 승인을 받는다. 보정 시 `openapi.local.yml` 과 controller `@*Mapping` 을 함께 갱신한다.
- 화면이 본문 + 사이드바 식으로 둘 이상 panel 로 나뉘어 있으면 각각이 별도 endpoint 인지 확인. 한 응답에 합칠지
  분리할지 먼저 결론을 내고 진행한다.

## 시각 블록 → 중첩 DTO 매핑

이미지의 박스/카드 하나 = nested data class 하나로 본다. 박스 안 라벨이 그대로 필드명 후보가 된다.
한 박스에 항목이 너무 많으면 평탄화하지 말고 의미 단위(요청 정보, 결제 정보, 진행 단계 등)로 한 번 더 묶는다 —
화면 그루핑과 응답 그루핑이 일치할수록 프론트 매핑이 단순해진다.

표시되지 않은 식별자/내부 필드를 추측해서 끼워 넣지 않는다. 화면에 보이지 않는 항목은 기본적으로 응답에 포함하지
않고, 표시 정책에 정말 필요한 보조 필드(타임존 등)만 명시적으로 추가한다.

depth = 2 까지만 추가한다.
## 컨벤션

- 외곽 응답 클래스 명: `<Feature><Purpose>Response`. 내부 nested data class 는 도메인 어휘를 그대로 사용.
- 필드: camelCase. nullable 은 화면에서 "—" / "미완료" / "미결제" 등으로 표현되는 항목에만 허용.
- 모든 필드에 `@field:Schema(description, example)`. example 은 시드 데이터의 실제 표시값과 일치시킨다.
  Swagger example 이 시드와 어긋나면 프론트 입장에선 거짓 문서가 된다.
- enum 신규 정의가 필요하면 프로젝트 표준 패턴 (`val code: Byte` 생성자 + `companion object { fun fromCode }`)을
  그대로 따른다. 화면이 정렬된 순서로 단계/상태를 보여주면 enum 정의 순서를 화면 순서에 맞춘다.
- 시간 필드는 표시 형식과 무관하게 `Instant`(UTC) 로 받고, 표시 정책은 별도 `timezone: Timezone` 필드로 노출.
- 비어 있을 수 있는 컬렉션은 `List<T>`(빈 리스트 허용). nullable collection 은 만들지 않는다.

## 검증

DTO 작성/수정 후 반드시 한 번에:

```
./gradlew spotlessApply compileKotlin --quiet
```

ktlint 가 줄 길이를 자동 정리하므로 example 문자열이 길어도 별도로 손볼 필요 없다.
컴파일과 ktlint 가 모두 통과해야만 사용자에게 완료 보고한다. 통과 후 자동으로 커밋하지 않고,
"커밋할까요?" 확인을 받는다.

## 다음 단계

DTO 가 정해졌다면 mock 시드를 채울 시점이다. `mock-api-impl` 스킬로 넘어가도록 사용자에게 안내한다.
mock 응답이 화면 요구사항의 기준 계약이 되므로, 이후 실제 DB 구현으로 전환할 때는 이 DTO 와 화면 grouping 을 `impl-api-schema` 의 ERD 입력으로 사용한다.
