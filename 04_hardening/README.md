# 4章 セキュリティ対策の導入

- [4章 セキュリティ対策の導入](#4章-セキュリティ対策の導入)
  - [利用可能なセキュリティツール・機能](#利用可能なセキュリティツール機能)
    - [Trivy](#trivy)
    - [Security Context](#security-context)
    - [監視ログ](#監視ログ)
    - [Validating Admission Policy](#validating-admission-policy)
    - [Network Policy](#network-policy)
    - [Inspektor Gadget](#inspektor-gadget)
    - [Tetragon](#tetragon)
    - [OpenClarity](#openclarity)
  - [次のステップ](#次のステップ)

2章および3章では、クラウドネイティブ環境におけるセキュリティの基本概念、脅威モデリングの手法、そして多層防御の重要性について学習しました。理論的な知識の習得は不可欠ですが、その知識を実際の問題解決に応用する能力が現場では求められます。

本章では、具体的なセキュリティ対策をどのように導入し、実践していくかについて演習を通して学習します。演習環境で利用可能なツールや機能、その他の有用なツールについて以下でご紹介します。

## 利用可能なセキュリティツール・機能

演習環境で利用可能なセキュリティツール、Kubernetesの機能の一例です。

### Trivy

https://trivy.dev/

Trivyは、コンテナイメージ、ファイルシステム、Gitリポジトリ、Kubernetes環境など、多岐にわたるターゲットに対して、脆弱性、設定ミス、機密情報、SBOM（Software Bill of Materials）などを検出する包括的かつ多機能なセキュリティスキャナーです。特にKubernetesにおいては、Trivy Operatorを活用することで、クラスタ内の状態変化（例：Podの新規作成）に反応して継続的にセキュリティスキャンを実行し、その結果をKubernetesのカスタムリソースとしてセキュリティレポートにまとめることも可能です。

### Security Context

https://kubernetes.io/docs/tasks/configure-pod-container/security-context/

Security Contextは、Podやコンテナのセキュリティ設定を定義するKubernetesの重要な機能です。Linuxのセキュリティメカニズム（ユーザーID、グループID、権限、SELinux、AppArmor、seccompなど）をKubernetes環境で制御できます。rootユーザーでの実行を禁止する（runAsNonRoot: true）、読み取り専用のルートファイルシステムを強制する（readOnlyRootFilesystem: true）、特権アクセスを無効化する（allowPrivilegeEscalation: false）、不要なLinux capabilitiesを削除する（drop: ["ALL"]）といった設定により、コンテナが侵害された場合の被害を最小限に抑えることができます。Pod Security Standardsと組み合わせることで、クラスタ全体に一貫したセキュリティポリシーを適用できます。

### 監視ログ

https://kubernetes.io/docs/tasks/debug/debug-cluster/audit/

Kubernetes の監査ログは、クラスタ内での全ての API リクエストを記録し、セキュリティやコンプライアンスの要件を満たすための重要な機能です。これにより、誰がいつ何を行ったのかを追跡でき、不正アクセスや異常な活動を検知するのに役立ちます。監査ポリシーをカスタマイズすることで、必要な情報だけをログに記録し、ログの管理や解析を効率化できます。

### Validating Admission Policy

https://kubernetes.io/docs/reference/access-authn-authz/validating-admission-policy/

Validating Admission Policyは、Kubernetes 1.26で導入された新しいタイプのポリシー機能であり、Kubernetes APIへのリクエストがetcdに永続化される前に、その内容を検証するための宣言的な代替手段を提供します。Common Expression Language (CEL) を用いて検証ルールを定義し、ポリシー作成者はパラメータ化やリソースへのスコープ設定を柔軟に行うことができます。これにより、不正な設定やポリシー違反のあるリソースがクラスタにデプロイされるのを防止し、セキュリティ体制の一貫性を保つ上で重要な役割を果たします。

### Network Policy

https://kubernetes.io/docs/concepts/services-networking/network-policies/

Kubernetes Network Policyは、Kubernetesクラスタ内のPod間の通信を制御するためのファイアウォールルールを定義する仕様です。デフォルトでは、クラスタ内のすべてのPodは自由に通信できますが、Network Policyを適用することで、Pod間のネットワークトラフィックを制限し、ネットワークセグメンテーションや分離を実現できます。これにより、最小権限の原則やゼロトラストの考え方をネットワーク層で適用し、攻撃対象領域を削減し、横方向の移動を制限することが可能になります。

### Inspektor Gadget

https://inspektor-gadget.io/

Inspektor Gadgetは、eBPF（extended Berkeley Packet Filter）を活用し、KubernetesクラスタやLinuxホスト上でのデータ収集とシステム検査を行うためのツール群およびフレームワークです。eBPFプログラムを「Gadget」と呼ばれるOCIイメージにカプセル化してデプロイ・実行を管理し、カーネルレベルの低レベルなシステム情報（マウント名前空間、PIDなど）をKubernetesのPodやコンテナといった高レベルなリソースに自動的にマッピング（エンリッチメント）することで、強力な可観測性を提供します。これにより、システム内部の挙動を詳細に可視化し、セキュリティ分析やトラブルシューティングに役立てることができます。

### Tetragon

https://tetragon.io/

Tetragonは、eBPFベースのKubernetes対応セキュリティ可観測性およびランタイム強制ツールです。プロセス実行、システムコール、ファイルアクセス、ネットワーク活動などのシステム動作をカーネルレベルでリアルタイムに監視し、ポリシーに基づいて悪意のある活動をブロックする機能を提供します。CiliumのKubernetesネイティブな設計に基づいており、名前空間やPodメタデータといったワークロードの識別情報を認識することで、従来の可観測性ツールを超えた深い洞察を提供します。最小限のオーバーヘッドで、リアルタイムのポリシー適用と脅威検出を可能にします。

![](https://github.com/cilium/tetragon/raw/main/docs/static/images/smart_observability.png)

### OpenClarity

https://openclarity.io/

OpenClarityは、クラウドネイティブアプリケーションおよびインフラストラクチャのセキュリティと可観測性を強化するために構築されたツールです。VMやコンテナイメージの脆弱性、エクスプロイト、マルウェア、設定ミスなどをエージェントレスで検出・管理する機能を提供します。また、KubernetesのランタイムスキャンやCI/CDパイプラインのスキャン機能、さらには内部およびサードパーティAPIに対する包括的なAPIセキュリティ機能も備えており、クラウドネイティブ環境全体にわたる脅威検出と緩和を支援します。

![](https://openclarity.io/img/carousel/VMsec.png)

※ 機能不足やバグが目立ち、まだあまり実用的とは言えません

---

## 次のステップ

- [演習4 セキュリティ対策の導入](./training.md)
