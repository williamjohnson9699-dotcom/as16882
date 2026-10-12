-- 添加消息已读状态字段
ALTER TABLE `chat_message` ADD COLUMN `is_read` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '是否已读：0-未读，1-已读' AFTER `content`;
