# Helm package layout

공용 차트(`helm/stocat-service`) 아래에 서비스별 디렉터리를 두어 values 파일을
정리했습니다. 서비스에 공통으로 필요한 값은 `values.yaml`, 환경별 오버라이드는
같은 폴더 안에서 `<env>.values.yaml` 식으로 관리합니다.

```
helm/
├── stocat-service/                   # base chart
├── services/
│   ├── auth-api/
│   │   ├── values.yaml               # 서비스 기본값
│   │   └── local.values.yaml         # (예시) 로컬 환경 오버라이드
├── local.values.yaml                 # 모든 서비스 공통 로컬 값(선택)
└── legacy/                           # 과거 데모 values
```

## 배포 방법

1. 서비스 기본값 파일인 `helm/services/<service>/values.yaml`을 사용합니다.
   예: `helm/services/auth-api/values.yaml`.
2. 필요하면 같은 디렉터리 안에 `<env>.values.yaml` 파일을 만들어 환경별
   변경분을 정의하세요 (`local.values.yaml`, `prod.values.yaml` 등). 여러
   서비스가 공유할 환경 공통 값은 `helm/local.values.yaml`처럼 루트에 둡니다.
3. Helm 명령에서 베이스 chart와 values 파일들을 순서대로 넘깁니다.

   ```bash
   helm upgrade --install auth-api ./helm/stocat-service \
     --namespace stocat-dev --create-namespace \
     -f helm/services/auth-api/values.yaml \
     -f helm/local.values.yaml \                       # 공통 환경 값 (선택)
     -f helm/services/auth-api/local.values.yaml       # 서비스별 환경 값 (선택)
   ```

## 서비스 추가하기

1. `helm/services/<service>/values.yaml`을 만들고 `image.repository`,
   `image.tag`, `containerPort` 등 기본 값을 정의합니다.
2. 환경별로 값이 달라야 하면 같은 폴더에 `<env>.values.yaml` 파일을 추가합니다.
3. 배포 시 새로 만든 파일을 `-f` 옵션으로 순서대로 넘기면 됩니다.

서비스별 디렉터리로 정리해 두면 values 파일이 늘어나도 찾아보기 쉽고, 코드 변경과
배포 설정 변경을 같은 레포에서 함께 추적할 수 있습니다.

## Makefile 연동

- **로컬(kind) 배포**: 각 모듈의 `localhost/Makefile`이 Gradle 빌드 → Docker(`stocat/<service>:local`)
  → Kind 적재 → Helm 배포를 자동화합니다. 루트에서 `make helm-local-trade-api`나
  모듈에서 `make -C trade-api/localhost helm-deploy`를 실행하면, `helm/services/<service>/values.yaml`,
  `helm/local.values.yaml`, `helm/services/<service>/local.values.yaml`을 순서대로 적용하여
  `stocat-local` 클러스터/네임스페이스에 배포합니다.
- **운영/스테이징 배포**: `helm/Makefile`을 사용해 환경별 values 조합을 자동으로 구성합니다.
  `cd helm && make deploy SERVICE=trade-api ENV=prod`처럼 실행하면 기본 values에 더해
  `services/trade-api/prod.values.yaml`과 `prod.values.yaml`(존재 시)을 자동으로 포함하여
  설치/업데이트합니다. 릴리스를 삭제하려면 `make -C helm delete SERVICE=trade-api ENV=prod`
  를 사용하세요.
