# GREEN 구현 컨벤션

골드 스탠다드는 inquiry 도메인의 테스트 코드다. 새 도메인을 GREEN 으로 만들 때는 먼저 아래 파일을 읽고 같은 책임 분리와 검증 밀도를 따른다.

규범으로 삼을 것은 책임 분리, 테스트 밀도, fixture 사용 방식, cleanup 방식, 시간 처리, 실패 원인 분리다. inquiry 의 endpoint 모양, 첨부파일 흐름, 권한 모델, fixture 값 자체는 예시일 뿐 새 도메인에 기계적으로 복사하지 않는다.

- `src/test/kotlin/.../domain/inquiry/service/impl/InquiryServiceImplTest.kt`
- `src/test/kotlin/.../domain/inquiry/service/impl/InquiryAttachmentServiceImplTest.kt`
- `src/test/kotlin/.../domain/inquiry/model/InquiryAttachmentSelectionTest.kt`
- `src/test/kotlin/.../domain/inquiry/model/InquiryAttachmentUploadPolicyTest.kt`
- `src/integrationTest/kotlin/.../domain/inquiry/repository/InquiryRepositoryIntegrationTest.kt`
- `src/e2eTest/kotlin/.../domain/inquiry/InquiryCreateE2ETest.kt`
- `src/e2eTest/kotlin/.../domain/inquiry/InquiryDetailE2ETest.kt`

## 구현 순서

- E2E 가 표현한 사용자 흐름을 기준으로 필요한 ServiceImpl 메서드부터 GREEN 으로 만든다.
- ServiceImpl unit 이 요구하는 repository 호출, 도메인 예외, 권한/상태 분기를 먼저 만족시킨다.
- 상태 전이, 선택/중복 제거, 업로드 정책, 키 생성 같은 순수 규칙은 domain model/policy 테스트로 분리한다.
- 그 다음 repository integration 이 요구하는 jOOQ query, mapper, converter, UTC DATETIME 왕복, guarded mutation 을 맞춘다.
- 마지막으로 E2E 를 실행해 Controller → Service → Repository → DB wiring 을 확인한다.

## ServiceImpl

- ServiceImpl 은 트랜잭션 스크립트 패턴으로 작성하지 않는다. 비즈니스 로직은 도메인 모델 안에 둔다.
- ServiceImpl 은 orchestration 만 맡는다: 인증 주체 확인, 트랜잭션 경계, repository 호출, domain model 메서드 조합, 응답 조립.
- 상태 전이, 불변식, 계산, 검증 규칙은 도메인 모델 메서드로 보낸다. ServiceImpl 에 조건문이 늘어나면 먼저 도메인 모델 행위로 옮길 수 있는지 검토한다.
- 현재 시각은 `clock.instant()` 만 사용한다.
- 조회 실패, 권한 위반, 상태 위반은 도메인 `BusinessException` 으로 맞춘다.
- 외부 저장소나 첨부 처리는 별도 service 로 위임하고, 상위 service 는 흐름만 조율한다.
- auth-aware service unit 은 `SecurityContextHolder` 를 직접 setup/teardown 하고 `JwtPrincipal` 을 주입한다.
- unit 테스트에서는 repository/외부 client 를 mock 으로 둔다. 구현은 필수 interaction 을 만족하되, 순서가 계약인 경우(권한 확인 전 mutation 금지, lock/read-before-update 등)에만 호출 순서를 고정한다.

## RepositoryImpl / mapper

- RepositoryImpl 은 jOOQ `DSLContext` 와 generated table/record 를 사용한다.
- active row 조건, soft-delete 조건, 상태 조건은 integration 테스트명에 드러난 계약을 우선한다.
- enum 은 byte-code converter 를 통해 도메인 enum 으로 왕복되어야 한다.
- DB `DATETIME` 은 UTC `Instant` 로 왕복한다.
- update, softDelete, saveAnswer 같은 state-guarded mutation 의 affected row 가 0이면 도메인 상태 예외로 변환한다.
- mapper 는 record 와 model 의 1:1 변환에 집중하고 service 규칙을 넣지 않는다.

## Test 스타일 유지

- unit: JUnit 5 + mockito-kotlin, `Clock.fixed`, 한글 backtick 테스트명.
- unit: 큰 multi-method service 는 `@Nested` 로 메서드별 그룹을 둔다. 작은 service 는 flat 테스트도 허용한다.
- unit: 한 테스트는 한 규칙만 검증하고, mock verify 로 service orchestration 을 확인한다.
- fixture: 반복되는 domain model, request DTO, external response 는 test support fixture 로 둔다. 테스트별 의미가 중요한 값만 named argument 로 덮어쓴다.
- fixture: integration/E2E 의 DB row 생성 helper 는 repository contract 나 HTTP scenario 를 흐리지 않는 범위에서 공유한다.
- fixture: 공용 fixture 가 테스트 의도를 숨기면 로컬 helper 를 유지한다. JSON body 나 단발성 assertion 까지 억지로 추상화하지 않는다.
- integration: `@SpringBootTest` + Testcontainers datasource + `DSLContext` 직접 seed/cleanup.
- integration: service 분기를 반복하지 않고 query predicate, converter, UTC 왕복, soft-delete, attachment filtering, guarded mutation 을 검증한다.
- E2E: `MockMvc` 로 실제 HTTP 경로를 타고, 대표 wiring 시나리오 몇 개만 검증한다.
- E2E: 기본 happy path, 자연스러운 multi-call 흐름, 회귀 가치가 큰 forbidden/invalid-state 1건 정도를 고른다.
- E2E: 응답 핵심 필드와 필요한 DB side effect 만 검증한다.
- E2E: 자동 rollback 보다 명시적 cleanup 을 선호한다. 실제 commit/wiring 확인이 목적이다.

## 하지 말 것
- **ServiceImpl 은 트랜잭션 스크립트 패턴으로 작성하지 않는다.**
- GREEN 을 위해 테스트 단정을 느슨하게 바꾸지 않는다.
- ServiceImpl 에 jOOQ query 나 record mapping 을 넣지 않는다.
- RepositoryImpl 에 인증/권한/화면 응답 조립 규칙을 넣지 않는다.
- integration 테스트에서 unit 예외 매트릭스를 그대로 복제하지 않는다.
- E2E 를 여러 예외 케이스로 넓혀 실패 원인 구분을 어렵게 만들지 않는다.
