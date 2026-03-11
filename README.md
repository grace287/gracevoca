# GraceVoca (그레이스보카)

> AI-assisted multilingual vocabulary notebook for Korean learners of English, Japanese, and Chinese

[![Android APK](https://github.com/grace287/gracevoca/actions/workflows/android-apk.yml/badge.svg)](https://github.com/grace287/gracevoca/actions/workflows/android-apk.yml)
[![Web Deploy](https://github.com/grace287/gracevoca/actions/workflows/web-deploy.yml/badge.svg)](https://github.com/grace287/gracevoca/actions/workflows/web-deploy.yml)

---

## 소개 (Description)

**GraceVoca**는 영어, 일본어, 중국어를 학습하는 한국인을 위한 AI 기반 다국어 단어장 앱입니다.

단어를 입력하면 무료 공개 API를 통해 발음기호(IPA), 정의, 예문, JLPT 레벨, 병음 등을 자동으로 채워줍니다. 별도 계정이나 서버 없이 기기 로컬에 데이터를 저장하여 오프라인에서도 완전히 동작합니다.

---

## 스크린샷 (Screenshots)

| 단어 목록 | 영어 추가 | 플래시카드 | 설정 |
|---|---|---|---|
| `docs/screenshots/word_list.png` | `docs/screenshots/add_english.png` | `docs/screenshots/flashcard.png` | `docs/screenshots/settings.png` |

---

## 주요 기능 (Features)

- **다국어 단어장**: 영어 / 일본어 / 중국어 통합 관리
- **API 자동완성**: 무료 공개 Dictionary API를 통해 단어 정보 자동 입력
- **노트북 분류**: 언어별 커스텀 노트북으로 단어 그룹 관리
- **플래시카드**: 앞/뒤 플립 애니메이션 복습 모드
- **4지선다 퀴즈**: 인터랙티브 객관식 퀴즈
- **TTS 발음**: 언어별 음성 엔진을 통한 단어 발음 재생
- **즐겨찾기**: 중요 단어 별표 표시
- **검색 및 필터**: 언어, 노트북, 정확도, 즐겨찾기 기준 필터링 + 정렬
- **오프라인 우선**: 계정 없이 기기 로컬 저장 (SharedPreferences)

---

## 기술 스택 (Tech Stack)

| 분류 | 기술 |
|---|---|
| 프레임워크 | Flutter (stable channel, SDK ^3.10.0) |
| 언어 | Dart |
| 로컬 저장 | shared_preferences ^2.5.3 |
| 네트워킹 | http ^1.2.0 |
| 오디오 | just_audio ^0.9.36 |
| TTS | flutter_tts ^4.2.0 |
| Dictionary API (EN) | api.dictionaryapi.dev (무료, 인증 불필요) |
| Dictionary API (JA) | jisho.org/api (무료, 인증 불필요) |
| Translation API (ZH) | api.mymemory.translated.net (무료, 인증 불필요) |
| 빌드 시스템 | Gradle 8.14, Java 17 |
| CI/CD | GitHub Actions |
| 웹 배포 | GitHub Pages |

---

## 시작하기 (Getting Started)

### 필수 요건

- Flutter SDK (stable channel)
- Java 17
- Android SDK (Android 빌드 시)

### 설치 및 실행

```bash
git clone <repo-url>
cd gracevoca
flutter pub get

# Android 기기/에뮬레이터에서 실행
flutter run

# 웹 브라우저에서 실행
flutter run -d chrome
```

---

## 빌드 및 배포 (Build & Deploy)

```bash
# Android APK
flutter build apk --release

# GitHub Pages 웹 배포
flutter build web --release --base-href /gracevoca/
```

자세한 내용은 [`.github/workflows/`](.github/workflows/)의 CI/CD 워크플로우를 참조하세요.

### 릴리즈 태그 배포

```bash
git tag prd-1.0.0
git push origin prd-1.0.0
```

`prd-*` 태그 푸시 시 GitHub Actions가 자동으로 APK를 빌드하고 GitHub Release에 첨부합니다.

---

## 문서 (Documentation)

| 문서 | 경로 |
|---|---|
| 아키텍처 | [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) |
| 제품 요구사항 (PRD) | [docs/PRD.md](docs/PRD.md) |
| 개발자 가이드 | [docs/DEV.md](docs/DEV.md) |

---

## 기여하기 (Contributing)

1. 리포지토리 포크
2. 기능 브랜치 생성 (`git checkout -b feature/my-feature`)
3. 변경사항 커밋
4. PR 제출 전 `flutter test` 실행
5. `main` 브랜치로 PR 제출

한국어 주석은 허용됩니다.

---

## 라이선스 (License)

라이선스 미정 — 추후 업데이트 예정
