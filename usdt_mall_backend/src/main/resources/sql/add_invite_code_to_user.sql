-- ====================================
-- 添加邀请码字段到用户表
-- ====================================

USE usdt_mall;

-- 添加 invite_code 字段（5位数字，从10000开始）
ALTER TABLE `user`
ADD COLUMN `invite_code` VARCHAR(5) DEFAULT NULL COMMENT '邀请码（5位数字，用于标注用户的唯一ID）'
AFTER `role`;

-- 为 invite_code 字段添加唯一索引
ALTER TABLE `user`
ADD UNIQUE INDEX `uk_invite_code` (`invite_code`);

-- 为现有用户生成唯一的邀请码（从10000开始）
UPDATE `user`
SET `invite_code` = CAST((10000 + id - 1) AS CHAR(5))
WHERE `invite_code` IS NULL;
