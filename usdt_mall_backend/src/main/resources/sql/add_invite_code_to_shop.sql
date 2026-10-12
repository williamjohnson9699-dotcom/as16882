-- ====================================
-- 添加邀请码字段到店铺表
-- ====================================

USE usdt_mall;

-- 添加 invite_code 字段到店铺表
ALTER TABLE `shop`
ADD COLUMN `invite_code` VARCHAR(5) DEFAULT NULL COMMENT '邀请码（5位数字，记录邀请人）'
AFTER `user_id`;

-- 为 invite_code 字段添加索引
ALTER TABLE `shop`
ADD INDEX `idx_invite_code` (`invite_code`);
