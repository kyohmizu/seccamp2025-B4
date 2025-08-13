# シークレット管理

## 課題1: HashiCorp Vaultの導入

### ステップ
1. HashiCorp Vaultをクラスタにインストールし、初期設定を実施してください
2. **[発展]** 適切な権限ポリシーを設定し、最小権限の原則を適用してください

## 課題2: External Secrets Operatorの導入

### ステップ
1. External Secrets Operatorをクラスタにインストールしてください
2. VaultからKubernetes Secretsへの同期を設定してください
3. アプリケーションのマニフェストを修正し、Vaultから取得されるシークレットを使用するようにしてください
4. **[発展]** シークレットのローテーションを検討してください

ヒント: [Vault初期化とExternal Secrets設定例](../../00_setup/vault_eso_tutorial.md)
