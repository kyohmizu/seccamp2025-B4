# アドミッションコントロール

## 課題1: Pod Security Admission (PSA) の設定

現在のKubernetesクラスタでは、セキュリティ要件を満たさないPodがデプロイされる可能性があります。Pod Security Admissionを活用して、Pod Securityの準拠状況を確認してみましょう。

参考: [seccamp2024-B6 - Pod Security Standards の適用](https://github.com/kyohmizu/seccamp2024-B6/blob/master/ch04_hardening_k8s/training.md#pod-security-standards-%E3%81%AE%E9%81%A9%E7%94%A8)

### ステップ
1. 現在の`default`名前空間にPod Security Admissionを設定し、`restricted`レベルを適用してください
2. 特権コンテナや特権昇格を許可するPodをデプロイしようとした際の動作を確認してください
3. `warn`と`audit`モードの違いを理解し、段階的な適用戦略を検討してください

## 課題2: Validating Admission Policy (VAP) の実装

CISベンチマークやセキュリティベストプラクティスに基づいた、より細かいポリシーを適用する必要があります。Validating Admission Policyを使用して、組織固有のセキュリティルールを実装してみましょう。

### ステップ
1. 以下の要件を満たすValidating Admission Policyを作成してください：
   - securityContextが設定されていることを強制
   - readOnlyRootFilesystemが有効になっていることを確認
   - コンテナイメージは信頼できるレジストリからのみ許可
2. ポリシー違反のリソースをデプロイしようとした際の動作を確認してください

<details><summary>ヒント: VAPの実装例</summary>

`app` キーのラベルを持たない Pod の作成を拒否するVAP ポリシーを適用。

```bash
kubectl apply -f - <<EOF
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicy
metadata:
  name: deny-missing-app-label-pod
spec:
  variables:
  - name: podName
    expression: |
      object.metadata.name
  matchConditions:
  - name: exclude-app
    expression: |
      object.metadata.?labels[?'exclude-missing-app-label'].orValue('') == ""
  matchConstraints:
    resourceRules:
    - apiGroups: [""]
      apiVersions: ["v1"]
      resources: ["pods"]
      operations: ["CREATE"]
  validations:
  - expression: |
      object.metadata.?labels[?'app'].orValue('') != ""
    messageExpression: "'Pod ' + variables.podName + ' must have app labels'"
  auditAnnotations:
  - key: "pod-name"
    valueExpression: "'Pod ' + variables.podName + ' have app label'"
---
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicyBinding
metadata:
  name: deny-missing-app-label-pod
spec:
  policyName: deny-missing-app-label-pod
  validationActions: [Deny]
  matchResources:
    namespaceSelector:
      matchLabels:
        kubernetes.io/metadata.name: default
EOF
```

サンプルPodのデプロイ

```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: sample-pod1
  labels:
    app: nginx
spec:
  securityContext:
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: nginx
    image: cgr.dev/chainguard/nginx:latest
---
apiVersion: v1
kind: Pod
metadata:
  name: sample-pod2
  labels:
    exclude-missing-app-label: "true"
spec:
  securityContext:
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: nginx
    image: cgr.dev/chainguard/nginx:latest
    securityContext:
      allowPrivilegeEscalation: false
      runAsNonRoot: true
      capabilities:
        drop: ["ALL"]
        add: ["NET_BIND_SERVICE"]
---
apiVersion: v1
kind: Pod
metadata:
  name: sample-pod3
spec:
  securityContext:
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: nginx
    image: cgr.dev/chainguard/nginx:latest
    securityContext:
      allowPrivilegeEscalation: false
      runAsNonRoot: true
      capabilities:
        drop: ["ALL"]
        add: ["NET_BIND_SERVICE"]
EOF
```

デプロイ結果を確認してください。
- pod1 はデプロイ成功（ルール準拠）
- pod2 はデプロイ成功（例外設定）
- pod3 はデプロイ失敗

```bash
pod/sample-pod1 created
pod/sample-pod2 created
The pods "sample-pod3" is invalid: : ValidatingAdmissionPolicy 'deny-missing-app-label-pod' with binding 'deny-missing-app-label-pod' denied request: Pod sample-pod3 must have app labels
```

クリーンアップ

```bash
kubectl delete pod sample-pod1 sample-pod2
kubectl delete validatingadmissionpolicies deny-missing-app-label-pod
kubectl delete validatingadmissionpolicybindings deny-missing-app-label-pod
```

</details>
