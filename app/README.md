# オンライン学習サービス サンプルアプリケーション

このディレクトリは、Kubernetes上で動作するオンライン学習サービスのサンプルWebアプリケーションです。

## 構成
- バックエンド: Python (FastAPI)
- フロントエンド: React (TypeScript)
- データベース: MariaDB
- 認証: JWTベース
- CI/CD: GitHub Actions
- デプロイ: Kubernetesマニフェスト/Helmチャート

## サービス機能
- ユーザー登録・ログイン
- コース一覧・詳細表示
- 学習進捗管理
- 管理者による教材登録
- APIエンドポイント（REST）
- 管理画面（管理者用UI）

## ディレクトリ構成
- backend/   ... FastAPI サーバー
- frontend/  ... React UI
- manifests/ ... Kubernetes用マニフェスト
- db/        ... MariaDB用初期化SQL等
- .github/   ... CI/CDワークフロー
