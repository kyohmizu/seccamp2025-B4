# ランタイムセキュリティ

## 課題1: Tetragonによるプロセス監視と制限

コンテナ内での不正なプロセス実行や権限昇格攻撃を検出するため、eBPFベースのランタイム監視と制限を実装します。

参考: [seccamp2024-B6 - コンテナプロセスの監視と強制 (Tetragon)](https://github.com/kyohmizu/seccamp2024-B6/blob/master/ch04_hardening_k8s/training.md#%E3%82%B3%E3%83%B3%E3%83%86%E3%83%8A%E3%83%97%E3%83%AD%E3%82%BB%E3%82%B9%E3%81%AE%E7%9B%A3%E8%A6%96%E3%81%A8%E5%BC%B7%E5%88%B6-tetragon)

### ステップ
1. 以下のポリシーを作成してください
   - 予期しないシェル（bash、sh）の実行
   - 権限昇格の試行（sudo、su コマンド）
   - 想定していない外部通信の禁止
   - システムファイルへの書き込み試行
2. **[発展]** Tetragonのアラートをログ収集システムに統合してください

## 課題2: 監査ログの設定とアラート

Kubernetes APIサーバーの監査ログから不審な活動を検出し、迅速な対応を可能にするアラートシステムが必要です。

参考: [seccamp2024-B6 - 監査ログの確認](https://github.com/kyohmizu/seccamp2024-B6/blob/master/ch04_hardening_k8s/training.md#%E7%9B%A3%E6%9F%BB%E3%83%AD%E3%82%B0%E3%81%AE%E7%A2%BA%E8%AA%8D)

### ステップ
1. Kubernetes監査ログが有効になっており、Grafana上で可視化されていることを確認してください
2. 以下のイベントを検出するログアラートを設定してください
   - 権限のないリソースへのアクセス試行
   - シークレットやConfigMapへの不正アクセス
   - クラスタレベルの権限変更
3. **[発展]** 偽陽性を減らすためのフィルタリングルールを検討してください

## 課題3: コンテナランタイムセキュリティ

参考: [seccamp2024-B6 - seccomp の設定](https://github.com/kyohmizu/seccamp2024-B6/blob/master/ch04_hardening_k8s/training.md#seccomp-%E3%81%AE%E8%A8%AD%E5%AE%9A)

### ステップ
1. seccompプロファイルを活用してシステムコールを制限してください
2. **[発展]** ルートレスコンテナの導入を検討してください
3. **[発展]** コンテナランタイム（containerd）のセキュリティ設定を強化してください
