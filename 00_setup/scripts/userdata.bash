#!/bin/bash

#-----------------------------
# settings
#-----------------------------

# https://kind.sigs.k8s.io/docs/user/known-issues/#pod-errors-due-to-too-many-open-files
cat << EOF | tee /etc/sysctl.conf >/dev/null
fs.inotify.max_user_watches = 1048576
fs.inotify.max_user_instances = 1024
EOF
sysctl -p

export HOME=/root
export KUBECONFIG=/root/.kube/config

mkdir -p /root/logs
mkdir -p /root/attack
mkdir -p /root/gitlab

PRIVATE_IP=$(hostname -I | awk '{print $1}')
cat << EOF | sudo tee -a /etc/hosts >/dev/null
${PRIVATE_IP} nginx.seccamp.com
${PRIVATE_IP} hubble.seccamp.com
${PRIVATE_IP} openclarity.seccamp.com
${PRIVATE_IP} harbor.seccamp.com
${PRIVATE_IP} gitlab.seccamp.com
${PRIVATE_IP} argocd.seccamp.com
${PRIVATE_IP} app.seccamp.com
${PRIVATE_IP} loki.seccamp.com
${PRIVATE_IP} grafana.seccamp.com
EOF

#-----------------------------
# components
#-----------------------------

apt update
apt upgrade -y

apt install -y jq

# docker
# https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository
apt install -y ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null
apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# kubectl
# https://medium.com/@saeidlaalkaei/installing-kubectl-on-amazon-linux-2-machine-fc82a3e6b7c8
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/

# kind
# https://kind.sigs.k8s.io/docs/user/quick-start/
# For AMD64 / x86_64
[ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.29.0/kind-linux-amd64
# For ARM64
[ $(uname -m) = aarch64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.29.0/kind-linux-arm64
chmod +x ./kind
mv ./kind /usr/local/bin/kind

# helm
# https://ap-northeast-1.console.aws.amazon.com/systems-manager/session-manager/i-066a4abd1ab950454?region=ap-northeast-1#:
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# helm-diff
helm plugin install https://github.com/databus23/helm-diff

# helmfile
HELMFILE_VERSION="1.1.3"
wget "https://github.com/helmfile/helmfile/releases/download/v${HELMFILE_VERSION}/helmfile_$(echo ${HELMFILE_VERSION})_linux_amd64.tar.gz"
tar -zxvf "helmfile_$(echo ${HELMFILE_VERSION})_linux_amd64.tar.gz"
mv helmfile /usr/local/bin/helmfile
rm "helmfile_$(echo ${HELMFILE_VERSION})_linux_amd64.tar.gz"

# trivy
# https://aquasecurity.github.io/trivy/v0.54/getting-started/installation/
apt install -y apt-transport-https gnupg
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor | tee /usr/share/keyrings/trivy.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb generic main" | tee -a /etc/apt/sources.list.d/trivy.list
apt update
apt install -y trivy

# krew
# https://krew.sigs.k8s.io/docs/user-guide/setup/install/
(
  set -x; cd "$(mktemp -d)" &&
  OS="$(uname | tr '[:upper:]' '[:lower:]')" &&
  ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" &&
  KREW="krew-${OS}_${ARCH}" &&
  curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" &&
  tar zxvf "${KREW}.tar.gz" &&
  ./"${KREW}" install krew
)

# cosign
# https://docs.sigstore.dev/cosign/system_config/installation/
curl -O -L "https://github.com/sigstore/cosign/releases/download/v2.5.3/cosign-linux-amd64"
mv cosign-linux-amd64 /usr/local/bin/cosign
chmod +x /usr/local/bin/cosign

export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

kubectl krew install neat
kubectl krew install view-secret
kubectl krew install who-can
kubectl krew install gadget
kubectl krew install view-serviceaccount-kubeconfig

#-----------------------------
# bashrc
#-----------------------------

# https://kubernetes.io/docs/reference/kubectl/generated/kubectl_completion/
echo 'source <(kubectl completion bash)' >> /root/.bashrc
echo 'alias k=kubectl' >> /root/.bashrc

echo 'complete -o default -F __start_kubectl k' >> /root/.bashrc

echo 'source <(kind completion bash)' >> /root/.bashrc

echo 'export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"' >> /root/.bashrc

#-----------------------------
# kind config
#-----------------------------

mkdir -p /root/kind

# kind-config.yaml
cat <<EOF > /root/kind/kind-config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  - |
    kind: ClusterConfiguration
    apiServer:
        # enable auditing flags on the API server
        extraArgs:
          audit-log-path: /var/log/kubernetes/kube-apiserver-audit.log
          audit-policy-file: /etc/kubernetes/policies/audit-policy.yaml
        # mount new files / directories on the control plane
        extraVolumes:
          - name: audit-policies
            hostPath: /etc/kubernetes/policies
            mountPath: /etc/kubernetes/policies
            readOnly: true
            pathType: "DirectoryOrCreate"
          - name: "audit-logs"
            hostPath: "/var/log/kubernetes"
            mountPath: "/var/log/kubernetes"
            readOnly: false
            pathType: DirectoryOrCreate
  extraMounts:
  - hostPath: /proc
    containerPath: /procHost
  - hostPath: /root/kind/audit-policy.yaml
    containerPath: /etc/kubernetes/policies/audit-policy.yaml
    readOnly: true
  extraPortMappings:
  # ingress port for nginx
  - containerPort: 30080
    hostPort: 80
    listenAddress: "0.0.0.0"
    protocol: TCP
  - containerPort: 30443
    hostPort: 443
    listenAddress: "0.0.0.0"
    protocol: TCP
- role: worker
  extraMounts:
  - hostPath: /proc
    containerPath: /procHost
- role: worker
  extraMounts:
  - hostPath: /proc
    containerPath: /procHost
networking:
  disableDefaultCNI: true
  kubeProxyMode: none
EOF

cat <<EOF > /root/kind/audit-policy.yaml
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
- level: Metadata
EOF

#-----------------------------
# helm releases
#-----------------------------

mkdir -p /root/helm/values

cat <<EOF > /root/helm/helmfile.yaml
repositories:
- name: cilium
  url: https://helm.cilium.io
- name: ingress-nginx
  url: https://kubernetes.github.io/ingress-nginx
- name: metrics-server
  url: https://kubernetes-sigs.github.io/metrics-server/
- name: gitlab
  url: https://charts.gitlab.io/
- name: argo
  url: https://argoproj.github.io/argo-helm
- name: harbor
  url: https://helm.goharbor.io
- name: jetstack
  url: https://charts.jetstack.io
- name: grafana
  url: https://grafana.github.io/helm-charts
- name: open-telemetry
  url: https://open-telemetry.github.io/opentelemetry-helm-charts

releases:
- name: cilium
  namespace: kube-system
  chart: cilium/cilium
  version: 1.17.6
  labels:
    app: cilium
  values:
  - values/cilium.values.yaml

- name: ingress-nginx
  namespace: ingress-nginx
  chart: ingress-nginx/ingress-nginx
  version: 4.10.1
  labels:
    app: ingress-nginx
  values:
  - values/ingress-nginx.values.yaml
  needs:
  - kube-system/cilium

- name: metrics-server
  namespace: kube-system
  chart: metrics-server/metrics-server
  version: 3.13.0
  labels:
    app: metrics-server
  values:
  - values/metrics-server.values.yaml
  needs:
  - kube-system/cilium

- name: tetragon
  namespace: kube-system
  chart: cilium/tetragon
  version: 1.4.1
  labels:
    app: tetragon
  values:
  - values/tetragon.values.yaml
  needs:
  - kube-system/cilium

- name: argocd
  namespace: argocd
  chart: argo/argo-cd
  version: 8.1.4
  labels:
    app: argocd
  values:
  - values/argocd.values.yaml
  needs:
  - kube-system/cilium

- name: gitlab
  namespace: gitlab
  chart: gitlab/gitlab
  version: 9.2.0
  labels:
    app: gitlab
  values:
  - values/gitlab.values.yaml
  needs:
  - kube-system/cilium

- name: harbor
  namespace: harbor
  chart: harbor/harbor
  version: 1.17.1
  labels:
    app: harbor
  values:
  - values/harbor.values.yaml
  needs:
  - kube-system/cilium

- name: cert-manager
  namespace: cert-manager
  chart: jetstack/cert-manager
  version: v1.18.2
  labels:
    app: cert-manager
  values:
  - values/cert-manager.values.yaml
  needs:
  - kube-system/cilium

- name: grafana
  namespace: monitoring
  chart: grafana/grafana
  version: 9.2.10
  labels:
    app: grafana
  values:
  - values/grafana.values.yaml
  needs:
  - kube-system/cilium

- name: loki
  namespace: monitoring
  chart: grafana/loki
  version: 6.32.0
  labels:
    app: loki
  values:
  - values/loki.values.yaml
  needs:
  - kube-system/cilium

- name: k8s-event-exporter
  namespace: monitoring
  chart: open-telemetry/opentelemetry-collector
  version: 0.128.0
  labels:
    app: k8s-event-exporter
  values:
  - values/k8s-event-exporter.values.yaml
  needs:
  - kube-system/cilium

# - name: openclarity
#   namespace: openclarity
#   chart: oci://ghcr.io/openclarity/charts/openclarity
#   version: 1.1.3
#   labels:
#     app: openclarity
#   values:
#   - values/openclarity.values.yaml
#   needs:
#   - kube-system/cilium

- name: promtail
  namespace: monitoring
  chart: grafana/promtail
  version: 6.17.0
  labels:
    app: promtail
  values:
  - values/promtail.values.yaml
  needs:
  - kube-system/cilium
EOF

cat <<EOF > /root/helm/values/cilium.values.yaml
# https://docs.cilium.io/en/stable/network/kubernetes/kubeproxy-free/#kubernetes-without-kube-proxy
kubeProxyReplacement: true
k8sServiceHost: kind-control-plane
k8sServicePort: 6443
rollOutCiliumPods: true
# https://docs.cilium.io/en/latest/observability/visibility/#layer-7-protocol-visibility
# endpointStatus:
#   enabled: true
#   status: policy
gatewayAPI:
  enabled: false
ingressController:
  enabled: false
operator:
  # ensure pods roll when configmap updates
  rollOutPods: true
  prometheus:
    enabled: true
prometheus:
  enabled: true
hubble:
  enabled: true
  relay:
    enabled: true
  ui:
    enabled: true
    # Visualization of l7 protocols
    podAnnotations:
      policy.cilium.io/proxy-visibility: "<Ingress/8082/TCP/HTTP>"
  metrics:
    enableOpenMetrics: true
    enabled:
    - dns
    - drop
    - tcp
    - flow
    - port-distribution
    - icmp
    - httpV2:exemplars=true;labelsContext=source_ip,source_namespace,source_workload,destination_ip,destination_namespace,destination_workload,traffic_direction
socketLB:
  hostNamespaceOnly: true
cni:
  exclusive: false
EOF

cat <<EOF > /root/helm/values/ingress-nginx.values.yaml
controller:
  config:
    use-forwarded-headers: "true"
  metrics:
    enabled: true
  nodeSelector:
    kubernetes.io/hostname: kind-control-plane
  tolerations:
  - effect: NoSchedule
    key: node-role.kubernetes.io/control-plane
    operator: Exists
  ingressClassResource:
    default: true
  admissionWebhooks:
    enabled: false
  service:
    type: NodePort
    ports:
      http: 80
      https: 443
    nodePorts:
      http: 30080
      https: 30443
    targetPorts:
      http: http
      https: https
EOF

cat <<EOF > /root/helm/values/metrics-server.values.yaml
args:
  - --kubelet-insecure-tls
EOF

cat <<EOF > /root/helm/values/tetragon.values.yaml
tetragon:
  hostProcPath: "/procHost"
EOF

cat <<EOF > /root/helm/values/argocd.values.yaml
global:
  domain: argocd.seccamp.com
server:
  service:
    type: ClusterIP
  ingress:
    annotations:
      nginx.ingress.kubernetes.io/connection-proxy-header: "keep-alive"
      nginx.ingress.kubernetes.io/ssl-redirect: "true"
      cert-manager.io/cluster-issuer: "root-ca-issuer"
    enabled: true
    hostname: argocd.seccamp.com
    ingressClassName: nginx
    path: /
    tls: true
    extraTls:
      - hosts:
          - argocd.seccamp.com
        secretName: argocd-tls
certificate:
  enabled: false
controller:
  replicas: 1
repoServer:
  replicas: 1
applicationSet:
  enabled: true
configs:
  cm:
    admin.enabled: true
  params:
    server.insecure: "true"
EOF

cat <<EOF > /root/helm/values/gitlab.values.yaml
nginx-ingress:
  enabled: false
prometheus:
  install: false
installCertmanager: false
global:
  kas:
    enabled: false
  hosts:
    domain: seccamp.com
    https: true
  ingress:
    annotations:
      nginx.ingress.kubernetes.io/connection-proxy-header: "keep-alive"
      nginx.ingress.kubernetes.io/ssl-redirect: "true"
      cert-manager.io/cluster-issuer: "root-ca-issuer"
    class: nginx
    configureCertmanager: false
    enabled: true
    path: /
    pathType: ImplementationSpecific
    tls:
      enabled: true
      secretName: gitlab-tls
  initialRootPassword:
    secret: gitlab-initial-root-password
    key: password
minio:
  ingress:
    tls:
      enabled: true
      secretName: gitlab-minio-tls
gitlab:
  webservice:
    enabled: true
  gitlab-shell:
    enabled: false
registry:
  enabled: false
gitlab-runner:
  install: true
  rbac:
    create: true
  certsSecretName: gitlab-tls
  runners:
    privileged: true
    locked: false
    secret: "nonempty"
    config: |
      [[runners]]
        tls-ca-file = "/home/gitlab-runner/.gitlab-runner/certs/ca.crt"
        environment = ["HARBOR_USER=test", "HARBOR_PASSWORD=TestUser1234"]
        [runners.kubernetes]
        image = "ubuntu:22.04"
        namespace = "gitlab"
        service_account = "gitlab-gitlab-runner"
        poll_timeout = 180
        cpu_request = "100m"
        memory_request = "128Mi"
        helper_cpu_request = "50m"
        helper_memory_request = "64Mi"
        [runners.kubernetes.node_selector]
          "kubernetes.io/os" = "linux"
        [[runners.kubernetes.volumes.secret]]
          name = "gitlab-tls"
          mount_path = "/home/gitlab-runner/.gitlab-runner/certs/"
          default_mode = 292
          [runners.kubernetes.volumes.secret.items]
            "ca.crt" = "ca.crt"
      [[runners.kubernetes.volumes.empty_dir]]
        name = "builds"
        mount_path = "/builds"
  podSecurityContext:
    seccompProfile:
      type: "RuntimeDefault"
EOF

cat <<EOF > /root/helm/values/harbor.values.yaml
expose:
  type: ingress
  tls:
    enabled: true
    certSource: secret
    secret:
      secretName: harbor-tls
  ingress:
    hosts:
      core: harbor.seccamp.com
    controller: default
    className: nginx
    annotations:
      nginx.ingress.kubernetes.io/ssl-redirect: "true"
      nginx.ingress.kubernetes.io/proxy-body-size: "0"
      cert-manager.io/cluster-issuer: "root-ca-issuer"
externalURL: https://harbor.seccamp.com
harborAdminPassword: "harboradminpassword"
database:
  type: internal
persistence:
  enabled: true
EOF

cat <<EOF > /root/helm/values/cert-manager.values.yaml
global:
  rbac:
    create: true

crds:
  enabled: true

resources:
  requests:
    cpu: 30m
    memory: 64Mi
  limits:
    memory: 64Mi

webhook:
  resources:
    requests:
      cpu: 20m
      memory: 80Mi
    limits:
      memory: 100Mi

cainjector:
  enabled: true
  resources:
    requests:
      cpu: 20m
      memory: 80Mi
    limits:
      memory: 100Mi

replicaCount: 1
EOF

cat <<EOF > /root/helm/values/grafana.values.yaml
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    memory: 128Mi

deploymentStrategy:
  type: Recreate

persistence:
  type: pvc
  enabled: true
  size: 3Gi

grafana.ini:
  server:
    root_url: https://grafana.seccamp.com/

ingress:
  enabled: true
  ingressClassName: nginx
  annotations:
    nginx.ingress.kubernetes.io/proxy-body-size: "0"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    cert-manager.io/cluster-issuer: "root-ca-issuer"
  path: /
  pathType: Prefix
  hosts:
  - grafana.seccamp.com
  tls:
  - secretName: grafana-tls
    hosts:
    - grafana.seccamp.com

initChownData:
  enabled: false

datasources:
  datasources.yaml:
    apiVersion: 1
    datasources:
      - name: Loki
        type: loki
        url: http://loki:3100
EOF

cat <<EOF > /root/helm/values/loki.values.yaml
deploymentMode: SingleBinary
loki:
  commonConfig:
    replication_factor: 1
  storage:
    type: 'filesystem'
  schemaConfig:
    configs:
    - from: "2024-01-01"
      store: tsdb
      index:
        prefix: loki_index_
        period: 24h
      object_store: filesystem
      schema: v13
  auth_enabled: false

singleBinary:
  replicas: 1
read:
  replicas: 0
backend:
  replicas: 0
write:
  replicas: 0

resultsCache:
  enabled: false
chunksCache:
  enabled: false

ingress:
  enabled: true
  ingressClassName: nginx
  annotations:
    nginx.ingress.kubernetes.io/proxy-body-size: "0"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    cert-manager.io/cluster-issuer: "root-ca-issuer"
  hosts:
    - loki.seccamp.com
  tls:
    - hosts:
      - loki.seccamp.com
      secretName: loki-tls
EOF

cat <<EOF > /root/helm/values/k8s-event-exporter.values.yaml
image:
  repository: otel/opentelemetry-collector-k8s

fullnameOverride: "kubernetes-events-exporter"

mode: deployment
replicaCount: 1

presets:
  kubernetesEvents:
    enabled: true

ports:
  jaeger-compact:
    enabled: false
  jaeger-thrift:
    enabled: false
  jaeger-grpc:
    enabled: false
  zipkin:
    enabled: false
  metrics:
    enabled: false

resources:
  requests:
    cpu: 50m
    memory: 60Mi
  limits:
    memory: 128Mi

config:
  exporters:
    otlphttp:
      headers:
        X-Scope-OrgID: \${SCOPE_ORG_ID}
      endpoint: http://loki:3100/otlp
  processors:
    transform/events:
      error_mode: ignore
      log_statements:
      - context: log
        statements:
        - set(attributes["watch-type"], body["type"]) where IsMap(body) and body["type"] != nil
        - merge_maps(attributes, body, "upsert") where IsMap(body) and body["object"] == nil
        - merge_maps(attributes, body["object"], "upsert") where IsMap(body) and body["object"] != nil
        - merge_maps(attributes, attributes["metadata"], "upsert") where IsMap(attributes["metadata"])
        # Maps the name of the resource to the right k8s.* attribute
        - set(attributes["k8s.pod.name"], attributes["regarding"]["name"]) where attributes["regarding"]["kind"] == "Pod"
        - set(attributes["k8s.deployment.name"], attributes["regarding"]["name"]) where attributes["regarding"]["kind"] == "Deployment"
        - set(attributes["k8s.statefulset.name"], attributes["regarding"]["name"]) where attributes["regarding"]["kind"] == "StatefulSet"
        - set(attributes["k8s.daemonset.name"], attributes["regarding"]["name"]) where attributes["regarding"]["kind"] == "DaemonSet"
        - set(attributes["k8s.job.name"], attributes["regarding"]["name"]) where attributes["regarding"]["kind"] == "Job"
        - set(attributes["k8s.cronjob.name"], attributes["regarding"]["name"]) where attributes["regarding"]["kind"] == "CronJob"
        - set(attributes["k8s.node.name"], attributes["regarding"]["name"]) where attributes["regarding"]["kind"] == "Node"
        - set(attributes["k8s.namespace.name"], attributes["regarding"]["namespace"]) where attributes["regarding"]["kind"] != "Node"
        # Converts event types to Otel log Severities
        - set(severity_text, attributes["type"]) where attributes["type"] == "Normal" or attributes["type"] == "Warning"
        - set(severity_number, SEVERITY_NUMBER_INFO) where attributes["type"] == "Normal"
        - set(severity_number, SEVERITY_NUMBER_WARN) where attributes["type"] == "Warning"
        # 不要なアトリビュートを削除
        - delete_key(attributes, "managedFields") where attributes["managedFields"] != nil
        - delete_key(attributes, "metadata") where attributes["metadata"] != nil
        # Events の非推奨なフィールドを削除
        - delete_key(attributes, "deprecatedCount") where attributes["deprecatedCount"] != nil
        - delete_key(attributes, "deprecatedFirstTimestamp") where attributes["deprecatedFirstTimestamp"] != nil
        - delete_key(attributes, "deprecatedLastTimestamp") where attributes["deprecatedLastTimestamp"] != nil
        - delete_key(attributes, "deprecatedSource") where attributes["deprecatedSource"] != nil
    resource:
      attributes:
      - action: upsert
        key: service.name
        value: kubernetes-events
  service:
    pipelines:
      logs:
        processors:
        - memory_limiter
        - resource
        - transform/events
        - batch
        exporters:
        - otlphttp
      metrics: null
      traces: null
EOF

cat <<EOF > /root/helm/values/openclarity.values.yaml
orchestrator:
  provider: kubernetes
  serviceAccount:
    automountServiceAccountToken: true

gateway:
  ingress:
    enabled: true
    annotations:
      nginx.ingress.kubernetes.io/proxy-buffer-size: "8k"
      nginx.ingress.kubernetes.io/ssl-redirect: "true"
      cert-manager.io/cluster-issuer: "root-ca-issuer"
    ingressClassName: nginx
    hosts:
    - host: openclarity.seccamp.com
      paths:
      - pathType: Prefix
        path: /
    tls:
    - secretName: openclarity-tls
      hosts:
      - openclarity.seccamp.com

postgresql:
  auth:
    username: openclarity
    password: ocpostgresqlpassword
EOF

cat <<EOF > /root/helm/values/promtail.values.yaml
nodeSelector:
  kubernetes.io/hostname: kind-control-plane

config:
  clients:
    - url: http://loki-gateway/loki/api/v1/push

  snippets:
    scrapeConfigs: |
      - job_name: audit-logs
        static_configs:
          - targets:
              - localhost
            labels:
              job: audit-logs
              __path__: /var/log/kubernetes/**/*.log

extraVolumes:
  - name: kubernetes
    hostPath:
      path: /var/log/kubernetes

extraVolumeMounts:
  - name: kubernetes
    mountPath: /var/log/kubernetes
    readOnly: true
EOF

#-----------------------------
# manifests
#-----------------------------

mkdir -p /root/app
cat <<EOF > /root/app/hubble-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: hubble-ingress
  namespace: kube-system
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    cert-manager.io/cluster-issuer: "root-ca-issuer"
spec:
  tls:
  - hosts:
    - hubble.seccamp.com
    secretName: hubble-tls
  rules:
  - host: hubble.seccamp.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: hubble-ui
            port:
              number: 80
EOF

cat <<EOF > /root/app/selfsigned-clsuterissuer.yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: root-ca-issuer-selfsigned
spec:
  selfSigned: {}
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: root-ca
  namespace: cert-manager
spec:
  isCA: true
  commonName: seccamp.com
  secretName: root-ca-secret
  privateKey:
    algorithm: ECDSA
    size: 256
  issuerRef:
    name: root-ca-issuer-selfsigned
    kind: ClusterIssuer
    group: cert-manager.io
---
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: root-ca-issuer
spec:
  ca:
    secretName: root-ca-secret
EOF

cat <<EOF > /root/app/coredns-configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns
  namespace: kube-system
data:
  Corefile: |
    .:53 {
        errors
        health {
           lameduck 5s
        }
        ready
        rewrite name gitlab.seccamp.com ingress-nginx-controller.ingress-nginx.svc.cluster.local
        rewrite name harbor.seccamp.com ingress-nginx-controller.ingress-nginx.svc.cluster.local
        kubernetes cluster.local in-addr.arpa ip6.arpa {
           pods insecure
           fallthrough in-addr.arpa ip6.arpa
           ttl 30
        }
        prometheus :9153
        forward . /etc/resolv.conf {
           max_concurrent 1000
        }
        cache 30
        loop
        reload
        loadbalance
    }
EOF

#-----------------------------
# exec
#-----------------------------

kind create cluster --config /root/kind/kind-config.yaml > /root/logs/kind-create.log 2>&1
mkdir -p /root/.kube
kind get kubeconfig > /root/.kube/config
chmod 600 /root/.kube/config

kubectl create namespace gitlab > /root/logs/gitlab-namespace.log 2>&1
kubectl create secret -n gitlab generic gitlab-initial-root-password --from-literal=password=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 32) > /root/logs/gitlab-secret.log 2>&1

kubectl create namespace seccamp-app
kubectl create secret docker-registry harbor-cred \
  --namespace seccamp-app \
  --docker-server=harbor.seccamp.com \
  --docker-username=test \
  --docker-password=TestUser1234 \
  --docker-email=test@test.com

helmfile sync -f /root/helm/helmfile.yaml --selector app=cilium > /root/logs/helmfile-sync-cilium.log 2>&1
helmfile sync -f /root/helm/helmfile.yaml --selector app=cert-manager > /root/logs/helmfile-sync-cert-manager.log 2>&1

kubectl apply -f /root/app/selfsigned-clsuterissuer.yaml > /root/logs/selfsigned-clusterissuer.log 2>&1

helmfile sync -f /root/helm/helmfile.yaml > /root/logs/helmfile-sync.log 2>&1

kubectl apply -f /root/app/hubble-ingress.yaml > /root/logs/hubble-ingress.log 2>&1

kubectl gadget deploy > /root/logs/gadget-deploy.log 2>&1

git config --global credential.helper cache

mkdir /usr/local/share/ca-certificates/extra
kubectl view-secret -n cert-manager root-ca-secret ca.crt > /usr/local/share/ca-certificates/extra/seccamp-ca.crt
update-ca-certificates

mkdir -p /etc/docker/certs.d/harbor.seccamp.com
cp /usr/local/share/ca-certificates/extra/seccamp-ca.crt /etc/docker/certs.d/harbor.seccamp.com/

curl -L -O https://gist.githubusercontent.com/kyohmizu/7360421adffcf36a6231af5648db49f3/raw/05cc28711738d152e4aeef394909c291dc57a3a5/kind-load-certfile.sh
chmod +x ./kind-load-certfile.sh
./kind-load-certfile.sh /usr/local/share/ca-certificates/extra/seccamp-ca.crt > /root/logs/kind-load-certfile.log 2>&1

touch /root/logs/finished
