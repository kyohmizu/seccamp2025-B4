USE seccamp2025;

-- MariaDB初期化用SQL
-- ユーザー情報テーブル
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(64) UNIQUE NOT NULL,
    full_name VARCHAR(128),
    password VARCHAR(256) NOT NULL,
    is_admin BOOLEAN DEFAULT FALSE
);

-- 学習コンテンツ情報テーブル
CREATE TABLE IF NOT EXISTS courses (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(128) NOT NULL,
    description TEXT
);

-- 学習進捗テーブル（複合ユニーク制約追加）
CREATE TABLE IF NOT EXISTS progress (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    course_id INT NOT NULL,
    percent INT DEFAULT 0,
    updated_at DATETIME,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (course_id) REFERENCES courses(id),
    UNIQUE KEY user_course_unique (user_id, course_id)
);

-- サンプルデータ投入用SQL
-- ユーザーサンプルデータ（日本人名・自然な名前）
INSERT INTO users (username, full_name, password, is_admin) VALUES
  ('sato', '佐藤 太郎', 'pass1', FALSE),
  ('suzuki', '鈴木 花子', 'pass2', FALSE),
  ('takahashi', '高橋 健一', 'pass3', FALSE),
  ('tanaka', '田中 由美', 'pass4', FALSE),
  ('watanabe', '渡辺 翔太', 'pass5', FALSE),
  ('ito', '伊藤 美咲', 'pass6', FALSE),
  ('yamamoto', '山本 悠斗', 'pass7', FALSE),
  ('nakamura', '中村 彩香', 'pass8', FALSE),
  ('kobayashi', '小林 直人', 'pass9', FALSE),
  ('kato', '加藤 恵美', 'pass10', FALSE),
  ('yoshida', '吉田 拓海', 'pass11', FALSE),
  ('yamada', '山田 沙織', 'pass12', FALSE),
  ('sasaki', '佐々木 亮介', 'pass13', FALSE),
  ('yamaguchi', '山口 真由美', 'pass14', FALSE),
  ('matsumoto', '松本 智也', 'pass15', FALSE),
  ('inoue', '井上 千尋', 'pass16', FALSE),
  ('kimura', '木村 大輔', 'pass17', FALSE),
  ('hayashi', '林 美和', 'pass18', FALSE),
  ('shimizu', '清水 和也', 'pass19', FALSE),
  ('saito', '斎藤 香織', 'pass20', FALSE),
  ('admin', '管理者', 'adminpass', TRUE);

-- コースサンプルデータ
INSERT INTO courses (title, description) VALUES
  ('Python入門', 'Pythonの基礎を学ぶコース'),
  ('Kubernetes基礎', 'Kubernetesの基本を学ぶコース'),
  ('Go言語入門', 'Go言語の基礎を学ぶコース'),
  ('React入門', 'Reactの基礎を学ぶコース'),
  ('セキュリティ基礎', 'セキュリティの基本を学ぶコース'),
  ('Linux入門', 'Linuxの基礎を学ぶコース'),
  ('クラウド基礎', 'クラウド技術の基礎を学ぶコース'),
  ('ネットワーク基礎', 'ネットワークの基本を学ぶコース'),
  ('Docker入門', 'Dockerの基礎を学ぶコース'),
  ('CI/CD入門', 'CI/CDの基礎を学ぶコース');

-- 学習進捗サンプルデータ
INSERT INTO progress (user_id, course_id, percent, updated_at) VALUES
  (1, 1, 50, NOW()),
  (1, 2, 0, NOW()),
  (1, 3, 100, NOW()),
  (2, 1, 80, NOW()),
  (2, 2, 20, NOW()),
  (2, 3, 0, NOW()),
  (3, 1, 0, NOW()),
  (3, 2, 0, NOW()),
  (3, 3, 0, NOW()),
  (4, 1, 100, NOW()),
  (4, 2, 100, NOW()),
  (4, 3, 100, NOW()),
  (5, 1, 10, NOW()),
  (5, 2, 30, NOW()),
  (5, 3, 60, NOW());
