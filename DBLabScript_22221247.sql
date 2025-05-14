drop database er_database;
CREATE DATABASE IF NOT EXISTS ER_Database;
USE ER_Database;

-- Users Table
CREATE TABLE Users (
    user_id INT PRIMARY KEY AUTO_INCREMENT,
    gender VARCHAR(10),
    career_experience TEXT,
    education_experience TEXT,
    username VARCHAR(255) NOT NULL,
    password VARCHAR(255) NOT NULL
);
ALTER TABLE Users DROP PRIMARY KEY, ADD PRIMARY KEY (user_id);
-- 为 Users 表添加 password 字段

-- Membership Table
CREATE TABLE Membership (
    membership_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    membership_duration INT,
    membership_type VARCHAR(50),
    registration_date DATETIME,
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE
);

-- Comments Table
CREATE TABLE Comments (
    comment_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    publish_time DATETIME,
    location VARCHAR(255),
    upvotes INT DEFAULT 0,
    comment_text TEXT,
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE
);
CREATE  unique index idx_comment ON COMMENTs(comment_id);
drop index idx_comment on COMMENTs;
-- Questions Table
CREATE TABLE Questions (
    question_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    question_title VARCHAR(255) NOT NULL,
    question_text TEXT,
    question_time DATETIME,
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE
);

-- Answers Table
CREATE TABLE Answers (
    answer_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    answer_text TEXT,
    upvotes INT DEFAULT 0,
    answer_time DATETIME,
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE
);

-- Articles Table
CREATE TABLE Articles (
    article_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    article_title VARCHAR(255) NOT NULL,
    article_text TEXT,
    publish_time DATETIME,
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE
);

-- Messages Table
CREATE TABLE Messages (
    user_id INT,
    message_content TEXT,
    send_time DATETIME,
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE
);

-- EBooks Table
CREATE TABLE EBooks (
    category VARCHAR(100),
    content TEXT,
    author VARCHAR(255),
    price DECIMAL(10,2),
    user_id INT,
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE
);

-- Insert sample data
-- 插入 Users 表的数据
-- 插入 Users 表数据（包含加密后的密码）
INSERT INTO Users (username, gender, career_experience, education_experience, password) VALUES
('Alice', '女', '软件工程师', '麻省理工学院', '123456'),
('Bob', '男', '数据科学家', '哈佛大学', 'password123'),
('Charlie', '男', '产品经理', '斯坦福大学', 'charliepass'),
('David', '男', '网络安全专家', '加利福尼亚大学伯克利分校', 'encrypted_password_4'),
('Emma', '女', '人工智能研究员', '加州理工学院', 'encrypted_password_5'),
('Fiona', '女', '用户体验设计师', '哥伦比亚大学', 'encrypted_password_6'),
('George', '男', '运维工程师', '普林斯顿大学', 'encrypted_password_7'),
('Hannah', '女', '区块链开发者', '耶鲁大学', 'encrypted_password_8'),
('Ian', '男', '云架构师', '牛津大学', 'encrypted_password_9'),
('Julia', '女', '生物信息学科学家', '剑桥大学', 'encrypted_password_10');



-- 插入 Membership 表的数据
INSERT INTO Membership (user_id, membership_duration, membership_type, registration_date) VALUES
(1, 12, '高级', '2024-01-10'),
(2, 6, '基础', '2024-02-15'),
(3, 24, '黄金', '2023-12-20'),
(4, 3, '试用', '2024-03-01'),
(5, 12, '高级', '2024-02-25'),
(6, 6, '基础', '2024-03-05'),
(7, 12, '黄金', '2024-01-30'),
(8, 24, '高级', '2023-11-15'),
(9, 3, '试用', '2024-03-10'),
(10, 6, '基础', '2024-02-28');

-- 插入 Questions 表的数据
INSERT INTO Questions (user_id, question_title, question_text, question_time) VALUES
(1, '如何优化 SQL 查询？', '我想提高数据库性能。', '2024-03-15 10:00:00'),
(2, '深度学习模型训练的最佳实践是什么？', '如何防止过拟合？', '2024-03-16 11:30:00');

-- 插入 Answers 表的数据
INSERT INTO Answers (user_id, answer_text, upvotes, answer_time) VALUES
(3, '使用索引并避免不必要的连接。', 5, '2024-03-15 12:00:00'),
(4, '尝试使用 dropout 正则化和交叉验证。', 3, '2024-03-16 12:45:00');
INSERT INTO Answers (user_id, answer_text, upvotes, answer_time) VALUES
(5, '尝试使用 dropout 正则化和交叉验证。', 3, '2024-03-16 12:45:00');

INSERT INTO Answers (user_id, answer_text, upvotes, answer_time) VALUES
(5, '使用索引并避免不必要的连接。', 5, '2024-03-15 12:00:00');


-- 插入 Comments 表的数据
INSERT INTO Comments (user_id, publish_time, location, upvotes, comment_text) VALUES
(1, '2024-03-15 10:30:00', '北京', 10, '这个SQL优化方法非常有用，谢谢分享！'),
(2, '2024-03-16 11:00:00', '上海', 15, '深度学习的过拟合问题，使用正则化真的有效！'),
(3, '2024-03-17 09:45:00', '广州', 7, '关于区块链开发，建议增加对网络安全的考虑。'),
(4, '2024-03-17 14:20:00', '深圳', 20, '感谢这篇文章，给我很多启发，尤其是在网络安全方面。'),
(5, '2024-03-18 08:30:00', '成都', 5, '区块链的学习资源整理非常好，已经收藏了。');


-- 插入 Articles 表的数据
INSERT INTO Articles (user_id, article_title, article_text, publish_time) VALUES
(5, '神经网络简介', '神经网络是...', '2024-03-14 09:00:00');

-- 插入 Messages 表的数据
INSERT INTO Messages (user_id, message_content, send_time) VALUES
(6, '你好，我们合作吧！', '2024-03-18 14:30:00');

-- 插入 EBooks 表的数据
INSERT INTO EBooks (category, content, author, price, user_id) VALUES
('技术', '高级 SQL 技巧', 'John Doe', 29.99, 7);



