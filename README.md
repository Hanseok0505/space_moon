# Space → Moon v3 (Main & Moon with Round-trip Teleport and Auto Scene)

## 두 플레이스 사용법
1. **MainPlace**와 **MoonPlace**를 각각 Publish하여 PlaceId를 확보합니다.
2. MainPlace > `ServerScriptService/MainServer.server.lua`에서
   ```lua
   local MOON_PLACE_ID = 0 -- MoonPlace의 PlaceId로 교체
   ```
3. MoonPlace > `ServerScriptService/MoonServer.server.lua`에서
   ```lua
   local ROOT_PLACE_ID = 0 -- MainPlace(루트)의 PlaceId로 교체
   ```
4. 두 플레이스 모두 `Game Settings → Security → Enable Studio Access to API Services` 체크(DataStore).

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

Have fun! 🚀🌙
