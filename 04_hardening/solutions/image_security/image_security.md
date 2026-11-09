# イメージセキュリティ

## 課題1: コンテナイメージの脆弱性調査と修正

現在使用されているコンテナイメージには、既知の脆弱性が含まれている可能性があります。

### ステップ
1. アプリケーション（frontend, backend, db）のコンテナイメージの脆弱性スキャンを実施してください
2. ベースイメージのバージョンアップによって解決できる脆弱性を修正してください
3. DBイメージの脆弱性を解消する方法を検討してください
4. 修正前後での脆弱性数を比較してください
5. アプリケーションが修正後のイメージで正常に動作することを確認してください

## 課題2: Distrolessイメージへの移行

現在のイメージには不要なパッケージやツールが含まれており、攻撃対象領域が大きくなっています。

### ステップ
1. アプリケーションをDistrolessベースイメージに移行してください
2. 移行前後でのイメージサイズと脆弱性数の変化を比較してください
3. アプリケーションが修正後のイメージで正常に動作することを確認してください

## 課題3: CIでの自動脆弱性スキャン

開発サイクルの中で継続的にセキュリティを確保するため、CI/CDパイプラインに脆弱性スキャンを組み込む必要があります。

### ステップ
1. CIパイプラインにTrivyによる脆弱性スキャンを組み込んでください
2. スキャン結果のレポートを後から見れるように出力してください
3. **[発展]** 脆弱性が検出された場合のビルド失敗条件を検討してください

## 課題4: イメージ署名と検証の実装

コンテナイメージの改ざんや不正なイメージの実行を防ぐため、イメージ署名と検証機能を導入する必要があります。

### ステップ
1. Cosignを使用してCIパイプラインでコンテナイメージに署名してください
2. Harbor レジストリで署名のないイメージのプルを禁止する設定を行ってください
3. **[発展]** 署名キーの管理を検討してください

<details><summary>解答例: CIパイプラインでの脆弱性スキャン・イメージ署名の実装</summary>

```yaml
stages:
  - build
  - security-scan
  - push
  - sign

variables:
  HARBOR_REGISTRY: harbor.seccamp.com
  HARBOR_PROJECT: seccamp2025
  IMAGE_NAME: $HARBOR_REGISTRY/$HARBOR_PROJECT/seccamp-backend
  DOCKER_CONFIG: /kaniko/.docker/

build-image:
  stage: build
  image:
    name: gcr.io/kaniko-project/executor:debug
  script:
    - /kaniko/executor --context $CI_PROJECT_DIR --dockerfile $CI_PROJECT_DIR/Dockerfile --tarPath image.tar --no-push --ignore-path /product_uuid
  artifacts:
    paths:
      - image.tar
    expire_in: 2 hours
  only:
    - main

build-image-tag:
  stage: build
  image:
    name: gcr.io/kaniko-project/executor:debug
  script:
    - /kaniko/executor --context $CI_PROJECT_DIR --dockerfile $CI_PROJECT_DIR/Dockerfile --tarPath image.tar --no-push --ignore-path /product_uuid
  artifacts:
    paths:
      - image.tar
    expire_in: 2 hours
  only:
    - tags

trivy-scan:
  stage: security-scan
  image:
    name: aquasec/trivy:latest
    entrypoint: [""]
  script:
    - trivy image --exit-code 0 --format table --input image.tar
    # 重要度HIGH以上の脆弱性でCI/CDを失敗させる（本格運用時は有効化）
    # - trivy image --exit-code 1 --severity HIGH,CRITICAL --input image.tar
    - trivy image --format json --output trivy-report.json --input image.tar
  artifacts:
    reports:
      container_scanning: trivy-report.json
    paths:
      - trivy-report.json
    expire_in: 1 week
  rules:
    - if: $CI_COMMIT_REF_NAME == "main"
      needs: ["build-image"]
    - if: $CI_COMMIT_TAG
      needs: ["build-image-tag"]

push-image:
  stage: push
  image:
    name: quay.io/skopeo/stable:latest
    entrypoint: [""]
  script:
    - |
      cat > /tmp/auth.json <<EOF
      {
        "auths": {
          "${HARBOR_REGISTRY}": {
            "auth": "$(echo -n ${HARBOR_USER}:${HARBOR_PASSWORD} | base64 -w 0)"
          }
        }
      }
      EOF
    - |
      if [ "$CI_COMMIT_REF_NAME" = "main" ]; then
        echo "Pushing to: $IMAGE_NAME:$CI_COMMIT_SHORT_SHA"
        skopeo copy --dest-tls-verify=false --authfile=/tmp/auth.json docker-archive:image.tar docker://$IMAGE_NAME:$CI_COMMIT_SHORT_SHA
      else
        echo "Pushing to: $IMAGE_NAME:$CI_COMMIT_REF_NAME"
        skopeo copy --dest-tls-verify=false --authfile=/tmp/auth.json docker-archive:image.tar docker://$IMAGE_NAME:$CI_COMMIT_REF_NAME
      fi
  rules:
    - if: $CI_COMMIT_REF_NAME == "main"
      needs: 
        - job: build-image
          artifacts: true
        - job: trivy-scan
          artifacts: false
    - if: $CI_COMMIT_TAG
      needs: 
        - job: build-image-tag
          artifacts: true
        - job: trivy-scan
          artifacts: false

cosign-sign:
  stage: sign
  image:
    name: alpine:3.18
  timeout: 10m
  before_script:
    # Cosignのインストール
    - apk add --no-cache curl
    - |
      COSIGN_VERSION="v2.2.2"
      curl -O -L "https://github.com/sigstore/cosign/releases/download/${COSIGN_VERSION}/cosign-linux-amd64"
      mv cosign-linux-amd64 /usr/local/bin/cosign
      chmod +x /usr/local/bin/cosign
    - |
      # 認証ファイル作成（Cosignでもレジストリアクセスが必要）
      cat > /tmp/auth.json <<EOF
      {
        "auths": {
          "${HARBOR_REGISTRY}": {
            "auth": "$(echo -n ${HARBOR_USER}:${HARBOR_PASSWORD} | base64 -w 0)"
          }
        }
      }
      EOF
    - export DOCKER_CONFIG=/tmp
    - |
      # Docker config.jsonファイルを直接作成
      mkdir -p /tmp/.docker
      cp /tmp/auth.json /tmp/.docker/config.json
    - export DOCKER_CONFIG=/tmp/.docker
    - |
      # Cosign用のキーペアを動的に生成（デモ用）
      COSIGN_PASSWORD="" cosign generate-key-pair
    - ls -la cosign.key cosign.pub
  script:
    - |
      # イメージURIの設定
      if [ "$CI_COMMIT_REF_NAME" = "main" ]; then
        IMAGE_URI="$IMAGE_NAME:$CI_COMMIT_SHORT_SHA"
      else
        IMAGE_URI="$IMAGE_NAME:$CI_COMMIT_REF_NAME"
      fi
      echo "Signing image: $IMAGE_URI"
    - |
      # キーペア署名（transparency logを無効化、SSL証明書検証を無効化）
      COSIGN_PASSWORD="" cosign sign --key cosign.key --tlog-upload=false --allow-insecure-registry --registry-username=${HARBOR_USER} --registry-password=${HARBOR_PASSWORD} $IMAGE_URI
    - |
      # 署名の検証（transparency logを無視、SSL証明書検証を無効化）
      cosign verify --key cosign.pub --insecure-ignore-tlog=true --allow-insecure-registry --registry-username=${HARBOR_USER} --registry-password=${HARBOR_PASSWORD} $IMAGE_URI
  artifacts:
    paths:
      - cosign.pub
    expire_in: 1 week
  rules:
    - if: $CI_COMMIT_REF_NAME == "main"
      needs: 
        - job: push-image
          artifacts: false
    - if: $CI_COMMIT_TAG
      needs: 
        - job: push-image
          artifacts: false
```

</details>

## 課題5: 実行環境のイメージ脆弱性管理

Openclarity を使い、実行環境で実際に動作しているコンテナのイメージ脆弱性を確認してみましょう。

### ステップ
1. helmfileのコメントアウトを外し、Openclarity をhelmfileでインストールします
2. ブラウザから Openclarity のWeb UIにアクセスし、イメージ脆弱性のスキャンを実施します

```bash
cd /root/helm
helmfile sync --selector app=openclarity

# ブラウザからアクセス
https://openclarity.seccamp.com:8082
```
