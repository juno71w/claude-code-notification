---
name: impl-api-orchestrate
description: >
  Controller + mock 만 있는 도메인을 impl-api-schema → impl-api-iface → impl-api-red → impl-api-green 순서로 끝까지 진행한다.
  red-green 은 사용자와 합의한 시나리오 단위로 반복 수행하며, 각 반복 사이에 산출물 검토와 사용자 승인 게이트를 둔다.
  사용자가 인자로 전달한 프로젝트 도메인 이름으로 temp/<domain>.md 메모 파일을 만들어 세션 복원 상태를 관리한다.
  단일 단계만 요청받으면 해당 impl-api-* 스킬을 사용한다.
  "처음부터 끝까지", "1~4 다", "impl-api 풀스택", "전체 파이프라인" 요청에 사용한다.
---

# impl-api 파이프라인 오케스트레이터

4단계 전체를 한 도메인에 적용할 때만 쓴다. schema/iface 는 순차로 한 번 정렬하고, red-green 은 사용자와 합의한 시나리오 단위로 반복한다.
각 단계의 실제 작업 규칙은 해당 sub-skill 이 진실이다.

## 순서

1. `impl-api-schema`: ERD + Flyway + generateJooq
2. `impl-api-iface`: service/repository 인터페이스 + TODO stub
3. `impl-api-red`: 다음 시나리오의 E2E 1개 + 관련 ServiceImpl unit + repository integration RED
4. `impl-api-green`: 해당 unit/integration/E2E 를 GREEN 으로 전환 + 필요한 최소 회귀 보강
5. 추가 시나리오가 남아 있으면 3~4 를 반복한다.

## 사전 정렬

- 대상 도메인 이름과 경로를 확인한다.
- 사용자가 도메인 인자를 줬으면 프로젝트 루트의 `temp/<domain>.md` 를 상태 메모 파일로 사용한다.
- 도메인 인자가 없으면 작업을 시작하기 전에 도메인 이름을 먼저 확인한다.
- controller, DTO, mock service 가 실제로 있는지 확인한다.
- 골드 스탠다드 도메인을 한 번만 정하고 모든 단계에 같은 기준으로 전달한다.
- 사용자의 도메인 결정사항은 상태 메모 파일에 한 줄씩 누적한다.

## 상태 메모

- 목적은 세션이 끊겨도 `temp/<domain>.md` 만 읽고 현재 워크플로우 상태를 복원하는 것이다.
- 오케스트레이션 중 생성/수정하는 `.md` 문서는 한글로 작성한다. 코드 식별자, 명령어, 파일 경로, enum 값은 원문을 유지한다.
- 프로젝트 루트에 `temp` 디렉터리가 없으면 생성한다.
- 파일 이름은 사용자가 입력한 도메인 이름을 기준으로 하되, 경로 구분자나 공백은 `-` 로 치환한다.
- 이미 상태 메모 파일이 있으면 먼저 읽고, 체크리스트와 최근 메모를 기준으로 이어서 진행한다.
- 새 파일을 만들 때는 `references/state-memo-template.md` 를 읽고 그 형식을 사용한다.
- red-green 반복이 추가될 때마다 `red-green scenario N`, `red N`, `green N` 체크 항목을 추가한다.
- 단계 시작 시 `Current step`, `Current scenario`, `Blocked`, `Last updated`, `Next action` 을 갱신한다.
- 단계 완료 또는 사용자 승인 직후 관련 체크박스를 완료 처리하고 산출물/검증/결정을 기록한다.

## 단계 게이트

각 단계마다 다음 순서로 진행한다.

1. 해당 sub-skill 을 적용한다.
2. 산출물, 검증 결과, 다음 단계 차단 여부를 직접 리뷰한다.
3. 사용자가 서브에이전트/병렬 리뷰를 명시적으로 요청한 경우에만 별도 에이전트 리뷰를 위임한다.
4. 리뷰 결과를 `차단`, `권장`, `OK` 로 재분류해 사용자에게 보여준다.
5. 사용자에게 `진행`, `수정`, `중단` 중 결정을 받는다. 자동으로 다음 단계로 넘어가지 않는다.
6. 결정과 피드백을 상태 메모 파일에 반영한다.

## red-green 반복 규칙

- schema/iface 가 확정된 뒤 사용자와 다음 구현 시나리오를 하나 고른다.
- 선택한 시나리오마다 `impl-api-red` → 리뷰/승인 → `impl-api-green` → 리뷰/승인 순서로 진행한다.
- GREEN 완료 후 남은 핵심 시나리오가 있으면 다음 red-green 반복을 제안한다.
- 새 시나리오가 기존 인터페이스로 표현되지 않거나 스키마 변경이 필요하면 반복을 멈추고 필요한 이전 단계로 돌아간다.
- 반복마다 RED/GREEN 산출물, 검증 결과, 다음 반복 차단 여부를 상태 메모 파일에 남긴다.

## 차단 기준

- 다음 단계 진입을 실제로 막는 컴파일/테스트/마이그레이션 실패
- jOOQ 생성 실패 또는 잘못된 table/column 타입
- 인터페이스가 RED 테스트의 mock 표면으로 쓰기 어려운 경우
- RED 테스트가 production 경로를 타지 않거나 구현을 깨도 실패하지 않는 경우
- GREEN 이후 unit/integration/E2E 가 구현 책임을 분리하지 못하는 경우
- GREEN 구현이 도메인 규칙을 서비스 메서드 절차 흐름에 몰아넣는 트랜잭션 스크립트 패턴으로 보이는 경우

## 단계별 리뷰 포커스

- schema: NULL, FK, enum 저장 방식, migration version, generated jOOQ 타입
- iface: jOOQ 타입 누출, YAGNI 메서드, DTO 반환, TODO stub 상태
- red: 인터뷰로 고른 E2E 1개, 관련 unit/integration 범위, 기존 E2E 충분성 판단, RED/통과 사유의 타당성
- green: unit → repository integration → E2E 순차 GREEN, Clock, 예외 책임 분리, fixture 사용, 트랜잭션 스크립트 패턴 여부

## 중단과 재개

- 중단 시 상태 메모 파일을 최신화하고, 산출물 목록, 검증 상태, 재개할 sub-skill 을 보고한다.
- 재개 시에는 먼저 상태 메모 파일을 읽고 체크리스트의 첫 미완료 항목과 `Next action` 을 기준으로 진행한다.
- 상태 메모 중 프로젝트 전반에 반복될 규칙만 사용자에게 메모리 저장 여부를 묻는다.
- 한 도메인/한 PR 한정 결정은 메모리 저장을 제안하지 않는다.

## 종료

4단계 완료 후 파일 묶음과 추천 커밋 단위를 요약한다. 자동 커밋/푸시는 하지 않는다.
