# mock-impl-plugin

Spring + Kotlin 도메인 API 의 **Mock → 실제 구현** 작업 흐름을 묶은 스킬 플러그인.

## Mock 단계 (Controller prefix `_`)

| 스킬 | 역할 |
| --- | --- |
| `mock-api-dto` | 화면 이미지 → panel 단위 nested 응답 DTO 설계 |
| `mock-api-impl` | DTO 로 mock 서비스 구현 (`EgovAbstractServiceImpl` + 시드 2~3) |
| `mock-api-expand` | 시드 10건+ 매트릭스 확장, helper 추출 |

## 실제 구현 단계 (impl-api)

| 스킬 | 역할 |
| --- | --- |
| `impl-api-schema` | ERD + Flyway + `generateJooq` |
| `impl-api-iface` | service/repository 인터페이스 + KDoc + TODO stub |
| `impl-api-red` | E2E 1개 + ServiceImpl unit + repository integration RED (outside-in) |
| `impl-api-green` | RED 를 GREEN 으로 + 최소 회귀 보강 |
| `impl-api-orchestrate` | schema → iface → red → green 4단계 풀스택. `temp/<domain>.md` 로 세션 복원 |

## 전제

Spring Boot + Kotlin + jOOQ + Flyway, `EgovAbstractServiceImpl` 패턴. Controller prefix: `_` = mock, `__` = 실제 구현.
