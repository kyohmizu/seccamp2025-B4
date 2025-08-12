# 演習1 環境の把握

- [演習1 環境の把握](#演習1-環境の把握)
  - [1 環境への接続確認](#1-環境への接続確認)
    - [1.1 Kubernetesクラスタ接続確認](#11-kubernetesクラスタ接続確認)
    - [1.2 無敗塾アプリケーション動作確認](#12-無敗塾アプリケーション動作確認)
    - [1.3 利用可能なツール確認](#13-利用可能なツール確認)
  - [2 利用可能なツールの探索](#2-利用可能なツールの探索)
    - [2.1 監視・ログ系ツール](#21-監視ログ系ツール)
    - [2.2 セキュリティ系ツール](#22-セキュリティ系ツール)
    - [2.3 CI/CD・開発系ツール](#23-cicd開発系ツール)
  - [次のステップ](#次のステップ)

この演習では、無敗塾の現在の環境を探索し、アプリケーションやOSSツールの構成を把握します。

## 1 環境への接続確認

### 1.1 Kubernetesクラスタ接続確認

まずは基本的な接続確認を行いましょう。

```bash
# クラスタ情報確認
kubectl version
kubectl cluster-info

# namespace確認
kubectl get namespaces

# 現在の権限確認
kubectl auth whoami
kubectl auth can-i get pods --namespace=seccamp-app
```

### 1.2 無敗塾アプリケーション動作確認

無敗塾のアプリケーションが実際に動いているかチェックしてみましょう。

```bash
# アプリケーション用namespaceの状態確認
kubectl get all -n seccamp-app
kubectl get services -n seccamp-app
kubectl get ingress -n seccamp-app
```

Webアプリケーションへのアクセス

https://app.seccamp.com:8082

### 1.3 利用可能なツール確認

どんなツールが用意されているか確認してみましょう。

```bash
# 全namespaceのPod確認
kubectl get pods -A

# 主要なnamespace
kubectl get namespaces

# 監視系ツール
kubectl get pods -n monitoring

# セキュリティ系ツール
kubectl get pods -n kube-system | grep tetragon
kubectl get pods -n openclarity

# CI/CD・開発系ツール
kubectl get pods -n gitlab
kubectl get pods -n harbor
kubectl get pods -n argocd
```

**確認ポイント**:
- [ ] Kubernetesクラスタにアクセスできる
- [ ] 無敗塾アプリケーションが動作している
- [ ] 利用可能なツール群を把握できた

## 2 利用可能なツールの探索

### 2.1 監視・ログ系ツール

実際に環境で動作している監視・ログツールを確認してみましょう。

```bash
# Grafana（ダッシュボード）
kubectl get pods -n monitoring | grep grafana

# Loki（ログ収集）
kubectl get pods -n monitoring | grep loki

# Kubernetes Events Exporter
kubectl get pods -n monitoring | grep events-exporter

# Metrics Server
kubectl get pods -n kube-system | grep metrics-server

# Hubble（ネットワーク可視化）
kubectl get pods -n kube-system | grep hubble
```

### 2.2 セキュリティ系ツール

セキュリティ関連のツールを探してみましょう。

```bash
# Tetragon（ランタイムセキュリティ・eBPF）
kubectl get pods -n kube-system | grep tetragon

# OpenClarity（セキュリティスキャン）
kubectl get pods -n openclarity

# Cilium（ネットワークセキュリティ・eBPF）
kubectl get pods -n kube-system | grep cilium
```

### 2.3 CI/CD・開発系ツール

開発・デプロイに関連するツールを確認してみましょう。

```bash
# GitLab（ソースコード管理・CI/CD）
kubectl get pods -n gitlab

# Harbor（コンテナレジストリ）
kubectl get pods -n harbor

# ArgoCD（GitOps）
kubectl get pods -n argocd
```

**確認ポイント**:

- [ ] どんなツールが動いているか（監視、セキュリティ、CI/CDなど）
- [ ] 無敗塾アプリケーションの構成
- [ ] その他、設定や構成で気になったこと

---

## 次のステップ

演習完了後、[2章 クラウドネイティブセキュリティの基礎](../02_cloud_native_sec/README.md) に進みます。
