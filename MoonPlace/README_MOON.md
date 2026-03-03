# MoonPlace Quick Guide
- `MoonServer.server.lua`가 월면 씬을 자동으로 생성합니다.
- 권장: `game` Attribute `RootPlaceId`(Number)에 메인 PlaceId를 설정하면 **ReturnPortal**/귀환 버튼이 작동합니다.
- 대안: `ROOT_PLACE_ID` 상수를 직접 수정해도 됩니다.
- 드랍률은 `ReplicatedStorage/Shared/DropRatesConfig.lua` 수정.
- 배포 점검: 귀환 포털, 채집 노드, 데이터 유지, 왕복 텔레포트 2회 이상 테스트 권장.
