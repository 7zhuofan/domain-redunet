USE ER_Database;

-- =============================
-- 1. 存储过程实现
-- =============================

-- 1.1 单表或多表查询 - 获取用户和会员信息
DELIMITER //
CREATE PROCEDURE sp_get_users_with_membership()
BEGIN
    SELECT u.user_id, u.username, u.gender, u.career_experience, 
           u.education_experience, m.membership_type, m.membership_duration, 
           m.registration_date
    FROM Users u
    LEFT JOIN Membership m ON u.user_id = m.user_id
    ORDER BY u.user_id;
END //
DELIMITER ;

-- 1.2 数据插入 - 添加新用户
DELIMITER //
CREATE PROCEDURE sp_add_user(
    IN p_username VARCHAR(255),
    IN p_gender VARCHAR(10),
    IN p_career_experience TEXT,
    IN p_education_experience TEXT,
    IN p_password VARCHAR(255),
)
BEGIN
    -- 检查用户名是否已存在
    DECLARE user_exists INT DEFAULT 0;
    
    SELECT COUNT(*) INTO user_exists FROM Users WHERE username = p_username;
    -- 插入新用户
    INSERT INTO Users (username, gender, career_experience, education_experience, password)
    VALUES (p_username, p_gender, p_career_experience, p_education_experience, p_password);
        
        
END //
DELIMITER ;

-- 1.3 数据删除 - 删除用户及其相关数据
DELIMITER //
CREATE PROCEDURE sp_delete_user(
    IN p_user_id INT,
    OUT p_success BOOLEAN
)
BEGIN
    DECLARE exit_handler BOOLEAN DEFAULT TRUE;
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET exit_handler = FALSE;
    
    START TRANSACTION;
    
    -- 删除用户
    DELETE FROM Users WHERE user_id = p_user_id;
    
    IF exit_handler THEN
        COMMIT;
        SET p_success = TRUE;
    ELSE
        ROLLBACK;
        SET p_success = FALSE;
    END IF;
END //
DELIMITER ;

-- 1.4 数据修改 - 更新用户信息
DELIMITER //
CREATE PROCEDURE sp_update_user(
    IN p_user_id INT,
    IN p_username VARCHAR(255),
    IN p_gender VARCHAR(10),
    IN p_career_experience TEXT,
    IN p_education_experience TEXT,
    IN p_password VARCHAR(255),
    OUT p_success BOOLEAN
)
BEGIN
    DECLARE user_exists INT DEFAULT 0;
    DECLARE exit_handler BOOLEAN DEFAULT TRUE;
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET exit_handler = FALSE;
    
    -- 检查新用户名是否已被其他用户使用
    SELECT COUNT(*) INTO user_exists 
    FROM Users 
    WHERE username = p_username AND user_id != p_user_id;
    
    IF user_exists = 0 THEN
        START TRANSACTION;
        
        -- 更新用户信息
        UPDATE Users 
        SET username = p_username,
            gender = p_gender,
            career_experience = p_career_experience,
            education_experience = p_education_experience,
            password = p_password
        WHERE user_id = p_user_id;
        
        IF exit_handler THEN
            COMMIT;
            SET p_success = TRUE;
        ELSE
            ROLLBACK;
            SET p_success = FALSE;
        END IF;
    ELSE
        -- 用户名已被其他用户使用
        SET p_success = FALSE;
    END IF;
END //
DELIMITER ;

-- 1.5 高级多表查询 - 获取用户活动摘要
DELIMITER //
CREATE PROCEDURE sp_get_user_activity_summary(
    IN p_user_id INT
)
BEGIN
    -- 用户基本信息
    SELECT 
        u.user_id, 
        u.username, 
        u.gender, 
        m.membership_type,
        m.registration_date
    FROM Users u
    LEFT JOIN Membership m ON u.user_id = m.user_id
    WHERE u.user_id = p_user_id;
    
    -- 用户发布的问题数量
    SELECT COUNT(*) as question_count
    FROM Questions
    WHERE user_id = p_user_id;
    
    -- 用户发布的回答数量
    SELECT COUNT(*) as answer_count
    FROM Answers
    WHERE user_id = p_user_id;
    
    -- 用户发表的评论数量
    SELECT COUNT(*) as comment_count
    FROM Comments
    WHERE user_id = p_user_id;
    
    -- 用户获得的总赞数
    SELECT COALESCE(SUM(upvotes), 0) as total_upvotes
    FROM (
        SELECT upvotes FROM Comments WHERE user_id = p_user_id
        UNION ALL
        SELECT upvotes FROM Answers WHERE user_id = p_user_id
    ) as combined_upvotes;
end //
DELIMITER ;

-- =============================
-- 2. 触发器实现
-- =============================

-- 2.1 数据插入触发器 - 新用户自动创建会员记录
DELIMITER //
CREATE TRIGGER tr_after_user_insert
AFTER INSERT ON Users
FOR EACH ROW
BEGIN
    -- 为新用户创建基础会员记录
    INSERT INTO Membership (user_id, membership_duration, membership_type, registration_date)
    VALUES (NEW.user_id, 3, '试用', NOW());
END //
DELIMITER ;

-- 2.2 数据更新触发器 - 记录用户信息变更日志
DELIMITER //
CREATE TABLE IF NOT EXISTS user_updates_log (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    action_type VARCHAR(20) NOT NULL,
    action_time DATETIME NOT NULL,
    details TEXT
) //

CREATE TRIGGER tr_after_user_update
AFTER UPDATE ON Users
FOR EACH ROW
BEGIN
    DECLARE changes TEXT DEFAULT '';
    
    -- 检查哪些字段被修改并记录
    IF NEW.username != OLD.username THEN
        SET changes = CONCAT(changes, '用户名从"', OLD.username, '"变更为"', NEW.username, '"; ');
    END IF;
    
    IF NEW.gender != OLD.gender THEN
        SET changes = CONCAT(changes, '性别从"', OLD.gender, '"变更为"', NEW.gender, '"; ');
    END IF;
    
    IF NEW.career_experience != OLD.career_experience THEN
        SET changes = CONCAT(changes, '职业经验已更新; ');
    END IF;
    
    IF NEW.education_experience != OLD.education_experience THEN
        SET changes = CONCAT(changes, '教育经历已更新; ');
    END IF;
    
    IF NEW.password != OLD.password THEN
        SET changes = CONCAT(changes, '密码已更新; ');
    END IF;
    
    -- 记录变更日志
    IF changes != '' THEN
        INSERT INTO user_updates_log (user_id, action_type, action_time, details)
        VALUES (NEW.user_id, 'UPDATE', NOW(), changes);
    END IF;
END //
DELIMITER ;

-- 2.3 数据删除触发器 - 记录用户删除日志
DELIMITER //
CREATE TABLE IF NOT EXISTS user_deletion_log (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    deleted_user_id INT NOT NULL,
    deleted_username VARCHAR(255) NOT NULL,
    deletion_time DATETIME NOT NULL,
    deletion_details TEXT
) //

CREATE TRIGGER tr_before_user_delete
BEFORE DELETE ON Users
FOR EACH ROW
BEGIN
    -- 记录被删除的用户信息
    INSERT INTO user_deletion_log (deleted_user_id, deleted_username, deletion_time, deletion_details)
    VALUES (
        OLD.user_id, 
        OLD.username, 
        NOW(), 
        CONCAT('用户ID: ', OLD.user_id, ', 用户名: ', OLD.username, ', 性别: ', OLD.gender)
    );
END //
DELIMITER ;