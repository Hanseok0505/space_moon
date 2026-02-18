# Space Moon - 실제 배포 실행 가이드

아래 순서대로 진행하면 지금 코드 상태에서 바로 서비스 가능합니다.

## 1) 먼저 실행/컴파일 체크
- 이 저장소에서 변경한 스크립트 저장
- `MainPlace/ServerScriptService/MainServer.server.lua`와 `MoonPlace/ServerScriptService/MoonServer.server.lua`에서
  - PlaceId가 0이더라도 `game:GetAttribute` / `ReplicatedStorage` 속성으로도 대체 읽기
  - 즉시 반영되는 구조로 변경됨

## 2) Studio에서 Place 파일 열기
- `MainPlace.rbxlx` 열기
- `MoonPlace.rbxlx` 열기

## 3) PlaceId 연결 (두 방식 중 하나)
### A안 (권장): Place Attribute로 설정 (추천)
- MainPlace 스크립트 실행 후 `game:GetAttribute("MOON_PLACE_ID")` 값을 쓰기 위해
  - `game`(Place) 속성에 `MOON_PLACE_ID` (Number) 추가
  - 값: MoonPlace의 실제 PlaceId
- MoonPlace 쪽에는 `ROOT_PLACE_ID` (Number) 추가
  - 값: MainPlace의 실제 PlaceId

### B안: Shared/PlaceConfig.lua 직접 수정
- `MainPlace/ReplicatedStorage/Shared/PlaceConfig.lua`
  - `MOON_PLACE_ID = 0` → MoonPlace PlaceId로 변경
- `MoonPlace/ReplicatedStorage/Shared/PlaceConfig.lua`
  - `ROOT_PLACE_ID = 0` → MainPlace PlaceId로 변경

## 4) 기능 동작 확인(로컬 플레이 테스트)
- 메인 플레이 테스트:
  - 우주선 구매/장착 UI
  - `Go to Moon` 버튼 활성/비활성 상태
  - 박물관 기부, 퀴즈, 제작 버튼
- 달 스테이지 플레이 테스트:
  - 노드 수집, 남은 자원 즉시 반영
  - `Return to Earth`

## 5) 배포(2개 Place)
- 두 Place 모두 `Publish to Roblox` 실행
- Security -> `API Services` 활성화(둘 다)
- 데이터스토어 사용 허용 확인

## 6) 최종 점검 포인트
- 동일한 우주선(`Lunar-Module`) 동시 탑승 시 패드 쿨다운 동작
- 게임에 접속한 여러 사람이 각각의 우주선 구매/장착 상태가 서로 섞이지 않고 반영되는지 확인
- 자동 동기화(`GetPlayerState`, `RequestState`)가 4초/6초 주기로 잘 들어오는지 확인

## 7) 긴급 점검 항목(필수)
- `QuizzesConfig.lua`의 질문 표시 인코딩 정상화 완료
- PlaceId 미설정 시 서버 알림이 표시되고 전송이 차단되는지 확인

원하시면 제가 다음으로 `MainPlace.rbxlx`와 `MoonPlace.rbxlx`를 Studio에서 바로 열어 확인할 수 있도록
`Place Attribute`까지 반영된 템플릿(스크립트 기준)으로 붙여넣기용 체크리스트를 추가로 드리겠습니다.
