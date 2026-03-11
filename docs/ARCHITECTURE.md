# GraceVoca — Architecture Document

**Version**: 1.0.0
**Last Updated**: 2026-03-11

---

## 목차 (Table of Contents)

1. [System Overview](#1-system-overview)
2. [Directory Structure](#2-directory-structure)
3. [Data Model: Word](#3-data-model-word)
4. [State Management](#4-state-management)
5. [API Integrations](#5-api-integrations)
6. [TTS (Text-to-Speech)](#6-tts-text-to-speech)
7. [SharedPreferences Key Reference](#7-sharedpreferences-key-reference)
8. [Sort and Filter System](#8-sort-and-filter-system)
9. [Navigation Architecture](#9-navigation-architecture)
10. [Platform Notes](#10-platform-notes)

---

## 1. System Overview

GraceVoca는 Android와 Web을 동시 타깃으로 하는 단일 리포지토리 Flutter 앱입니다.

- **백엔드 없음**: 모든 데이터 저장은 클라이언트 측 `shared_preferences`를 통해 처리됩니다.
- **주요 스토리지 키**:
  - `words_v2`: Word 객체의 JSON 배열
  - `notebooks_by_language`: `english`/`japanese`/`chinese`를 키로 하는 JSON 맵

---

## 2. Directory Structure

```
lib/
  main.dart              # 앱 진입점, MaterialApp, 4탭 NavigationBar
  pages/
    word_list_page.dart  # Word 모델 정의 + 메인 목록/필터/CRUD UI (1893줄)
    flashcard_page.dart  # 플립카드 퀴즈 + 4지선다 퀴즈 (2탭, TabController)
    add_word_page.dart   # 언어 선택 후 단어 추가 라우팅 진입점
    edit_word_page.dart  # 단어 인라인 편집
    home_page.dart       # (스텁/예약)
    settings_page.dart   # 언어 설정, AI 자동추가 토글, 전체 노트북 표시 토글
    languages/
      add_english_word_page.dart   # DictionaryAPI 조회 + TTS + 노트북 선택
      add_japanese_word_page.dart  # Jisho API 조회 + TTS (ja-JP)
      add_chinese_word_page.dart   # MyMemory 번역 + TTS

android/
  app/build.gradle.kts   # namespace=com.example.gracevoca, Java 17
  gradle.properties      # JVM: -Xmx8G, Gradle 8.14

web/
  index.html             # gh-pages 서브경로를 위한 $FLUTTER_BASE_HREF 플레이스홀더

.github/workflows/       # CI/CD 워크플로우 (3개 YAML)
```

---

## 3. Data Model: Word

`Word` 클래스는 `lib/pages/word_list_page.dart` (lines 12–97)에 정의되어 있습니다.

### 3.1 필드 목록

| 필드 | 타입 | 공통 | EN 전용 | JA 전용 | ZH 전용 |
|---|---|:---:|:---:|:---:|:---:|
| `word` | `String` | ✅ | | | |
| `meaning` | `String` | ✅ | | | |
| `phonetic` | `String?` | ✅ (EN IPA) | | | |
| `example` | `String?` | ✅ | | | |
| `notebook` | `String` | ✅ | | | |
| `language` | `String` | ✅ (`english`/`japanese`/`chinese`) | | | |
| `isFavorite` | `bool` | ✅ | | | |
| `createdAt` | `DateTime` | ✅ | | | |
| `reviewCount` | `int` | ✅ | | | |
| `correctCount` | `int` | ✅ | | | |
| `lastReviewed` | `DateTime?` | ✅ | | | |
| `kanji` | `String?` | | | ✅ | |
| `hiragana` | `String?` | | | ✅ | |
| `jlptLevel` | `String?` | | | ✅ | |
| `simplified` | `String?` | | | | ✅ |
| `pinyin` | `String?` | | | | ✅ |

### 3.2 파생 속성

```dart
double get accuracy => reviewCount > 0 ? (correctCount / reviewCount * 100) : 0.0;
```

### 3.3 데이터 마이그레이션

`Word.fromJson` 팩토리에는 마이그레이션 shim이 포함되어 있습니다:

```dart
notebook: json['notebook'] ?? json['tags']?.first ?? '기본 단어장'
```

이전 데이터 모델은 `tags` 배열 필드를 사용했으나, 현재는 단일 `notebook` 문자열로 대체되었습니다.

---

## 4. State Management

- **패턴**: 순수 `setState` 사용. BLoC, Provider, Riverpod, GetX 미사용.
- **진실의 원천(Source of Truth)**: `WordListPage`가 모든 단어의 원천이며 `SharedPreferences`를 직접 읽고 씁니다.
- **페이지 간 데이터 전달**:
  - `FlashcardPage`: `ModalRoute.settings.arguments` (Map, `words` 키)를 통해 단어 수신
  - `SettingsPage`: 각 설정 키를 독립적으로 읽고 씁니다
- **언어별 노트북 목록**: `notebooks_by_language` 키 아래 JSON 맵으로 저장

---

## 5. API Integrations

| API | 사용 위치 | 엔드포인트 | 용도 |
|---|---|---|---|
| Free Dictionary API | `add_english_word_page.dart` | `https://api.dictionaryapi.dev/api/v2/entries/en/{word}` | 발음기호, 정의, 예문 |
| Jisho API | `add_japanese_word_page.dart` | `https://jisho.org/api/v1/search/words?keyword={word}` | 한자, 히라가나, JLPT 레벨, 의미 |
| MyMemory Translation | `add_chinese_word_page.dart` | `https://api.mymemory.translated.net/get?q={text}&langpair=zh|ko` | 중국어 입력의 한국어 번역 |

- 모든 API 호출은 `package:http`의 `http.get(Uri.parse(url))` 사용
- 인증 불필요 (모두 무료/공개 API)
- 에러 처리: 각 호출을 try/catch로 래핑, 실패 시 SnackBar 표시

---

## 6. TTS (Text-to-Speech)

- **패키지**: `flutter_tts ^4.2.0`
- **인스턴스**: 각 언어 추가 페이지마다 자체 `FlutterTts` 인스턴스 생성
- **언어 코드**:
  - 영어: `en-US`
  - 일본어: `ja-JP`
  - 중국어: `zh-CN`
- **설정**: pitch 1.0, speech rate 0.5 (전 언어 공통)

---

## 7. SharedPreferences Key Reference

| 키 | 타입 | 설명 |
|---|---|---|
| `words_v2` | String (JSON) | 모든 Word 객체의 배열 |
| `notebooks_by_language` | String (JSON) | 언어 → 노트북 이름 목록 맵 |
| `selectedLanguage` | String | 단어 추가 기본 언어 (`english`/`japanese`/`chinese`) |
| `autoAddEnglish` | bool | 영어 AI 자동추가 토글 |
| `autoAddJapanese` | bool | 일본어 AI 자동추가 토글 |
| `autoAddChinese` | bool | 중국어 AI 자동추가 토글 |
| `showMenu` | bool | 단어 목록에서 전체 노트북 표시 여부 |
| `recommendedEnglishWords` | StringList | 추천 영어 단어 캐시 |

---

## 8. Sort and Filter System (WordListPage)

### 8.1 정렬 유형

`SortType` 열거형:

| 값 | 설명 |
|---|---|
| `newest` | 최신순 (기본값) |
| `oldest` | 오래된순 |
| `alphabetical` | 알파벳순 |
| `mostReviewed` | 복습 횟수 많은 순 |
| `accuracy` | 정확도 높은 순 |

### 8.2 필터 차원

| 필터 | 설명 |
|---|---|
| 검색어 | 단어/뜻 부분 문자열 검색 |
| 노트북 | 선택된 노트북으로 필터 |
| 즐겨찾기 | 즐겨찾기 단어만 표시 |
| 언어 | `all`/`english`/`japanese`/`chinese` |
| 정확도 | `high`(70%+) / `medium`(40-70%) / `low`(40% 미만) |

모든 활성 필터는 `_applyFilters()` 메서드에서 순서대로 적용됩니다.

---

## 9. Navigation Architecture

- **메인 탭**: `MainScreen`이 `IndexedStack`을 사용하여 4개 탭 간 상태 유지
- **Named Route**: `/editWord` → `EditWordPage` (arguments로 단어 데이터 전달)
- **언어 추가 페이지**: Imperative push (named route 아님)

```
MainScreen (IndexedStack)
├── Tab 0: WordListPage
├── Tab 1: FlashcardPage
├── Tab 2: StatisticsPage (스텁, main.dart 인라인 정의)
└── Tab 3: SettingsPage

Named Routes:
  /editWord → EditWordPage
```

---

## 10. Platform Notes

### Android

- `applicationId`: `com.example.gracevoca` (출시 전 변경 필요)
- `minSdk`/`targetSdk`/`versionCode`: Flutter Gradle 플러그인 기본값 위임
- 릴리즈 빌드는 현재 debug signing key 사용 (keystore 미설정)

### Web

- `web/index.html`의 `$FLUTTER_BASE_HREF` 플레이스홀더는 빌드 시 `--base-href` 플래그 값으로 교체됩니다.
- GitHub Pages 서브경로 배포 시 반드시 `--base-href /gracevoca/` 플래그 지정 필요
- 이 플래그를 생략하거나 잘못 지정하면 빈 페이지 + 404 에러가 발생합니다.

### 미구현 기능

- `StatisticsPage`는 `main.dart` 인라인 스텁으로 정의됨 (`lib/pages/` 외부)
- `SettingsPage`의 내보내기/가져오기 UI는 `SnackBar('기능 준비중입니다')` 호출만 존재 (미구현)
