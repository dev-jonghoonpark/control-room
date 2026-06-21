# Control Room

*[English](README.md) · 한국어*

화면에 떠 있는 바에서 **각 데스크탑(Space)에서 맨 앞 창의 미리보기 + 앱 이름을 한눈에** 보고,
클릭하면 해당 창/데스크탑으로 바로 이동하는 macOS 메뉴바 앱입니다.
Mission Control처럼 왔다 갔다 하지 않고도 어느 데스크탑에 뭐가 떠 있는지 파악할 수 있어요.

- 데스크탑마다 **맨 앞 창 하나의 미리보기 + 앱 이름**을 표시(비어 있으면 "없음").
- 바는 **왼쪽 그립으로 이동**, **가장자리/우하단 그립으로 Dock처럼 비율 유지하며 확대/축소**. 위치/크기는 자동 저장.

## 동작 방식

macOS는 **현재 활성화된 Space만 렌더링**하므로, 다른 데스크탑의 화면은 공개 API로 캡처할 수 없습니다.
Mission Control이 하는 것처럼 Apple의 비공개 프레임워크 **SkyLight(SLS)** 를 사용합니다
(yabai · AltTab 등 검증된 오픈소스와 동일한 접근).

- `SLSCopyManagedDisplaySpaces` — 모든 디스플레이의 Space 목록 / 현재 Space
- `SLSCopyWindowsWithOptionsAndTags` — 각 Space의 창 목록(맨 앞 창 추출)
- `SLSHWCaptureWindowList` — 맨 앞 창 하나의 미리보기 캡처(다른 Space 창 포함)
- Accessibility(`AXRaise`) — 클릭 시 해당 창으로 점프(= 그 Space로 이동)

> ⚠️ Control Room은 비공개 API에 의존하므로 macOS 버전이 올라가면 시그니처가
> 바뀌어 동작이 깨질 수 있습니다(그때는 코드 업데이트가 필요할 수 있어요).
> 같은 이유로 Mac App Store에는 올릴 수 없어 DMG와 소스 형태로 직접 배포합니다.
> 창 목록은 1초 주기로 갱신됩니다.

## 빌드

```bash
# 개발 중 실행
xcrun swift run -c release

# .app 번들 생성 → dist/ControlRoom.app
./scripts/build-app.sh

# 배포용 DMG 생성 → dist/ControlRoom.dmg
./scripts/make-dmg.sh
```

요구사항: macOS 13+, Xcode(또는 Command Line Tools)의 Swift 5.9+.

## 권한 (최초 1회)

`시스템 설정 → 개인정보 보호 및 보안` 에서 두 가지를 허용해야 합니다.

1. **화면 기록(Screen Recording)** — 맨 앞 창 미리보기 캡처에 필요. 허용 후 앱 **재실행** 필요.
2. **손쉬운 사용(Accessibility)** — 다른 Space의 창을 포커스(점프)하는 데 필요.

앱 첫 실행 시 두 권한을 자동으로 요청합니다. 메뉴바 아이콘 → "화면 기록 권한 재요청" / "손쉬운 사용 권한 재요청"으로 다시 요청할 수 있습니다.

> UI는 다국어를 지원합니다. 기본은 영어이고, 시스템 선호 언어가 한국어이면 한국어로 표시됩니다.

## 사용법

- 실행하면 화면 상단에 컨트롤룸 바가 나타납니다.
- 메뉴바 아이콘(▦) 클릭 또는 메뉴의 "표시/숨기기"로 토글합니다.
- 각 항목 = 하나의 데스크탑. 번호 배지가 파란색 = 현재 데스크탑.
- 카드 클릭 → 그 데스크탑의 맨 앞 창으로 점프. 빈 데스크탑("없음") 클릭 → 그 데스크탑으로 전환.
- **왼쪽 점무늬 그립**을 끌면 이동, **가장자리** 또는 **우하단 빗금 그립**을 끌면 Dock처럼 비율 유지하며 확대/축소(위치·크기 자동 저장).
- 메뉴 → "위치/사이즈 초기화"로 기본 위치·크기로 되돌립니다.

## 배포 시 주의 (서명되지 않은 앱)

DMG를 받은 사람이 처음 열 때 Gatekeeper가 막을 수 있습니다.
앱을 우클릭 → "열기" 하거나, 터미널에서 격리 속성을 제거하세요:

```bash
xattr -dr com.apple.quarantine /Applications/ControlRoom.app
```

## 한계 / 향후

- 데스크탑마다 맨 앞 창 하나만 미리보기(나머지 창은 생략).
- 비활성 Space의 미리보기는 "마지막으로 보였던 모습"입니다(해당 Space는 렌더링되지 않으므로). 현재 Space만 실시간 갱신.
- 비활성 패널 특성상 가장자리 리사이즈 **커서**는 표시되지 않을 수 있어, 그립을 시각적 표시로 제공합니다.
- 전역 단축키, 멀티 모니터 배치 개선, 드래그로 창을 다른 Space로 이동 등은 향후 과제.

## 후원

Control Room이 유용했다면 개발을 후원해 주세요:

<a href="https://buymeacoffee.com/jonghoonpark"><img src="https://img.shields.io/badge/Buy%20Me%20a%20Coffee-ffdd00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black" alt="Buy Me a Coffee" /></a>
