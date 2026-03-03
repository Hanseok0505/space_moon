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
1. MainPlace 플레이 시 캐릭터가 `MainSpawn`에서 시작하고 추락하지 않는지 확인
2. `퀴즈` 버튼: 문제 수신, 답 제출, 정/오답 문구 표시 확인
3. `상점/제작` 버튼: 창 토글 및 버튼 클릭 시 서버 오류 없는지 확인
4. `달로 이동` 버튼: Lunar-Module 구매 후 텔레포트되는지 확인
5. MoonPlace에서 `ReturnPortal` 및 `메인으로 귀환` 버튼으로 왕복 가능한지 확인
6. Moon 노드 채집 후 재입장 시 인벤/현금(DataStore) 유지 확인
7. Creator Dashboard에서 아이콘/썸네일/설명/장르/연령등급/기기 호환 설정 완료 확인

Have fun! 🚀🌙
