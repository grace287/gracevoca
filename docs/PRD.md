# GraceVoca — Product Requirements Document (PRD)

**Version**: 1.0.0
**Status**: Production
**Owner**: Grace
**Platform**: Flutter (Android / Web / iOS 예정)
**Last Updated**: 2026-03-11

---

## 목차 (Table of Contents)

1. [제품 개요](#1-제품-개요)
2. [제품 목표](#2-제품-목표)
3. [기능 요구사항 (FRD)](#3-기능-요구사항-frd)
4. [비기능 요구사항 (NFR)](#4-비기능-요구사항-nfr)
5. [아키텍처](#5-아키텍처)
6. [배포 전략](#6-배포-전략)
7. [QA 체크리스트](#7-qa-체크리스트)
8. [향후 로드맵](#8-향후-로드맵)
9. [부록](#9-부록)

---

## 1. 제품 개요

### 1.1 제품명

**GraceVoca**
브랜드명: GraceVoca (Product Flavor: prd)
※ 출시 시 브랜드명 변경 가능 (예: PolyVoca, AivoVoca 등)

### 1.2 한줄 소개

> 다국어(영/일/중) 학습을 위한 미니멀 & AI 기반 스마트 단어장

### 1.3 주요 가치

| 가치 | 설명 |
|------|------|
| 개인 맞춤 단어장 | 노트북별로 단어를 구분 관리 |
| 다국어 구조 | 영어 / 일본어 / 중국어 언어별 고유 속성 지원 |
| AI 기반 확장 | 파생 단어, 예문, 연관 단어 추천 (로드맵) |
| 모바일·웹 동시 제공 | Flutter 기반 크로스플랫폼 |
| 빠른 배포 | GitHub Actions 기반 CI/CD |

---

## 2. 제품 목표

| 목표 | 상세 |
|------|------|
| 다국어 단어장 | 언어별 고유속성(훈독/음독, 병음, IPA) 지원 |
| TTS 기반 발음 학습 | 언어별 음성 엔진 자동 선택 |
| 퀴즈 / 플래시카드 | 학습 후 즉시 복습 가능한 인터랙티브 UI |
| 자동 번역 | 외부 API를 통한 한국어 번역 자동 제공 |
| 미니멀 UI/UX | 단순하고 직관적인 Material Design 3 UI |

---

## 3. 기능 요구사항 (FRD)

### 3.1 단어 관리 기능

#### Must-Have (구현 완료)

- [x] 단어 추가 / 수정 / 삭제
- [x] 단어 뜻 저장 (한국어 번역)
- [x] 발음 음성 재생 (TTS - flutter_tts)
- [x] 검색 기능 (단어 및 뜻)
- [x] 단어 즐겨찾기
- [x] 단어 목록 로컬 저장 (SharedPreferences)
- [x] 다국어 모드 (EN / JP / CN)
- [x] 노트북별 단어 분류
- [x] 학습 통계 (복습 횟수, 정확도)

#### Good-to-Have (로드맵)

- [ ] 데이터 내보내기 / 가져오기 (Export / Import)
- [ ] 품사 자동 분류 (영어)
- [ ] 파생·변형 단어 자동 생성 (AI)
- [ ] 추천 단어 표시
- [ ] 스페이스드 리피티션(SRS) 복습 알고리즘

---

### 3.2 언어별 데이터 스키마

#### 3.2.1 공통 필드

```dart
class Word {
  String word;        // 단어 원문
  String meaning;     // 한국어 뜻
  String notebook;    // 노트북 이름
  String language;    // 'english' | 'japanese' | 'chinese'
  bool isFavorite;    // 즐겨찾기
  DateTime createdAt; // 생성일
  DateTime? lastReviewed; // 마지막 복습일
  int reviewCount;    // 총 복습 횟수
  int correctCount;   // 정답 횟수
  // 정확도: correctCount / reviewCount * 100
}
```

#### 3.2.2 영어 (EN)

```dart
String? phonetic;   // IPA 발음기호 (예: /ˈæp.əl/)
String? example;    // 예문
// word_forms: 파생형 (명사/형용사/부사/동사) - 로드맵
```

외부 API: [Free Dictionary API](https://api.dictionaryapi.dev)
번역 API: [MyMemory](https://mymemory.translated.net)

#### 3.2.3 일본어 (JP)

```dart
String? kanji;      // 漢字 표기 (예: 勉強)
String? hiragana;   // ひらがな (예: べんきょう)
String? jlptLevel;  // JLPT 레벨 (N1~N5)
// on_yomi, kun_yomi - 로드맵
```

외부 API: [Jisho.org API](https://jisho.org/api/v1/search/words)

#### 3.2.4 중국어 (CN)

```dart
String? simplified; // 簡体字 (예: 学习)
String? pinyin;     // 병음 (예: xuéxí)
// traditional, tone - 로드맵
```

외부 API: [MyMemory](https://mymemory.translated.net) (zh→ko)

---

### 3.3 TTS 기능

| 언어 | 음성 코드 |
|------|-----------|
| 영어 | en-US |
| 일본어 | ja-JP |
| 중국어 | zh-CN |

- 패키지: `flutter_tts: ^4.2.0`
- 언어별 음성 엔진 자동 선택
- 단어 탭 시 즉시 재생

---

### 3.4 검색 기능

| 언어 | 검색 범위 |
|------|-----------|
| 영어 | word, meaning (대소문자 무시) |
| 일본어 | kanji, hiragana, meaning |
| 중국어 | simplified, pinyin, meaning |

---

### 3.5 퀴즈 / 플래시카드

- 플래시카드: 앞면(단어) → 탭 → 뒷면(뜻, 발음, 예문)
- 4지선다 퀴즈 모드
- 정답/오답 카운트
- 세션 종료 후 정확도 통계 표시

---

### 3.6 AI 관련 기능 (v1.2+ 확장 예정)

| 기능 | 설명 |
|------|------|
| 의미 재해석 | AI 기반 단어 문맥 설명 |
| 예문 생성 | 단어별 맞춤 예문 자동 생성 |
| 연관 단어 추천 | 유사 단어 및 반의어 추천 |
| SRS 추천 | 복습 최적 시간 계산 |

---

## 4. 비기능 요구사항 (NFR)

### 4.1 성능

| 항목 | 목표 |
|------|------|
| 로컬 단어 저장 | 5,000개 이상 |
| TTS 응답 시간 | 1초 이내 |
| 웹앱 최초 로딩 | 3초 이내 |
| 검색 응답 | 500ms 이내 |

### 4.2 보안

| 항목 | 방법 |
|------|------|
| API Key 관리 | GitHub Secrets (추후 API Key 필요 시) |
| 사용자 데이터 | 로컬 저장 (클라우드 미사용) |
| 외부 API | 무인증 무료 API 사용 (현재 버전) |

### 4.3 확장성

| 항목 | 방법 |
|------|------|
| 언어 추가 | 언어별 모듈 분리 (lib/pages/languages/) |
| 환경 분리 | Flutter Flavor (dev/prd) - 로드맵 |
| 상태관리 확장 | setState → Provider/Riverpod (로드맵) |

### 4.4 호환성

| 플랫폼 | 상태 |
|--------|------|
| Android | ✅ 지원 |
| Web | ✅ 지원 |
| iOS | 계획 (미테스트) |
| Desktop | 미계획 |

---

## 5. 아키텍처

### 5.1 기술 스택

| 영역 | 기술 | 버전 |
|------|------|------|
| 앱 프레임워크 | Flutter | SDK ^3.10.0 |
| 언어 | Dart | - |
| 상태관리 | setState | 내장 |
| 로컬 저장 | shared_preferences | ^2.5.3 |
| TTS | flutter_tts | ^4.2.0 |
| 오디오 | just_audio | ^0.9.36 |
| HTTP | http | ^1.2.0 |
| 웹 호스팅 | GitHub Pages | - |
| Android 배포 | GitHub Releases | - |
| CI/CD | GitHub Actions | - |

### 5.2 폴더 구조

```
lib/
├── main.dart                    # 앱 진입점, MaterialApp 설정
└── pages/
    ├── home_page.dart           # 홈 화면 (히어로 애니메이션)
    ├── word_list_page.dart      # 단어 목록 + Word 모델 (핵심)
    ├── add_word_page.dart       # 언어 선택 후 단어 추가 라우팅
    ├── edit_word_page.dart      # 단어 수정
    ├── flashcard_page.dart      # 플래시카드 / 퀴즈
    ├── settings_page.dart       # 설정 화면
    └── languages/
        ├── add_english_word_page.dart   # 영어 단어 추가
        ├── add_japanese_word_page.dart  # 일본어 단어 추가
        └── add_chinese_word_page.dart   # 중국어 단어 추가
```

### 5.3 데이터 흐름

```
사용자 입력
    │
    ▼
Language-specific Page
(add_english/japanese/chinese_word_page.dart)
    │
    ├──▶ External API (Dictionary / Jisho / MyMemory)
    │         │
    │         ▼
    │    API 응답 파싱 → Word 객체 생성
    │
    ▼
WordListPage.saveWords()
    │
    ▼
SharedPreferences (JSON 직렬화)
    │
    ▼
WordListPage.loadWords() → UI 렌더링
```

---

## 6. 배포 전략

### 6.1 Android PRD 배포

```bash
# 릴리즈 APK 빌드
flutter build apk --release

# 태그 기반 GitHub Release 자동 배포
git tag prd-1.0.0
git push origin prd-1.0.0
```

GitHub Release에 APK 자동 업로드 (CI/CD via `.github/workflows/android-release.yml`)

### 6.2 Web PRD 배포

```bash
# 웹 빌드
flutter build web --release
```

- GitHub Pages 자동 배포 (`.github/workflows/web-deploy.yml`)
- `main` 브랜치 push 시 자동 트리거
- 배포 URL: `https://{username}.github.io/gracevoca/`

### 6.3 버전 체계

| 유형 | 형식 | 예시 |
|------|------|------|
| 태그 | `prd-x.y.z` | `prd-1.0.0` |
| APK 버전 | `x.y.z+build` | `1.0.0+1` |

---

## 7. QA 체크리스트

### UI/UX

- [ ] 단어 추가/삭제 정상 작동
- [ ] 영어 단어 자동 번역 정상
- [ ] 일본어 음독/훈독 표기 오류 없음
- [ ] 중국어 병음 정상 표시
- [ ] 즐겨찾기 토글 반영
- [ ] 검색 결과 정확성

### 기능

- [ ] TTS 재생 (영어/일본어/중국어)
- [ ] 플래시카드 애니메이션 정상
- [ ] 4지선다 퀴즈 정답/오답 처리
- [ ] 단어 데이터 저장/로드 (앱 재시작 후 유지)
- [ ] 노트북별 필터 작동

### 배포

- [ ] GitHub Pages 웹 페이지 정상 접속
- [ ] APK 정상 설치 (Android 7.0 이상)
- [ ] GitHub Release에 APK 파일 자동 첨부

---

## 8. 향후 로드맵 (Roadmap)

| 버전 | 목표 | 기능 |
|------|------|------|
| v1.0 | MVP 출시 | 다국어 단어장, TTS, 퀴즈, 검색, 즐겨찾기 |
| v1.1 | 학습 강화 | 단어 퀴즈 모드 강화, 통계 페이지 구현 |
| v1.2 | AI 확장 | AI 기반 예문 및 단어 추천 |
| v1.3 | 복습 최적화 | 스페이스드 리피티션(SRS) |
| v2.0 | 클라우드 | 사용자 계정 + 클라우드 동기화 |
| v2.1 | Flavor | dev/prd 환경 분리, Firebase 연동 |

---

## 9. 부록

### 9.1 외부 API 목록

| API | 용도 | 인증 | 요금 |
|-----|------|------|------|
| [Free Dictionary API](https://api.dictionaryapi.dev/api/v2/entries/en/{word}) | 영어 단어 정보 | 불필요 | 무료 |
| [Jisho API](https://jisho.org/api/v1/search/words?keyword={word}) | 일본어 단어 정보 | 불필요 | 무료 |
| [MyMemory API](https://api.mymemory.translated.net/get?q={text}&langpair={from}|{to}) | 다국어 번역 | 불필요 (기본) | 무료 (일 5,000자) |

### 9.2 GitHub Pages 설정

1. GitHub 리포지토리 → **Settings** → **Pages**
2. **Deploy from a branch** 선택
3. Branch: `gh-pages` / `/root` 선택
4. 저장

### 9.3 APK 다운로드

GitHub Releases 탭 → 최신 릴리즈 → Assets → `app-release.apk`

### 9.4 관련 문서

- [개발자 가이드](./DEV.md)
- [아키텍처 문서](./ARCHITECTURE.md)
- [프로젝트 README](../README.md)
