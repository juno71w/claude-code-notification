---
name: mock-api-expand
description: >
  mock 서비스 구현체에 시드가 한두 건만 박혀 있는 상태에서 데이터를 충분한 개수(10건 등)로 늘리고
  상태/단계/결제 조합을 매트릭스로 펼쳐야 할 때 쓴다. 사용자가 "데이터 10개로 늘려", "케이스 다양하게 추가",
  "시드 더 만들자", "여러 상태 조합 보고 싶어", "mock 채워줘" 같은 요청을 하면 즉시 트리거. 단순 복붙 확장이
  아니라, 반복 시드를 helper 함수로 추출해 가독성과 일관성을 동시에 끌어올리는 리팩터링까지 포함한다.
  mock-api-impl 의 후속 단계로, 컴파일 가능한 mock 골격이 이미 존재할 때만 의미가 있다.
---

# mock 시드 확장

이 스킬은 "이미 동작하는 mock 구현체에 시드를 늘리고 케이스를 다양화한다"는 작업만 다룬다.
구조 자체가 비어 있거나 DTO 가 미확정이면 mock-api-impl / mock-api-dto 로 먼저 돌아간다.

## 사전 정리: helper 추출

시드가 늘어나는 순간 단일 시드 작성 시점에 받아들였던 길고 평탄한 생성자 호출이 가독성을 무너뜨린다.
시드를 추가하기 전에 반드시 helper 함수를 먼저 추출한다 — 같은 인자 모양을 두 번 이상 쓰게 될 모든 nested 객체가
대상이다(예: 결제 정보, 신청 본문, 첨부 목록, 단계별 progress).

helper 의 시그니처는 "그 시드에서 케이스마다 달라지는 값" 만 인자로 받게 잡는다. 모든 case 가 공통인 값(예:
`DataType.FILE`, `Timezone.ASIA_SEOUL`)은 helper 안에 고정해 두고 노출하지 않는다 — 인자 폭증이 helper 의 가치를
지운다. 결제 정보처럼 "값 있음 / 값 없음" 두 모드가 명확하면 `purchaseInfo(...)` / `emptyPurchase(...)` 처럼
모드별 helper 를 따로 둔다.

## 케이스 매트릭스

10건 정도의 시드를 만들 때는 한 시드에 한 axis 만 다르게 두지 말고, 도메인의 핵심 enum 들을 교차로 덮는다.
대표 axis 예시: 응답 status enum 의 모든 값, 결제 상태(NONE/REQUESTED/COMPLETED/CANCELLED), 단계 진행 정도
(초기 / 중간 / 완료 / 취소·환불 분기), 카테고리 분포. axis 가 정해지면 시드 ID 와 상태를 표 형태로 정리해두고
사용자에게 보여주면 검토 시간이 짧아진다.

단계별 timestamp 처럼 nullable 이 줄지어 등장하는 필드는 `Map<Stage, String>` + `Stage.entries.map { ... }` 패턴으로
"도달한 단계만 timestamp 를 채워 넣고, 나머지는 자동으로 null" 이 되게 작성한다. 시드마다 다섯 줄씩 nullable 을
나열하는 것보다 의도가 훨씬 또렷이 드러난다.

## 시드 ID와 Swagger example

시드 ID 는 1,2,3... 식으로 단조 증가시키되, ID 1 자리에는 사용자가 처음 보여준 "기준 화면" 시드를 둔다.
DTO 의 `@field:Schema(example = ...)` 들도 ID 1 시드와 일치하도록 함께 갱신한다 — Swagger try-out 의 기본
프리셋이 ID 1 의 시드와 동일해야 프론트와의 합의가 깨지지 않는다.

## 검증

helper 추출 → 시드 채우기 → example 정렬을 마친 뒤:

```
./gradlew spotlessApply compileKotlin --quiet
```

ktlint 가 줄 길이와 들여쓰기를 잡아준다. 컴파일 통과 후 자동 커밋하지 않고 사용자에게 커밋 여부를 묻는다.
시드 표(ID × status × 진행 단계)를 답변에 포함하면 사용자 검수 비용이 크게 줄어든다.
mock seed 의 상태/단계/관계 매트릭스가 확정되면 실제 DB 구현의 요구사항 자료가 된다. 사용자가 mock 말고 실제 DB 구현을 원하면 `impl-api-schema` 로 넘어가 ERD/Flyway 를 시작한다.
