# ネットワークポリシー

## 課題1: 基本的なNetwork Policyの実装

現在のクラスタではすべてのPod間で自由な通信が可能になっています。セキュリティを向上させるため、最小権限の原則に基づいたネットワーク制御を実装しましょう。

### ステップ
1. フロントエンドからデータベースへの直接アクセスを禁止するNetwork Policyを作成してください
2. データベースへはバックエンドからのみアクセスを許可するポリシーを設定してください
3. 外部インターネットへの不要な通信を制限してください
4. 許可されていない通信がブロックされることを確認してください

<details><summary>解答例: フロントエンドのNetworkPolicy</summary>

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: frontend-netpol
  namespace: seccamp-app
spec:
  podSelector:
    matchLabels:
      app: frontend
  policyTypes:
  - Ingress
  - Egress
  ingress:
  # 外部からのHTTPアクセスを許可
  - from: []
    ports:
    - protocol: TCP
      port: 80
  egress:
  # DNS解決を許可
  - to: []
    ports:
    - protocol: UDP
      port: 53
  # バックエンドAPIへのアクセスを許可
  - to:
    - podSelector:
        matchLabels:
          app: backend
    ports:
    - protocol: TCP
      port: 8000
```

</details>

## 課題2: Cilium Network Policyの活用

標準のKubernetes Network PolicyよりもCilium Network Policyは豊富な機能を提供します。

### ステップ
1. Cilium Network PolicyでL7（HTTP）レベルの通信制御を実装してください
2. APIエンドポイント単位でのアクセス制御を設定してください

<details><summary>ヒント: バックエンドのNetworkPolicy（作成途中）</summary>

```yaml
apiVersion: "cilium.io/v2"
kind: CiliumNetworkPolicy
metadata:
  name: backend-l7-policy
  namespace: seccamp-app
spec:
  endpointSelector:
    matchLabels:
      app: backend
  ingress:
  # フロントエンドからのHTTPリクエスト受信
  - fromEndpoints:
    toPorts:
    - ports:
      - port: "8000"
        protocol: TCP
      rules:
        http:
        # 受信を許可するAPIエンドポイント
        - method: "GET"
          path: "/admin/users"
```

</details>
