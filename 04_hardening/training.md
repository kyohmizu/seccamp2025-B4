# 演習4 セキュリティ対策の導入

以下の演習課題の中から選ぶか、3章で検討したセキュリティ対策を実施してみましょう。

## 演習課題一覧

1. **[アドミッションコントロール](./trainings/admission_control.md)**: 難易度⭐︎⭐︎
   - Pod Security Admission（PSA）の設定
   - Validating Admission Policyの実装

2. **[ネットワークポリシー](./trainings/networkpolicy.md)**: 難易度⭐︎
   - 基本的なNetwork Policyの実装
   - Cilium Network Policyの活用

3. **[イメージセキュリティ](./trainings/image_security.md)**: 難易度⭐︎
   - コンテナイメージの脆弱性調査と修正
   - Distrolessイメージへの移行
   - CIでの自動脆弱性スキャン
   - イメージ署名と検証の実装
   - 実行環境のイメージ脆弱性管理

4. **[シークレット管理](./trainings/secret_management.md)**: 難易度⭐︎⭐︎⭐︎⭐︎
   - HashiCorp Vaultの導入
   - External Secrets Operatorの導入

5. **[認証・認可](./trainings/auth.md)**: 難易度⭐︎⭐︎⭐︎⭐︎
   - OIDC 認証の実装
   - 細やかなRBAC設計

6. **[ランタイムセキュリティ](./trainings/runtime_security.md)**: 難易度⭐︎⭐︎⭐︎
   - Tetragonによるプロセス監視
   - 監査ログの設定とアラート
   - コンテナランタイムセキュリティ

7. **[Kubernetesセキュリティポスチャー管理（KSPM）](./trainings/kspm.md)**: 難易度⭐︎
   - 現在のセキュリティポスチャーの評価
   - 高優先度のセキュリティ問題の修正
   - 継続的なコンプライアンス監視の検討

8. **[インシデント対応](./trainings/incident_response.md)**: 難易度⭐︎⭐︎⭐︎
   - 不審なPodの発見と初期対応、再発防止策の検討

9. **[ランサムウェア対策](./trainings/ransomware.md)**: 難易度⭐︎⭐︎
   - ランサムウェア脅威の分析
   - 予防的セキュリティ対策の実装
   - データ保護とバックアップ戦略

10. **[ペネトレーションテスト](./trainings/pentest.md)**: 難易度⭐︎⭐︎
    - シナリオに沿った攻撃演習
    - Pirates の検証
