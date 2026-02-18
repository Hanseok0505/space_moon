# Space Moon (Roblox)

지구에서 시작해 달로 이동해 자원을 채집하고, 박물관에 전시하는 멀티플레이 게임입니다.

## 실행/배포 핵심 흐름

1. `MainPlace.rbxlx` 열기
2. `MainPlace`에서 최신 스크립트 반영
   - `MainPlace/ServerScriptService/MainServer.server.lua`
   - `MainPlace/StarterPlayer/StarterPlayerScripts/ClientMain.client.lua`
3. `MoonPlace.rbxlx` 열기
4. `MoonPlace/ServerScriptService/MoonServer.server.lua`
5. `MoonPlace/StarterPlayer/StarterPlayerScripts/MoonClient.client.lua`
6. PlaceId 설정
   - MainPlace: `MOON_PLACE_ID`
   - MoonPlace: `ROOT_PLACE_ID`
7. 두 Place를 각각 Publish
8. Security: `Enable Studio Access to API Services` 활성화

## PlaceId 설정 방법(둘 다 가능)

- 권장: Place의 `Attributes`로 설정
  - MainPlace: `MOON_PLACE_ID` (Number)
  - MoonPlace: `ROOT_PLACE_ID` (Number)
- 또는 `ReplicatedStorage/Shared/PlaceConfig.lua` 수정

## 자동 동기화/멀티 UX

- Earth HUD: `GetPlayerState` 자동 동기화(4초 간격)
- Moon HUD: `RequestState` 자동 동기화(6초 간격)
- 우주선 구매/장착은 서버 검증 후 즉시 반영
- 동일 우주선 패드 쿨다운을 공유해 다중 사용자 충돌 완화

## 배포 전 점검

- 달 이동 버튼은 월면 운행 가능 우주선만 활성화
- 여러 계정 동시 접속 시 노드 채집/구매/기부 동시성 확인
- MOON/ROOT_PLACE_ID 미설정 시 경고 메시지 확인

## 변경 핵심

- `MainServer.server.lua`
  - `RequestEquipShip`, `RequestTeleportMoon` 강화
  - `shipCooldowns` 전달 및 상태 동기화 보강
  - 액션 스팸 방지 쿨다운 추가
- `ClientMain.client.lua`
  - 우주선 리스트 상태/버튼 처리 강화
  - 실패 사유 토스트
- `MoonServer.server.lua` / `MoonClient.client.lua`
  - 노드 채집/귀환 동기화 및 PlaceId 폴백 지원
- `QuizzesConfig.lua`
  - 퀴즈 텍스트 인코딩 정리