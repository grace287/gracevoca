# GraceVoca — Developer Guide

**Version**: 1.0.0
**Last Updated**: 2026-03-11

---

## 목차 (Table of Contents)

1. [Prerequisites](#1-prerequisites)
2. [Local Setup](#2-local-setup)
3. [Build Commands](#3-build-commands)
4. [Gradle Configuration](#4-gradle-configuration)
5. [Project Structure](#5-project-structure)
6. [Adding a New Language](#6-adding-a-new-language)
7. [Data Storage](#7-data-storage)
8. [Code Style](#8-code-style)
9. [Running Tests](#9-running-tests)
10. [Known Issues / Caveats](#10-known-issues--caveats)
11. [Branch Strategy](#11-branch-strategy)

---

## 1. Prerequisites

| 도구 | 버전 | 비고 |
|---|---|---|
| Flutter SDK | stable channel | SDK constraint `^3.10.0` |
| Dart | Flutter 번들 포함 | 별도 설치 불필요 |
| Java | **17** | `build.gradle.kts` `compileOptions` 및 `kotlinOptions` 필수 조건 |
| Android Studio 또는 VS Code | 최신 | Flutter/Dart 확장 설치 필요 |
| Android SDK | Flutter 호환 버전 | Android 빌드 시 필요 |

Android SDK 라이선스 수락:
```bash
flutter doctor --android-licenses
```

---

## 2. Local Setup

```bash
git clone <repo-url>
cd gracevoca
flutter pub get

# 연결된 기기 또는 에뮬레이터에서 실행
flutter run

# 웹 브라우저에서 실행
flutter run -d chrome
```

---

## 3. Build Commands

| 명령어 | 출력 결과 |
|---|---|
| `flutter build apk --release` | `build/app/outputs/flutter-apk/app-release.apk` |
| `flutter build appbundle --release` | Play Store용 AAB |
| `flutter build web --release --base-href /gracevoca/` | `build/web/` (GitHub Pages용) |

### `--base-href` 주의사항

GitHub Pages URL이 `https://username.github.io/gracevoca/`인 경우 `--base-href /gracevoca/`를 사용합니다.
루트 도메인(`username.github.io`)에 배포하는 경우 `--base-href /`를 사용합니다.

> ⚠️ `--base-href`를 생략하거나 잘못 지정하면 웹앱이 빈 페이지와 404 에러를 표시합니다.

---

## 4. Gradle Configuration

| 설정 | 값 |
|---|---|
| Gradle 버전 | 8.14 (`gradle-wrapper.properties`) |
| JVM 힙 | `-Xmx8G -XX:MaxMetaspaceSize=4G` (`gradle.properties`) |
| Java 호환성 | `VERSION_17` (`sourceCompatibility` 및 `jvmTarget`) |

---

## 5. Project Structure

```
lib/
├── main.dart                    # 앱 진입점, MaterialApp, 4탭 NavigationBar
│                                # ※ StatisticsPage 인라인 스텁 포함
└── pages/
    ├── word_list_page.dart      # ⭐ 핵심 파일: Word 모델 + 목록/필터/CRUD
    │                            #    lines 12-97: Word 클래스 정의
    │                            #    lines 98+: WordListPage 위젯
    ├── add_word_page.dart       # 언어 선택 → 언어별 추가 페이지 라우팅
    ├── edit_word_page.dart      # 기존 단어 편집 폼
    ├── flashcard_page.dart      # 플립카드 + 4지선다 퀴즈 (TabController)
    ├── home_page.dart           # 홈 (현재 스텁)
    ├── settings_page.dart       # 설정: 언어, AI 자동추가, 노트북 표시
    └── languages/
        ├── add_english_word_page.dart   # DictionaryAPI + TTS + 노트북 선택
        ├── add_japanese_word_page.dart  # Jisho API + TTS (ja-JP)
        └── add_chinese_word_page.dart   # MyMemory 번역 + TTS
```

### 주요 파일별 수정 가이드

| 작업 | 수정 파일 |
|---|---|
| Word 모델 필드 추가 | `word_list_page.dart` (lines 12–97) |
| 단어 목록 UI 변경 | `word_list_page.dart` |
| 필터/정렬 로직 수정 | `word_list_page.dart` (`_applyFilters()`) |
| 영어 자동완성 API | `add_english_word_page.dart` |
| 일본어 자동완성 API | `add_japanese_word_page.dart` |
| 중국어 자동완성 API | `add_chinese_word_page.dart` |
| 플래시카드/퀴즈 | `flashcard_page.dart` |
| 앱 설정 | `settings_page.dart` |
| 탭 구조 변경 | `main.dart` |

---

## 6. Adding a New Language

새 언어를 추가하는 단계별 가이드:

1. **언어 추가 페이지 생성**
   ```
   lib/pages/languages/add_LANGUAGE_word_page.dart
   ```
   기존 `add_english_word_page.dart`를 템플릿으로 사용하세요.

2. **Word 모델에 언어별 필드 추가** (`word_list_page.dart` lines 12–97)
   ```dart
   // 예: 한국어 추가 시
   String? romanization; // 로마자 표기
   ```

3. **WordListPage 언어 필터 업데이트** (`word_list_page.dart`)
   - 언어 선택 드롭다운에 새 언어 추가
   - `_applyFilters()` 메서드에서 새 언어 처리

4. **SettingsPage AI 자동추가 토글 추가** (`settings_page.dart`)
   ```dart
   // 새 SharedPreferences 키 추가
   static const String autoAddKorean = 'autoAddKorean';
   ```

5. **add_word_page.dart 디스패치 로직 업데이트**
   ```dart
   case 'korean':
     return AddKoreanWordPage();
   ```

---

## 7. Data Storage

아키텍처 문서의 [SharedPreferences Key Reference](./ARCHITECTURE.md#7-sharedpreferences-key-reference) 참조.

### 데이터 마이그레이션

`words_v2` 키는 이전 `words` 키를 대체합니다.
`Word.fromJson` 팩토리의 마이그레이션 shim:
```dart
notebook: json['notebook'] ?? json['tags']?.first ?? '기본 단어장'
```
이 코드는 이전 `tags` 배열을 단일 `notebook` 문자열로 변환합니다.

---

## 8. Code Style

- **린터**: `flutter_lints ^6.0.0` (`analysis_options.yaml` 참조)
- **상태관리**: 현재 컨벤션은 `setState`. Provider/Riverpod 마이그레이션은 로드맵.
- **주석 언어**: 코드베이스 전반에 한국어 주석 사용. 주요 컨텍스트가 한국어인 경우 유지.

---

## 9. Running Tests

```bash
flutter test
```

> 📝 현재 `test/widget_test.dart`에 기본 생성 테스트만 존재합니다. PR 제출 전 테스트를 통과시키세요.

---

## 10. Known Issues / Caveats

| 이슈 | 설명 | 해결 방법 |
|---|---|---|
| `StatisticsPage` 스텁 | `lib/pages/`가 아닌 `main.dart` 인라인에 정의됨 | v1.1에서 독립 페이지로 분리 예정 |
| 릴리즈 서명 | 릴리즈 빌드가 debug key 사용 | 출시 전 keystore 생성 및 `signingConfig` 업데이트 필요 |
| `applicationId` | 여전히 `com.example.gracevoca` | Play Store 출시 전 고유 ID로 변경 필요 |
| 내보내기/가져오기 | `SettingsPage`에 UI는 있지만 `SnackBar('기능 준비중입니다')`만 표시 | 미구현 상태 |
| `words` 레거시 키 | 이전 버전에서 `tags` 배열 필드 사용 | `fromJson` 마이그레이션 shim으로 처리 중 |

---

## 11. Branch Strategy

| 브랜치 | 용도 |
|---|---|
| `main` (또는 `master`) | 안정적인 프로덕션 코드 |
| `feature/*` | 기능 개발 브랜치 |
| `claude/*` | AI 지원 브랜치 |

### CI/CD 트리거

| 워크플로우 | 트리거 | 설명 |
|---|---|---|
| `android-apk.yml` | `main` 푸시 또는 PR | APK 빌드 및 아티팩트 업로드 |
| `web-deploy.yml` | `main` 푸시 | GitHub Pages에 웹 배포 |
| `android-release.yml` | `prd-*` 태그 푸시 | GitHub Release에 APK 첨부 |

### 릴리즈 태그 규칙

```bash
# 릴리즈 태그 생성 및 푸시
git tag prd-1.0.0
git push origin prd-1.0.0
```

태그 형식: `prd-x.y.z` (예: `prd-1.0.0`, `prd-1.0.1`, `prd-2.0.0-beta`)
