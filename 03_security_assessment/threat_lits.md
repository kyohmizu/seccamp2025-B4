# 参考: クラウドネイティブ環境の脅威と対策

| レイヤー | 脅威 | 攻撃テクニック | セキュリティ対策 |
| :--- | :--- | :--- | :--- |
| **Reconnaissance (偵察)** | Active Scanning | ポートスキャナーを使い、公開されているポートからアプリケーションやKubernetesコンポーネント、コンテナAPIなどを探索する。 | アプリケーション、Kubernetesクラスタ、VMへのネットワークアクセスを制限する。WAF（Web Application Firewall）で悪意のあるトラフィックを検知・遮断する。 |
| | Search Open Websites/Domains | 公開されたコードリポジトリから、誤って保存された認証情報などを探索する。 | Vaultなどのツールを利用して機密情報を保護し、コードリポジトリへの漏洩を防止する。 |
| **Initial Access (初期アクセス)** | Exploit Public-Facing Application | アプリケーションやクラスタコンポーネント、外部サービスの脆弱性を悪用して侵入する。 | SAST/DAST、SCA、コンテナイメージスキャンによる脆弱性検出。クラスタコンポーネントの迅速なアップデート。コンテナレジストリやコードリポジトリのアクセス制限を適切に行う。 |
| | External Remote Services | 誤設定により公開されたコンテナAPIやKubernetesクラスタコンポーネント、VMの公開ポートを通じて不正アクセスする。 | ネットワークポリシーによるアクセス制限。コンテナ専用OSの利用。定期的なクラスタ状態の診断。 |
| | Supply Chain Compromise | 依存ライブラリやコンテナイメージ、マニフェストファイルに悪意のあるコードを埋め込み、サプライチェーンを侵害して侵入する。 | SBOMを活用した依存関係の管理と脆弱性検出。コンテナイメージの署名と検証。Admission Controlによるデプロイの制限。 |
| | Valid Accounts | 漏洩したアプリケーションやKubernetesクラスタの正規認証情報を悪用して侵入する。 | ネットワークアクセス制限。監査ログによる異常なアクセスの検知。 |
| **Execution (実行)** | Container Administration Command | DockerやKubernetesの管理コマンドを悪用し、コンテナ内で悪意のあるコードを実行する。 | ユーザーに付与する権限を最小限に制限する。 |
| | Deploy Container / Schedule Task/Job | 攻撃ツールを含むコンテナや、悪意のあるコードを実行するCronJobをデプロイする。 | Admission Controlによるポリシー違反のコンテナ作成禁止。コンテナイメージの署名と検証。 |
| | User Execution | 悪意のあるコードが埋め込まれたコンテナイメージを利用者に実行させる。 | コンテナイメージの署名と検証を行う。 |
| **Persistence (永続化)** | Account Manipulation / Create Account | 盗んだ認証情報でアカウントを不正操作し、アクセスを維持する。または、新規ユーザーを作成する。 | 権限の最小化。Kubernetesの監査ログによる異常なアクティビティの検知。 |
| | Create or Modify System Process / Schedule Task/Job | DaemonsetやCronJobを利用して、悪意のあるコンテナをデプロイし、実行を永続化する。 | Admission Controlによるポリシー違反のコンテナ作成禁止。コンテナイメージの署名と検証。監査ログによる異常なアクティビティの検知。 |
| | External Remote Services | 侵害したコンテナから外部の悪意のあるサーバーに接続し、コマンド受信やデータ窃取を行う。 | CNIプラグインのネットワークポリシーで外部への通信を制限する。 |
| | Implant Internal Image | コンテナイメージに悪意のあるコードを埋め込み、アクセスの永続性を確保する。 | コンテナイメージの署名と検証を行う。 |
| | Valid Accounts | 盗んだ正規の認証情報を悪用し、バックドアアカウント作成や悪意のあるコンテナをデプロイすることで永続性を確保する。 | ネットワークアクセス制限と監査ログによる異常なアクセスの検知。 |
| **Privilege Escalation (権限昇格)** | Account Manipulation / Exploitation for Privilege Escalation | 盗んだ認証情報でロールを変更したり、過剰な権限を持つサービスアカウントを悪用して権限を昇格させる。 | 権限の最小化。Kubernetesの監査ログによる異常なアクティビティの検知。定期的なクラスタ状態のスキャン。 |
| | Create or Modify System Process | コンテナ内の脆弱性を悪用してrootユーザーに昇格する。 | クラスタ内のコンテナの脆弱性管理。ランタイムセキュリティツールによるシステムコールの監視。 |
| | Escape to Host | hostPathや特権コンテナ、コンテナランタイムの脆弱性を悪用して、コンテナからホストへ脱出する。 | Admission Controlによるポリシー違反のコンテナ作成禁止。gvisorなどの分離レベルが高いランタイムの導入。seccomp/Apparmorによる強制アクセス制御。コンテナ専用OSの利用。 |
| | Valid Accounts | 侵入したコンテナのサービスアカウント権限を悪用し、クラスタロールを作成または取得して権限を昇格させる。 | 権限の最小化。ネットワークアクセス制限。監査ログによる異常なアクティビティの検知。 |
| **Defense Evasion (防御回避)** | Build Image on Host | ホスト上で悪意のあるコンテナイメージをビルドし、イメージ署名検証を回避する。 | ホストの監査ログやネットワークトラフィックの監視で異常なアクティビティを検知する。 |
| | Deploy Container / Impair Defenses / Indicator Removal | 脆弱なコンテナの作成、監視システムの無効化、ログの削除により防御策を回避する。 | 権限の最小化。Admission Controlによるポリシー違反のコンテナ作成禁止。コンテナイメージの署名と検証。外部ログ管理システムによるログ保護。監査ログによる異常なアクティビティの検知。 |
| | Obfuscated Files or Information / Masquerading | 悪意のあるコードを難読化したり、正規のアカウントやプロセスに偽装したりして検知を回避する。 | ランタイムセキュリティツールによるシステムコールの監視で、異常なアクティビティを検知する。 |
| | Use Alternate Authentication Material / Valid Accounts / Subvert Trust Controls | 代替認証情報や正規の認証情報を悪用したり、改ざんによって認証を回避したりして、セキュリティツールによる検知を免れる。 | Kubernetesクラスタへのネットワークアクセス制限。監査ログによる不審なアクティビティの検知。ランタイムセキュリティツールによるシステムコールの監視。 |
| **Credential Access (認証情報へのアクセス)** | Brute Force | 総当たり攻撃で認証を突破する。 | WAFによる悪意のあるトラフィックの検知。監査ログやアクセスログによる多数のログイン試行の検知。 |
| | Steal Application Access Token | 外部サービスの認証情報やコンテナに付与されたサービスアカウントトークンを窃取する。 | 権限の最小化。Kubernetesやクラウドの監査ログによる異常なアクティビティの検知。 |
| | Unsecured Credentials | Kubernetesやコンテナ内のローカルファイルに保存された機密情報を窃取する。 | 権限の最小化。Vaultなどのツールで機密情報を保護する。Distrolessコンテナの利用や、seccomp/Apparmorによる強制アクセス制御。 |
| **Discovery (探索)** | Container and Resource Discovery | Kubernetes APIを悪用し、他のリソース（PodやSecretなど）の情報を収集する。 | Kubernetesの監査ログで異常なアクティビティを検知する。 |
| | Network Service Discovery | 侵入したコンテナからクラスタ内のネットワークスキャンを行う。 | CNIプラグインのネットワークポリシーでアクセスを制限する。 |
| | Permission Groups Discovery | kubectl auth can-iなどの管理コマンドを使い、特権を持つアカウントを調査する。 | 監査ログで異常なアクティビティを検知する。 |
| **Lateral Movement (水平展開)** | Use Alternate Authentication Material | 盗んだ代替認証情報を悪用し、他のアカウントやサービスに侵入する。 | ユーザーやPodに付与する外部サービスの権限を最小限に制限する。クラウドの監査ログで異常なアクティビティを検知する。 |
| | Lateral Tool Transfer | 侵入したコンテナから、別のコンテナやノードに攻撃ツールを転送する。 | CNIプラグインのネットワークポリシーでアクセスを制限する。ランタイムセキュリティツールで異常なアクティビティを検知する。 |
| **Collection (情報収集)** | Data from Cloud Storage | 認証情報を窃取し、クラウドストレージから機密情報を収集する。 | クラウドの監査ログで異常なアクティビティを検知する。データの暗号化。ネットワークアクセス制限。 |
| | Data from Information Repositories | 盗んだ資格情報を悪用し、コードリポジトリやコンテナレジストリから機密情報を収集する。 | 権限の最小化。機密情報の保護。ネットワークアクセス制限。監査ログによる異常なアクティビティの検知。 |
| | Data from Configuration Repository | サービスアカウントを悪用し、KubernetesクラスタからSecretなどの機密情報を収集する。または、コンテナからホストへ侵入し、kubeletの資格情報などを悪用して情報を取得する。 | 権限の最小化。Vaultなどのツールで機密情報を保護。Kubernetesの監査ログによる異常なアクティビティの検知。etcdの適切なセキュリティ設定。分離レベルの高いランタイムの導入。強制アクセス制御。コンテナ専用OSの利用。 |
| **Command and Control (C2)** | Proxy | 侵害したコンテナをプロキシ化し、外部との通信を中継する。 | ネットワーク監視ツールでEgress通信を監視する。強制アクセス制御やランタイムセキュリティツールによるシステムコールの監視。 |
| **Exfiltration (データ持ち出し)** | Exfiltration Over Alternative Protocol | DNSクエリなど、別のプロトコルを利用してデータを外部に流出させる。 | ランタイムセキュリティツールによるシステムコールの監視。強制アクセス制御。ネットワーク監視ツールによる異常なアクティビティの検知。 |
| | Transfer Data to Cloud Account | ログやバックアップの転送先を、攻撃者が保有するアカウントに変更する。 | クラウドの監査ログで異常なアクティビティを検知する。 |
| **Impact (影響)** | Data Destruction | DBやストレージのデータを削除する。 | 外部ストレージサービスでバックアップデータを管理する。 |
| | Endpoint Denial of Service | DoS攻撃でリソースを枯渇させたり、リソースを削除したりしてサービスを妨害する。 | WAFで悪意のあるトラフィックを検知・遮断。Resource Quotaでリソース利用を制限。SAST/DASTで脆弱性を検出。権限の最小化。監査ログによる異常なアクティビティの検知。データのバックアップ。 |
| | Network Denial of Service | DDoS攻撃でネットワーク帯域を飽和させ、通信を遮断する。 | Ingress controllerのrate limit機能などで、悪意のあるトラフィックを検知・遮断する。 |
| | Inhibit System Recovery | バックアップデータや永続データを削除し、システム復旧を妨害する。 | 外部サービスを利用してバックアップデータを管理する。 |
