# 演習2 クラウドネイティブセキュリティの基礎

- [演習2 クラウドネイティブセキュリティの基礎](#演習2-クラウドネイティブセキュリティの基礎)
  - [目標](#目標)
  - [0 事前準備](#0-事前準備)
  - [1. コンテナセキュリティ](#1-コンテナセキュリティ)
    - [1.1 コンテナの要素技術を理解する](#11-コンテナの要素技術を理解する)
      - [1.1.1 Namespaceの確認](#111-namespaceの確認)
      - [1.1.2 Cgroupの確認](#112-cgroupの確認)
      - [1.1.3 Capabilitiesの確認](#113-capabilitiesの確認)
    - [1.2 Dockerfileセキュリティスキャン](#12-dockerfileセキュリティスキャン)
      - [1.2.1 セキュアでないDockerfileの作成](#121-セキュアでないdockerfileの作成)
      - [1.2.2 Trivyを使用したDockerfileスキャン](#122-trivyを使用したdockerfileスキャン)
      - [1.2.3 セキュアなDockerfileの作成](#123-セキュアなdockerfileの作成)
  - [2. Kubernetesセキュリティ](#2-kubernetesセキュリティ)
    - [2.1 Kubernetesクラスタのセキュリティスキャン](#21-kubernetesクラスタのセキュリティスキャン)
      - [2.1.1 Trivyを使用したクラスタスキャン](#211-trivyを使用したクラスタスキャン)
      - [2.1.2 検出された問題の分析](#212-検出された問題の分析)
    - [2.2 Kubernetes APIサーバーへの直接アクセス](#22-kubernetes-apiサーバーへの直接アクセス)
      - [2.2.1 APIサーバーの情報取得](#221-apiサーバーの情報取得)
      - [2.2.2 認証なしでのアクセス試行](#222-認証なしでのアクセス試行)
      - [2.2.3 証明書を使用した認証](#223-証明書を使用した認証)
    - [2.3 Kubernetes認可（RBAC）の理解](#23-kubernetes認可rbacの理解)
      - [2.3.1 現在のユーザー権限の確認](#231-現在のユーザー権限の確認)
      - [2.3.2 制限されたServiceAccountの作成](#232-制限されたserviceaccountの作成)
      - [2.3.3 カスタムRoleの作成と権限制御](#233-カスタムroleの作成と権限制御)
      - [2.3.4 名前空間を跨いだ権限の確認](#234-名前空間を跨いだ権限の確認)
      - [2.3.5 権限のないアクセスの確認](#235-権限のないアクセスの確認)
      - [2.3.6 クリーンアップ](#236-クリーンアップ)
  - [次のステップ](#次のステップ)


本演習では、クラウドネイティブセキュリティの基盤となるコンテナとKubernetesのセキュリティ機能を実際に体験し、理解を深めます。

## 目標

- コンテナの要素技術（namespace, cgroup, capabilities）を理解する
- Dockerfileのセキュリティベストプラクティスを学習する
- Kubernetesクラスタのセキュリティ状態を評価する方法を習得する
- Kubernetes APIサーバーの認証・認可の仕組みを理解する

---

## 0 事前準備

作業ディレクトリを作成し、ディレクトリ内でファイル作成等の作業をしてください。

```bash
mkdir -p /root/<name>/02
cd /root/<name>/02
```

## 1. コンテナセキュリティ

### 1.1 コンテナの要素技術を理解する

コンテナの基盤となるLinuxの機能（namespace, cgroup, capabilities）を実際に確認してみましょう。

#### 1.1.1 Namespaceの確認

**ホストのnamespaceを確認**

```bash
# 現在のnamespaceを確認
ls -la /proc/$$/ns/
```

**unshareコマンドで新しいnamespaceを作成**

```bash
# PIDとネットワークnamespaceを分離した環境を作成
sudo unshare --pid --net --fork --mount-proc bash

# 新しいnamespace内でプロセスを確認
ps aux
# → PID 1として新しいbashプロセスが表示されることを確認

# ネットワークインターフェースを確認
ip addr show
# → loopbackインターフェースのみが表示されることを確認

exit
```

**コンテナ内でのnamespace確認**

```bash
# コンテナを起動してnamespaceを確認
docker run -it --rm alpine:latest sh

# コンテナ内でプロセスを確認
ps aux

# ネットワークを確認
ip addr show

# namespaceを確認
ls -la /proc/1/ns/

exit

# ホストのnamespaceと比較
ls -la /proc/$$/ns/
```

#### 1.1.2 Cgroupの確認

**cgroupの制限を確認**

```bash
# メモリ制限を設定してコンテナを起動
docker run -it --rm --memory=128m alpine:latest sh

# コンテナ内でメモリ制限を確認
cat /sys/fs/cgroup/memory.max

exit

# CPU制限を設定してコンテナを起動（別ターミナル）
docker run -it --rm --cpus=0.5 alpine:latest sh

# CPU制限を確認
cat /sys/fs/cgroup/cpu.max
# <quota> <period> の形式で表示される
# quota / period = 0.5 (50%制限) となることを確認

exit
```

**リソース制限の動作確認**

```bash
# メモリを大量消費するプロセスを実行
docker run --memory=64m --rm alpine:latest sh -c "apk add --no-cache python3; python3 -c 'x = b\"a\" * 1024 * 1024 * 80'"
# → メモリ制限によりプロセスが停止することを確認
dmesg
```

#### 1.1.3 Capabilitiesの確認

**デフォルトのcapabilitiesを確認**

```bash
# 通常のコンテナでcapabilitiesを確認
docker run -it --rm alpine:latest sh -c "apk add --no-cache libcap && capsh --print" | grep sys_admin

# 特権コンテナでcapabilitiesを確認
docker run -it --rm --privileged alpine:latest sh -c "apk add --no-cache libcap && capsh --print" | grep sys_admin
```

**特定のcapabilityを追加/削除**

```bash
# NET_ADMINを追加してネットワーク設定を変更
docker run -it --rm alpine:latest sh -c "ip link add dummy0 type dummy && ip link show dummy0"
docker run -it --rm --cap-add=NET_ADMIN alpine:latest sh -c "ip link add dummy0 type dummy && ip link show dummy0"

# CHOWNを削除
docker run -it --rm alpine:latest sh -c "touch /tmp/test && chown nobody /tmp/test" 2>&1
docker run -it --rm --cap-drop=CHOWN alpine:latest sh -c "touch /tmp/test && chown nobody /tmp/test" 2>&1
```

### 1.2 Dockerfileセキュリティスキャン

#### 1.2.1 セキュアでないDockerfileの作成

まず、セキュリティ上の問題を含むDockerfileを作成します。

```bash
cat << 'EOF' > Dockerfile.insecure
FROM ubuntu:latest

# rootユーザーでアプリケーションを実行
USER root

# 不要なパッケージをインストール
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    telnet \
    ftp \
    vim \
    git \
    && rm -rf /var/lib/apt/lists/*

# 機密情報をハードコード
ENV API_KEY=sk-1234567890abcdef
ENV DATABASE_PASSWORD=secret123

# 広範囲のポートを公開
EXPOSE 22 80 443 3306 5432

# rootでアプリケーションを実行
CMD ["sleep", "infinity"]
EOF
```

#### 1.2.2 Trivyを使用したDockerfileスキャン

```bash
# Dockerfileの設定不備をスキャン
trivy config Dockerfile.insecure
```

#### 1.2.3 セキュアなDockerfileの作成

検出された問題を修正したDockerfileを作成します。

```bash
cat << 'EOF' > Dockerfile.secure
# 具体的なバージョンを指定
FROM ubuntu:22.04

# セキュリティパッチを適用
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# 非root ユーザーを作成
RUN groupadd -r appgroup && useradd -r -g appgroup -s /bin/false appuser

# アプリケーションディレクトリを作成
WORKDIR /app

# ファイルの所有者を設定
COPY --chown=appuser:appgroup . .

# 必要なポートのみ公開
EXPOSE 8080

# 非rootユーザーに変更
USER appuser

# アプリケーションを実行
CMD ["sleep", "infinity"]
EOF
```

```bash
# 修正後のDockerfileをスキャン
trivy config Dockerfile.secure
```

## 2. Kubernetesセキュリティ

### 2.1 Kubernetesクラスタのセキュリティスキャン

#### 2.1.1 Trivyを使用したクラスタスキャン

```bash
# クラスタ全体のセキュリティ設定をスキャン
trivy k8s --tolerations node-role.kubernetes.io/control-plane=:NoSchedule --report summary --timeout=1h

# 特定のNamespaceをスキャン
trivy k8s --include-namespaces kube-system --tolerations node-role.kubernetes.io/control-plane=:NoSchedule --report summary --timeout=1h

# より詳細な結果を出力（ファイルサイズが非常に大きくなるため注意）
trivy k8s --tolerations node-role.kubernetes.io/control-plane=:NoSchedule --report all --timeout=1h > cluster-security-report.txt

# 結果を確認
cat cluster-security-report.txt
```

#### 2.1.2 検出された問題の分析

```bash
# CISベンチマークに基づく検証
trivy k8s --compliance=k8s-cis-1.23 --tolerations node-role.kubernetes.io/control-plane=:NoSchedule --report summary

# Pod Security Standards（Baseline）に基づく検証  
trivy k8s --compliance=k8s-pss-baseline-0.1 --tolerations node-role.kubernetes.io/control-plane=:NoSchedule --report summary
```

### 2.2 Kubernetes APIサーバーへの直接アクセス

kubectlを使わずに、直接APIサーバーにアクセスして認証・認可の仕組みを理解します。

#### 2.2.1 APIサーバーの情報取得

```bash
# APIサーバーのエンドポイントを確認
kubectl cluster-info

# APIサーバーのURLを変数に設定（適宜修正）
export API_SERVER=$(kubectl cluster-info | grep "Kubernetes control plane" | awk '{print $7}')
echo "API Server: $API_SERVER"
```

#### 2.2.2 認証なしでのアクセス試行

```bash
# 認証なしでAPIサーバーにアクセス（403が返される）
curl -k $API_SERVER/api/v1/pods
```

#### 2.2.3 証明書を使用した認証

```bash
# kubeconfigの内容を表示
kubectl config view --raw

# kubeconfigからクライアント証明書とキーを抽出
kubectl config view --raw -o jsonpath='{.users[0].user.client-certificate-data}' | base64 -d > kube-client.crt
kubectl config view --raw -o jsonpath='{.users[0].user.client-key-data}' | base64 -d > kube-client.key
kubectl config view --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' | base64 -d > kube-ca.crt

# 証明書を使用してAPIサーバーにアクセス
curl --cert kube-client.crt \
     --key kube-client.key \
     --cacert kube-ca.crt \
     $API_SERVER/api/v1/namespaces

# Podの一覧を取得
curl --cert kube-client.crt \
     --key kube-client.key \
     --cacert kube-ca.crt \
     $API_SERVER/api/v1/pods
```

### 2.3 Kubernetes認可（RBAC）の理解

Kubernetesの認可機能であるRBACの動作を実際に確認し、最小権限の原則について学習します。

#### 2.3.1 現在のユーザー権限の確認

```bash
# 現在のユーザーで実行可能な操作を確認
kubectl auth can-i get pods
kubectl auth can-i create pods
kubectl auth can-i delete pods
kubectl auth can-i get secrets -n kube-system

# すべての権限を一覧表示
kubectl auth can-i --list

# 特定のNamespaceでの権限を確認
kubectl auth can-i --list -n kube-system
```

#### 2.3.2 制限されたServiceAccountの作成

```bash
# 制限されたServiceAccountを作成
kubectl create serviceaccount limited-sa

# 現在のServiceAccountの権限を確認（権限なし）
kubectl auth can-i get pods --as=system:serviceaccount:default:limited-sa

# view権限のみを付与するRoleBindingを作成
kubectl create rolebinding limited-binding \
  --clusterrole=view \
  --serviceaccount=default:limited-sa

# 権限付与後の確認
kubectl auth can-i get pods --as=system:serviceaccount:default:limited-sa
kubectl auth can-i create pods --as=system:serviceaccount:default:limited-sa
kubectl auth can-i delete pods --as=system:serviceaccount:default:limited-sa
```

#### 2.3.3 カスタムRoleの作成と権限制御

```bash
# Pod読み取り専用のRoleを作成
kubectl create role pod-reader \
  --verb=get,list,watch \
  --resource=pods

# ServiceAccountにカスタムRoleを割り当て
kubectl create serviceaccount custom-sa
kubectl create rolebinding custom-binding \
  --role=pod-reader \
  --serviceaccount=default:custom-sa

# カスタムRoleの権限を確認
kubectl auth can-i get pods --as=system:serviceaccount:default:custom-sa
kubectl auth can-i create pods --as=system:serviceaccount:default:custom-sa
kubectl auth can-i get services --as=system:serviceaccount:default:custom-sa

# 権限の詳細を確認
kubectl auth can-i --list --as=system:serviceaccount:default:custom-sa
```

#### 2.3.4 名前空間を跨いだ権限の確認

```bash
# test Namespaceを作成
kubectl create namespace test

# defaultのみで有効なRoleBindingの動作確認
kubectl auth can-i get pods --as=system:serviceaccount:default:custom-sa -n default
kubectl auth can-i get pods --as=system:serviceaccount:default:custom-sa -n test

# クラスター全体で有効なClusterRoleBindingを作成
kubectl create clusterrolebinding cluster-pod-reader \
  --clusterrole=view \
  --serviceaccount=default:cluster-sa

kubectl create serviceaccount cluster-sa

# 異なるNamespaceでの権限を確認
kubectl auth can-i get pods --as=system:serviceaccount:default:cluster-sa -n default
kubectl auth can-i get pods --as=system:serviceaccount:default:cluster-sa -n test
kubectl auth can-i get pods --as=system:serviceaccount:default:cluster-sa -n kube-system
```

#### 2.3.5 権限のないアクセスの確認

```bash
# 権限のないリソースへのアクセスを試行
kubectl auth can-i create secrets --as=system:serviceaccount:default:limited-sa
kubectl auth can-i delete nodes --as=system:serviceaccount:default:limited-sa

# 実際にPodを作成して権限制限を確認
cat << EOF > test-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: test-rbac-pod
spec:
  serviceAccountName: limited-sa
  containers:
  - name: test
    image: alpine:latest
    command: ["sleep", "3600"]
EOF

kubectl apply -f test-pod.yaml

# Podにexec
kubectl exec -it test-rbac-pod -- /bin/sh

# Pod内からkubectl操作を試行
wget -qO /tmp/kubectl https://dl.k8s.io/release/v1.33.3/bin/linux/amd64/kubectl
chmod +x /tmp/kubectl
/tmp/kubectl get pods
/tmp/kubectl auth whoami

# ServiceAccountの認証情報
ls /var/run/secrets/kubernetes.io/serviceaccount/

exit
```

#### 2.3.6 クリーンアップ

```bash
# 作成したリソースを削除
kubectl delete pod test-rbac-pod --ignore-not-found
kubectl delete serviceaccount limited-sa custom-sa cluster-sa --ignore-not-found
kubectl delete rolebinding limited-binding custom-binding --ignore-not-found
kubectl delete clusterrolebinding cluster-pod-reader --ignore-not-found
kubectl delete role pod-reader --ignore-not-found
kubectl delete namespace test --ignore-not-found
```

---

## 次のステップ

演習完了後、[3章 セキュリティアセスメント](../03_security_assessment/README.md) に進みます。
