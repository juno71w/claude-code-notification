# 상태 메모 템플릿

`impl-api-orchestrate` 에서 `temp/<domain>.md` 를 만들 때 이 형식을 사용한다. 본문은 한글로 작성하고, 코드 식별자/명령어/파일 경로/enum 값은 원문을 유지한다.

```markdown
# impl-api 오케스트레이션: <domain>

## 현재 상태

- Domain: <domain>
- Domain path: <path-or-tbd>
- Current step: schema | iface | red | green | review | paused | done
- Current scenario: <scenario-or-tbd>
- Blocked: no | yes - <reason>
- Last updated: <YYYY-MM-DD HH:mm KST>

## 워크플로우

- [ ] 사전 정렬: 도메인/경로/controller/DTO/mock service 확인
- [ ] schema: ERD + Flyway + generateJooq
- [ ] schema review: 차단/권장/OK 재분류 및 사용자 승인
- [ ] iface: service/repository 인터페이스 + TODO stub
- [ ] iface review: 차단/권장/OK 재분류 및 사용자 승인
- [ ] red-green scenario 1: <scenario>
- [ ] red 1: E2E 1개 + 관련 ServiceImpl unit + repository integration
- [ ] red 1 review: outside-in 범위, 충분성 판단, RED/통과 사유 및 사용자 승인
- [ ] green 1: unit/integration/E2E GREEN + 최소 회귀 보강
- [ ] green 1 review: 검증 결과 및 다음 반복 결정
- [ ] 종료: 파일 묶음과 추천 커밋 단위 요약

## 결정 사항

- <YYYY-MM-DD HH:mm KST> - <decision>

## 산출물

- <path> - <description>

## 검증

- <command> - <result>

## 재개 메모

- Next action: <next-action>
- Open questions: <questions-or-none>
```
