-- ====================================
-- 用户表结构迁移脚本
-- 将 email 和 phone 字段合并为 username 字段
-- ====================================

USE usdt_mall;

-- 步骤1: 添加新的 username 字段
ALTER TABLE `user`
ADD COLUMN `username` VARCHAR(100) DEFAULT NULL COMMENT '用户名（邮箱或手机号）' AFTER `id`;

-- 步骤2: 迁移现有数据（优先使用 email，如果没有则使用 phone）
UPDATE `user`
SET `username` = COALESCE(`email`, `phone`)
WHERE `username` IS NULL;

-- 步骤3: 将 username 字段设置为 NOT NULL
ALTER TABLE `user`
MODIFY COLUMN `username` VARCHAR(100) NOT NULL COMMENT '用户名（邮箱或手机号）';

-- 步骤4: 添加 username 的唯一索引
ALTER TABLE `user`
ADD UNIQUE KEY `uk_username` (`username`);

-- 步骤5: 删除旧的 email 和 phone 字段及其索引
ALTER TABLE `user`
DROP INDEX `uk_email`,
DROP COLUMN `email`;

-- 验证表结构
SHOW CREATE TABLE `user`;
