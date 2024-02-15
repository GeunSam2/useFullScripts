# kube config 파일 업데이트 스크립트

kube config를 최신 정보로 업데이트하고, aws-vault 명령어를 내장시켜서 kubectl을 바로 사용할 수 있게 해요.
lens와 호환성도 좋아요.

## 의존성

- yq(https://github.com/mikefarah/yq/) >= v4.0
- jq(https://jqlang.github.io/jq) tested at v1.7.1
- bash

> install

```bash
# mac
brew install yq
brew install jq
```

## 사용법

- 옵션
  - `--clear-contexts` : 불필요한 context들을 정리합니다.
  - 끝

```bash
chmod +x ./update-kubeconfig-info-with-vault.sh #이름은 알아서...
./update-kubeconfig-info-with-vault.sh [--clear-contexts]
```
