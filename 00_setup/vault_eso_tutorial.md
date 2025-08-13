# Vault初期化とExternal Secrets設定例

## 1. Vaultへのアクセス確認
```bash
# Vault CLIでの接続確認
export VAULT_ADDR='https://vault.seccamp.com'
export VAULT_TOKEN="root"
vault status
```

## 2. Vault KV v2エンジンの確認と設定
```bash
# 既存のsecret engineを確認
vault secrets list

# 開発モードでは secret/ パスに KV v2 が既に有効になっている場合があります
# もし secret/ が存在しない場合のみ、以下のコマンドを実行：
# vault secrets enable -path=secret kv-v2

# シークレットの作成テスト
vault kv put secret/myapp/config \
  database-password="super-secret-password" \
  api-key="abc123def456"

# 作成したシークレットを確認
vault kv get secret/myapp/config
```

## 3. Vault用のポリシー作成
```bash
# External Secrets Operator用のポリシー作成
vault policy write external-secrets-policy - <<EOF
path "secret/data/*" {
  capabilities = ["read"]
}
path "secret/metadata/*" {
  capabilities = ["list", "read"]
}
EOF
```

## 4. Kubernetes認証方式の設定
```bash
# Kubernetes認証方式を有効化
vault auth enable kubernetes

# Vaultサービスアカウントを確認
kubectl get sa -n vault

# サービスアカウントトークンを直接取得
VAULT_SA_TOKEN=$(kubectl create token vault -n vault --duration=24h)

# Kubernetes認証の設定
vault write auth/kubernetes/config \
  token_reviewer_jwt="$VAULT_SA_TOKEN" \
  kubernetes_host="https://kubernetes.default.svc.cluster.local:443" \
  kubernetes_ca_cert="$(kubectl config view --raw --minify --flatten -o jsonpath='{.clusters[].cluster.certificate-authority-data}' | base64 --decode)"

# External Secrets Operator用のロール作成
vault write auth/kubernetes/role/external-secrets \
  bound_service_account_names=external-secrets \
  bound_service_account_namespaces=external-secrets-system \
  policies=external-secrets-policy \
  ttl=24h
```

## 5. 設定の適用手順
```bash
# ClusterSecretStoreを作成
cat <<EOF | kubectl apply -f -
apiVersion: external-secrets.io/v1
kind: ClusterSecretStore
metadata:
  name: vault-backend-cluster
spec:
  provider:
    vault:
      server: "http://vault.vault.svc.cluster.local:8200"
      path: "secret"
      version: "v2"
      auth:
        kubernetes:
          mountPath: "kubernetes"
          role: "external-secrets"
          serviceAccountRef:
            name: "external-secrets"
            namespace: "external-secrets-system"
EOF

# ExternalSecretを作成
cat <<EOF | kubectl apply -f -
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: myapp-secret
  namespace: seccamp-app
spec:
  refreshInterval: 30s
  secretStoreRef:
    name: vault-backend-cluster
    kind: ClusterSecretStore
  target:
    name: myapp-secret
    creationPolicy: Owner
  data:
  - secretKey: database-password
    remoteRef:
      key: secret/myapp/config
      property: database-password
  - secretKey: api-key
    remoteRef:
      key: secret/myapp/config
      property: api-key
EOF

# リソースの状態確認
kubectl get clustersecretstores vault-backend-cluster
kubectl get externalsecrets -n seccamp-app myapp-secret
kubectl get secrets -n seccamp-app myapp-secret
```
