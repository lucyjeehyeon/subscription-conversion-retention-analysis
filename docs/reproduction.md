# 실행과 재현 범위

## 검증한 실행

Python 표준 라이브러리 기반 `scripts/reproduce_key_metrics.py`를 제공 마트에 실행해 첫 결제 4개 세그먼트, 전후 요약, 갱신 4개 조건의 집계를 확인했습니다. 원본 CSV는 읽기만 합니다. 출력은 집계 JSON뿐이며 개인별 행을 저장하지 않습니다.

```bash
python scripts/reproduce_key_metrics.py --data-dir "마트 폴더" --output results/key_metrics.json
```

## 핵심 결과 노트북

`notebooks/00_key_results.ipynb`는 포함된 `results/key_metrics.json`을 읽어 집계표를 보여줍니다. 원시 데이터가 없어도 Python 표준 라이브러리만으로 실행할 수 있습니다. 저장소 루트와 notebooks 폴더를 작업 폴더로 두는 경우 모두 실행을 확인했습니다. 원시 분석을 재실행하는 노트북은 아닙니다.

## 탐색 기록 노트북

`notebooks/archive/`의 노트북은 기존 탐색·제출 기록입니다. 본문은 순차 실행을 전제하고, 취합된 개인 부록은 순차 실행을 전제하지 않는다고 명시합니다. 개인 부록에는 반복 시도, 중간 변수와 월별 이벤트 파일 의존성이 남아 있어 **이번 정리에서는 보관본 전체 순차 실행을 검증하지 않았습니다.** 확정 수치와 해석은 README·핵심 결과 노트북·교정 발표본을 우선합니다.

정리한 내용:

- 모든 셀 출력, 실행 번호, Colab 및 위젯 메타데이터를 제거했습니다.
- Drive 계정 연결과 작업 폴더 변경을 기본 실행에서 제거했습니다.
- 설치 명령을 실행하지 않도록 주석 처리했습니다.
- 개인 Drive 경로를 로컬 `data/private` 경로로 바꾸었습니다.
- 코드의 원본 셀 번호를 각 셀의 `source_cell_index` 메타데이터에 남겼습니다.

Python을 저장소 루트에서 실행한다고 가정합니다. Jupyter 환경에서 재실행하려면 입력 파일과 작업 폴더를 먼저 맞춰 주세요. 노트북에서 사용하는 패키지는 `requirements-analysis.txt`에 적었으며 당시 고정 버전을 복원한 목록은 아닙니다.

## 입력

팀 본문은 아래 3개 마트를 사용합니다.

1. `dm_user_activation_payment.csv`
2. `dm_content_7d_performance.csv`
3. `dm_user_subscription_retention_core.csv`

개인 부록의 이벤트 분석에는 `event_log_thin_YYYY_MM.csv` 등 월별 로그와 콘텐츠 메타데이터가 추가로 필요합니다. 저장소에는 원본 데이터를 포함하지 않습니다. 데이터가 없으면 원 수치 전체를 다시 계산할 수 없습니다.

## 공개 파일 범위

코드·문서·집계 결과·스키마만 정리했습니다. 팀 코드·교육 자료에 일괄적인 오픈소스 라이선스를 임의로 붙이지 않았습니다. 원시 데이터가 Git에 추가되지 않도록 `.gitignore`를 설정했습니다.
