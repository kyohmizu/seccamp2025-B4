
```bash
# 必要な通信の疎通チェック（バックエンド → DB）
POD_NAME=$(kubectl get pods -n seccamp-app -l app=backend -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it -n seccamp-app "$POD_NAME" -- /bin/sh
nc -vz -w 1 db 3306

# 不要な通信の疎通チェック（フロントエンド → DB）
POD_NAME=$(kubectl get pods -n seccamp-app -l app=frontend -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it -n seccamp-app "$POD_NAME" -- /bin/sh
nc -vz -w 1 db 3306

# 不要なAPIエンドポイントへの疎通チェック
curl https://app.seccamp.com/api/admin/info
```