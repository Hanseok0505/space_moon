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

## 8) 오픈 직전 마지막 점검(10~15분)
- 2인 동시 접속으로 시작:
  - 플레이어 A: 달행성 획득/박물관 전시
  - 플레이어 B: 지상에서 건물/상점/퀴즈 플레이
  - 5초마다 상태 동기화 UI/수치 반영 여부 확인
- 동시 우주선 탑승/귀환:
  - 서로 다른 우주선 선택 시 각자 독립 이동
  - 동일 우주선 모델 중복 요청 시 `패드 쿨다운/대기 문구`가 즉시 표시
- 데이터 안정성:
  - 리로딩 후 자원/소유 우주선/뮤지엄 수집물 복원 확인
  - 입장/퇴장 후 1분 뒤에도 소유 데이터가 유지되는지 확인
- 네트워크/성능:
  - 최소 20명 동시 입장 기준 랙/딜레이 심한 구간(달 착륙, 박물관 상호작용) 점검
  - 서버 출력에서 반복 에러가 없는지 확인

## 9) 실제 서비스 반영 후 즉시 대응 템플릿
- 플레이어가 “Go to Moon”으로 못 가면:
  1. `PlaceId`가 맞는지 즉시 재확인 (`MainPlace` MOON_PLACE_ID / `MoonPlace` ROOT_PLACE_ID)
  2. `Launch` 버튼 툴팁/쿨다운 메시지를 확인해 제재 사유 분류
  3. 같은 패드 충돌이면 30초 후 재시도 유도
- 수집물/박물관 데이터가 안보이면:
  1. 서버 동기화 이벤트( `GetPlayerState`, `UpdateUI` ) 수신 여부 확인
  2. 플레이어 재접속 후 `ProfileData` 복원 로그 확인
- 긴급 점검 문구:
  - “PlaceId 미설정” 경고 뜨면 즉시 게시 전용 PlaceId 적용 후 재배포

원하면 다음 단계로 `MainPlace`와 `MoonPlace`에 붙여넣기 가능한
`Place Attribute` 설정 스크립트(속성 체크 + 출력 가이드)도 만들어서 바로 붙여드릴게요.
