# Harness

AI 에이전트 기반 기획, 개발, 테스트, 운영 점검, 문서화 작업을 일정한 규칙 안에서 수행하기 위한 범용 하네스 템플릿입니다.

이 저장소는 AI 에이전트 주변에 작은 실행 구조를 제공합니다.

- 만들기 전에 작업을 먼저 정의한다.
- 단계별 산출물 형식을 일정하게 유지한다.
- 위험한 변경을 gate에서 막는다.
- 명령, 결정, 실패 원인을 기록한다.
- 반복되는 실패를 규칙으로 되돌린다.
- 재사용 가능한 지식을 wiki 초안으로 추출한다.
- 최종 승인 권한은 사람에게 둔다.

이 템플릿은 특정 프로젝트에 종속되지 않습니다. 어디에 클론해도 사용할 수 있으며, 대상 프로젝트의 문서와 규칙에 맞게 skill 문구와 gate를 조정하면 됩니다.

## 개요

하네스 엔지니어링은 AI 에이전트가 정해진 제약 안에서 목적을 완수하도록 실행 환경, 규칙, gate, 피드백 루프를 설계하는 작업입니다.

이 템플릿은 다음 여섯 가지에 집중합니다.

1. 입력 표준화
2. 단계 기반 작업 흐름
3. 산출물 품질 gate
4. 안전 gate
5. 추적 가능한 실행 로그
6. 사람이 승인하는 지식 승격

## 설치

저장소를 원하는 위치에 클론합니다.

```bash
git clone https://github.com/JongSoo0919/harness.git
cd harness
./init.sh --dry-run
./init.sh
```

`init.sh`는 `.Codex/skills/*`를 `${CODEX_HOME:-$HOME/.codex}/skills` 하위로 심볼릭 링크합니다.

삭제하거나 덮어쓰지 않습니다. 같은 이름의 skill이 이미 존재하고 다른 위치를 바라보면 `CONFLICT`로 중단합니다.

skill 이름은 의도적으로 단순하게 유지합니다. `plan`, `dev`, `test`, `ops`, `document`, `share`, `flow`를 사용합니다. 같은 이름이 이미 있다면 어떤 skill을 사용할지 사람이 결정해야 합니다.

## Skill

설치되는 skill은 다음과 같습니다.

- `flow`: 전체 흐름 조율
- `plan`: 아이디어, 제품, 기능, 유지보수 요청 구체화
- `dev`: 승인된 계획 구현
- `test`: 변경 사항 검증
- `ops`: 운영 리스크 점검
- `document`: 문서 갱신 및 재사용 지식 추출
- `share`: 커밋, PR, 팀 공유 준비

기본 흐름은 다음과 같습니다.

```text
plan -> dev -> test -> ops -> document -> share
```

작업이 좁으면 단일 skill만 사용합니다. 여러 단계가 이어지는 작업이면 `flow`를 사용합니다.

## 작업 흐름

### 1. Plan

요청이 모호하거나, 신규 제품/기능 기획이거나, 아키텍처 판단이 필요하거나, 바로 구현하기 어려운 경우 `plan`을 사용합니다.

`plan` 단계는 다음 작업에 사용할 수 있습니다.

- 신규 제품 아이디어
- 기능 설계
- 유지보수 작업
- 버그 수정
- 아키텍처 변경
- 운영 개선

모델은 목표, 사용자, 범위, 제약, 리스크, 인수 기준이 명확해질 때까지 질문해야 합니다.

### 2. Dev

`dev`는 계획이 승인된 뒤에만 사용합니다.

규칙은 다음과 같습니다.

- 변경은 최소화한다.
- 대상 프로젝트의 컨벤션을 따른다.
- 관련 없는 리팩터링을 피한다.
- secret을 포함하지 않는다.
- 파괴적 작업은 명시적 승인 전 수행하지 않는다.

### 3. Test

`test`는 기존 테스트를 실행하고, 부족한 검증 항목을 정의할 때 사용합니다.

테스트가 실패하거나 검증이 불완전하면 `dev`로 돌아갑니다.

### 4. Ops

`ops`는 배포, 관측성, 설정, 스케줄러, 외부 의존성, 롤백 리스크를 점검할 때 사용합니다.

운영 리스크가 남아 있으면 `dev` 또는 `document`로 돌아갑니다.

### 5. Document

`document`는 변경 사항에 맞게 문서를 갱신할 때 사용합니다.

작업 산출물에서 wiki 초안도 추출합니다.

### 6. Share

`share`는 커밋, push, PR, 팀 공유 요약을 준비할 때 사용합니다.

push, PR 생성, 외부 공유는 사람의 승인 없이 수행하지 않습니다.

## 작업 산출물

전체 흐름 작업은 다음 산출물을 생성하는 것을 기준으로 합니다.

```text
docs/work/YYYY-MM-DD-task/
├── input.yaml
├── 01-plan.md
├── 02-dev-result.md
├── 03-test-result.md
├── 04-ops-check.md
├── 05-summary.md
└── harness.json
```

실행 로그는 다음 위치에 기록합니다.

```text
.harness/runs/YYYYMMDD-HHMMSS-task/
├── run.json
├── commands.log
├── gates.log
├── decisions.md
└── errors.log
```

wiki 초안은 다음 위치에 생성합니다.

```text
docs/wiki/drafts/YYYY-MM-DD-task/
├── index.md
├── operation.md
├── development.md
└── onboarding.md
```

실패 학습은 다음 위치에 기록합니다.

```text
docs/wiki/drafts/lessons/YYYY-MM-DD.md
```

## Gate

기본 gate를 실행합니다.

```bash
scripts/harness/run-gates.sh
```

전체 작업 산출물을 기준으로 gate를 실행합니다.

```bash
scripts/harness/run-gates.sh --work-dir docs/work/YYYY-MM-DD-task
```

특정 단계 진입 gate를 실행합니다.

```bash
scripts/harness/run-gates.sh --work-dir docs/work/YYYY-MM-DD-task --stage test
```

최종 산출물 gate를 명시적으로 실행합니다.

```bash
scripts/harness/run-gates.sh --work-dir docs/work/YYYY-MM-DD-task --require-work-output
```

wiki 초안을 별도 경로에 생성합니다.

```bash
scripts/harness/run-gates.sh --work-dir docs/work/YYYY-MM-DD-task --require-work-output --wiki-dir /tmp/harness-wiki
```

`dev`, `test`, `ops`, `document` 단계 gate는 단계 진입 상태만 확인합니다. `share`, `pr` 단계는 최종 산출물까지 함께 확인합니다.

주요 gate는 다음과 같습니다.

- secret 탐지
- 작업 산출물 존재 여부
- 작업 산출물 품질
- wiki 초안 추출
- wiki 초안 검증
- 단계 진입 제어
- 실패 학습 수집

## 안전 규칙

다음 결정은 자동화하지 않습니다.

- 최종 PR 승인
- 최종 배포 결정
- wiki 승격
- 파괴적 파일 작업
- force push 또는 git history rewrite
- 데이터베이스 파괴적 변경
- secret/env/key 수정 또는 삭제
- 사용자 승인이 필요한 override

하네스는 판단을 보조합니다. 최종 결정은 사람이 합니다.

## Wiki 승격

초안은 최종 wiki 문서가 아닙니다.

승격은 수동으로만 진행합니다.

1. 사람이 초안을 검토한다.
2. 사람이 최종 wiki 문서를 작성하거나 수정한다.
3. 사람이 승인 메타데이터를 추가한다.
4. `check-wiki-promotion.sh`로 형식을 검증한다.
5. 사람이 PR에 포함한다.

스크립트는 초안을 이동하거나 승인하지 않습니다.

## 프롬프트 스타일

기본 프롬프트 스타일은 Caveman Lite입니다.

- 결론 먼저
- 짧은 문장
- 불필요한 인사 생략
- 반복 설명 생략
- 기술적 정확성 유지
- 코드, 로그, 에러 메시지는 훼손하지 않음

## 다른 프로젝트에 적용

새 프로젝트에 적용하는 기본 순서는 다음과 같습니다.

1. 이 저장소를 클론한다.
2. `./init.sh`를 실행한다.
3. 대상 프로젝트에서 `scripts/harness`를 복사하거나 참조한다.
4. 산출물을 유지하려면 대상 프로젝트에 `docs/work`, `docs/wiki`를 만든다.
5. skill이 참조하는 문서를 대상 프로젝트 기준으로 조정한다.
6. 반복적으로 발생하는 실제 리스크가 있을 때만 프로젝트 전용 gate를 추가한다.

기본 흐름은 유지하고, 도메인 규칙만 대상 프로젝트에 맞게 조정합니다.
