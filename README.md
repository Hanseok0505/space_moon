# Space → Moon v3 (Main & Moon with Round-trip Teleport and Auto Scene)

## 두 플레이스 사용법
1. **MainPlace**와 **MoonPlace**를 각각 Publish하여 PlaceId를 확보합니다.
2. 권장: 게임 Attribute로 PlaceId를 설정합니다.
   - MainPlace: `MoonPlaceId` (Number) = MoonPlace PlaceId
   - MoonPlace: `RootPlaceId` (Number) = MainPlace PlaceId
3. 기존 상수(`MOON_PLACE_ID`, `ROOT_PLACE_ID`)를 직접 수정해도 작동합니다.
4. 두 플레이스 모두 `Game Settings → Security → Enable Studio Access to API Services` 체크(DataStore).

## 즉시 플레이 가능한 기본 월드
- MainPlace는 서버 시작 시 자동으로 다음을 보정 생성합니다.
- `EarthGround` 지면
- `MainSpawn` 스폰 위치(없을 때만 생성)
- `IronNode/TitaniumNode` 채집 노드
- `MuseumPad` 박물관 구역 바닥

## RemoteEvents 생성
- MainPlace: `RequestCraft`, `RequestPurchaseShip`, `RequestStartQuiz`, `SubmitQuizAnswer`, `DonateMuseumItem`, `CollectOre`, `CollectNode`, `RequestTeleportMoon`
- MoonPlace: `RequestTeleportBack`

## MoonPlace 자동 씬
서버가 다음을 자동 생성합니다.
- 바닥 플랫폼
- **ReturnPortal** (ProximityPrompt로 메인 귀환)
- **LunarNode x3** (ProximityPrompt로 월면 채집, 드랍률은 `DropRatesConfig.lua`의 `LunarNode` 적용)

## 프로필/저장
- 두 플레이스 모두 같은 `SpaceGameProfile_V1` DataStore를 사용하여 현금/인벤/점수 유지.

## 주간 랭킹(메인)
- OrderedDataStore `QuizWeekly_Leaderboard_V1` 저장(표시는 커스텀 UI 필요).

## 배포 전 점검 체크리스트
1. PlaceId 설정
- MainPlace 게임 속성: `MoonPlaceId`(Number)
- MoonPlace 게임 속성: `RootPlaceId`(Number)
- Studio 내 `Enable Studio Access to API Services`가 켜져 있는지 확인
2. 첫 진입 안정성
- MainPlace 시작 시 캐릭터가 `MainSpawn` 또는 지면에서 즉시 스폰되는지
- 스폰 후 3초 이내 낙하/공중 부유 없이 제자리 유지되는지
3. 상호작용 기본 흐름
- 퀴즈 버튼: 문제 수신 → 답 제출 → 정답/오답 응답 UI 확인
- 상점/제작: 창 토글 및 구매/제작 버튼 클릭 시 서버 오류 없는지
- `달로 이동`: Lunar-Module 구매 후 텔레포트되고 MoonPlace에서 재입장되는지
4. 달에서의 상호작용
- `LunarNode_*` 채집 프롬프트 작동 및 보상 반영
- 수집 재화/인벤토리의 DataStore 저장이 재접속 후 유지되는지
- 귀환 포털과 `메인으로 귀환` 버튼 모두로 왕복 가능한지
5. 멀티플레이/반복 테스트
- 최소 2회 이상 왕복 텔레포트 테스트
- 최소 2명 동시 입장 시 텔레포트 및 채집 충돌/서버 오류 없는지
6. 마켓 출시 준비
- 썸네일/설명/장르/연령등급/기기 호환이 게임 페이지에 설정돼 있는지
- 테스트 게임에서 스폰, 채집, 귀환, 수집/제작 전체 흐름을 연속 5분 이상 플레이

## 배포 실패 대응 템플릿
1. 증상
- 발생 위치(메인/달), 재현 순서, 화면/콘솔 캡처
2. 수집 로그
- 출력창 `Output` 에러(전체 스택), 네트워크/텔레포트 로그
3. 영향 범위
- 특정 사용자/전체, 특정 디바이스, 특정 직전 액션 여부
4. 기대 동작 vs 실제 동작
- 기대: __
- 실제: __
5. 즉시 조치
- 플레이어 대기/로직 잠시 비활성화/수정 포인트
6. 반영 커밋
- 수정 파일: __
- 체크리스트 재실행 결과: 통과/실패

Have fun! 🚀🌙
