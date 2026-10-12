-- 添加用户未读消息数字段
ALTER TABLE `chat_session` ADD COLUMN `user_unread_count` INT NOT NULL DEFAULT 0 COMMENT '用户未读消息数（客服/管理员发送的消息）' AFTER `unread_count`;

-- 重命名原有的 unread_count 为 service_unread_count 以更清晰
ALTER TABLE `chat_session` CHANGE COLUMN `unread_count` `service_unread_count` INT NOT NULL DEFAULT 0 COMMENT '客服/管理员未读消息数（用户发送的消息）';
