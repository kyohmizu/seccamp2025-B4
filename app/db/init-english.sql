USE seccamp2025;

-- MariaDB initialization SQL
-- User information table
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(64) UNIQUE NOT NULL,
    full_name VARCHAR(128),
    password VARCHAR(256) NOT NULL,
    is_admin BOOLEAN DEFAULT FALSE
);

-- Learning content information table
CREATE TABLE IF NOT EXISTS courses (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(128) NOT NULL,
    description TEXT
);

-- Learning progress table (with composite unique constraint)
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

-- Sample data insertion SQL
-- User sample data
INSERT INTO users (username, full_name, password, is_admin) VALUES
  ('sato', 'Taro Sato', 'pass1', FALSE),
  ('suzuki', 'Hanako Suzuki', 'pass2', FALSE),
  ('takahashi', 'Kenichi Takahashi', 'pass3', FALSE),
  ('tanaka', 'Yumi Tanaka', 'pass4', FALSE),
  ('watanabe', 'Shota Watanabe', 'pass5', FALSE),
  ('ito', 'Misaki Ito', 'pass6', FALSE),
  ('yamamoto', 'Yuto Yamamoto', 'pass7', FALSE),
  ('nakamura', 'Ayaka Nakamura', 'pass8', FALSE),
  ('kobayashi', 'Naoto Kobayashi', 'pass9', FALSE),
  ('kato', 'Emi Kato', 'pass10', FALSE),
  ('yoshida', 'Takumi Yoshida', 'pass11', FALSE),
  ('yamada', 'Saori Yamada', 'pass12', FALSE),
  ('sasaki', 'Ryosuke Sasaki', 'pass13', FALSE),
  ('yamaguchi', 'Mayumi Yamaguchi', 'pass14', FALSE),
  ('matsumoto', 'Tomoya Matsumoto', 'pass15', FALSE),
  ('inoue', 'Chihiro Inoue', 'pass16', FALSE),
  ('kimura', 'Daisuke Kimura', 'pass17', FALSE),
  ('hayashi', 'Miwa Hayashi', 'pass18', FALSE),
  ('shimizu', 'Kazuya Shimizu', 'pass19', FALSE),
  ('saito', 'Kaori Saito', 'pass20', FALSE),
  ('admin', 'Administrator', 'adminpass', TRUE);

-- Course sample data
INSERT INTO courses (title, description) VALUES
  -- Basic/Introduction Courses (1-10)
  ('Python Introduction', 'Learn the basics of Python programming'),
  ('Kubernetes Fundamentals', 'Learn the fundamentals of Kubernetes'),
  ('Go Language Introduction', 'Learn the basics of Go programming language'),
  ('React Introduction', 'Learn the basics of React development'),
  ('Security Fundamentals', 'Learn the fundamentals of cybersecurity'),
  ('Linux Introduction', 'Learn the basics of Linux operating system'),
  ('Cloud Fundamentals', 'Learn the fundamentals of cloud technologies'),
  ('Network Fundamentals', 'Learn the basics of computer networking'),
  ('Docker Introduction', 'Learn the basics of Docker containerization'),
  ('CI/CD Introduction', 'Learn the basics of Continuous Integration and Deployment'),
  
  -- Intermediate Courses (11-20)
  ('Python Web Development', 'Build web applications using Django and Flask'),
  ('Kubernetes Operations', 'Advanced Kubernetes cluster management and operations'),
  ('Go Microservices', 'Build scalable microservices with Go'),
  ('React State Management', 'Advanced React patterns with Redux and Context API'),
  ('Penetration Testing', 'Learn ethical hacking and vulnerability assessment'),
  ('Linux System Administration', 'Advanced Linux server management and automation'),
  ('AWS Cloud Architecture', 'Design and implement AWS cloud solutions'),
  ('Network Security', 'Implement network security measures and protocols'),
  ('Docker Orchestration', 'Container orchestration with Docker Swarm'),
  ('DevOps Pipeline Design', 'Design and implement comprehensive DevOps pipelines'),
  
  -- Advanced Courses (21-30)
  ('Python Machine Learning', 'Advanced ML algorithms and data science with Python'),
  ('Kubernetes Security', 'Advanced security practices for Kubernetes clusters'),
  ('Go Performance Optimization', 'High-performance Go applications and profiling'),
  ('React Native Development', 'Cross-platform mobile development with React Native'),
  ('Advanced Threat Hunting', 'Advanced cybersecurity threat detection and analysis'),
  ('Linux Kernel Development', 'Understanding and modifying the Linux kernel'),
  ('Multi-Cloud Architecture', 'Design solutions across multiple cloud providers'),
  ('Network Protocol Analysis', 'Deep dive into network protocols and traffic analysis'),
  ('Kubernetes Custom Resources', 'Develop custom controllers and operators'),
  ('Infrastructure as Code', 'Advanced Terraform and infrastructure automation'),
  
  -- Expert/Specialized Courses (31-35)
  ('AI/ML System Design', 'Design and deploy production ML systems at scale'),
  ('Cloud Native Security', 'Comprehensive security for cloud-native applications'),
  ('Distributed Systems Architecture', 'Design highly scalable distributed systems'),
  ('Blockchain Development', 'Smart contract development and DeFi applications'),
  ('Quantum Computing Fundamentals', 'Introduction to quantum algorithms and computing');

-- Learning progress sample data (expanded with advanced courses)
INSERT INTO progress (user_id, course_id, percent, updated_at) VALUES
  -- Basic users starting with fundamentals
  (1, 1, 50, NOW()), (1, 2, 0, NOW()), (1, 3, 100, NOW()),
  (2, 1, 80, NOW()), (2, 2, 20, NOW()), (2, 3, 0, NOW()),
  (3, 1, 0, NOW()), (3, 2, 0, NOW()), (3, 3, 0, NOW()),
  
  -- Advanced users with multiple completed courses
  (4, 1, 100, NOW()), (4, 2, 100, NOW()), (4, 3, 100, NOW()),
  (4, 11, 75, NOW()), (4, 12, 50, NOW()), (4, 21, 25, NOW()),
  
  -- Intermediate users progressing through different paths
  (5, 1, 10, NOW()), (5, 2, 30, NOW()), (5, 3, 60, NOW()),
  (6, 5, 100, NOW()), (6, 15, 80, NOW()), (6, 25, 40, NOW()),
  (7, 6, 100, NOW()), (7, 16, 60, NOW()), (7, 26, 20, NOW()),
  (8, 7, 100, NOW()), (8, 17, 90, NOW()), (8, 27, 70, NOW()),
  
  -- DevOps focused learning path
  (9, 9, 100, NOW()), (9, 10, 100, NOW()), (9, 19, 85, NOW()),
  (9, 20, 65, NOW()), (9, 29, 45, NOW()), (9, 30, 25, NOW()),
  
  -- Security focused learning path
  (10, 5, 100, NOW()), (10, 15, 100, NOW()), (10, 25, 90, NOW()),
  (10, 18, 75, NOW()), (10, 32, 50, NOW()),
  
  -- Full-stack development path
  (11, 1, 100, NOW()), (11, 4, 100, NOW()), (11, 11, 80, NOW()),
  (11, 14, 60, NOW()), (11, 24, 40, NOW()),
  
  -- Cloud architecture specialists
  (12, 7, 100, NOW()), (12, 17, 100, NOW()), (12, 27, 85, NOW()),
  (12, 30, 70, NOW()), (12, 32, 30, NOW()),
  
  -- Machine Learning enthusiasts
  (13, 1, 100, NOW()), (13, 21, 90, NOW()), (13, 31, 60, NOW()),
  
  -- Emerging technology explorers
  (14, 34, 80, NOW()), (14, 35, 40, NOW()),
  
  -- Comprehensive learners
  (15, 1, 100, NOW()), (15, 5, 100, NOW()), (15, 7, 100, NOW()),
  (15, 11, 90, NOW()), (15, 15, 80, NOW()), (15, 17, 70, NOW()),
  (15, 21, 60, NOW()), (15, 25, 50, NOW()), (15, 27, 40, NOW());
