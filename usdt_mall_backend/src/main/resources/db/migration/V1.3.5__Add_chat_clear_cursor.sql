-- 删除会话时只记录清空位置，不删除消息行
ALTER TABLE `chat_session`
ADD COLUMN `user_cleared_message_id` BIGINT DEFAULT NULL COMMENT '用户侧已清空到的消息ID' AFTER `handler_hidden`,
ADD COLUMN `handler_cleared_message_id` BIGINT DEFAULT NULL COMMENT '处理人侧已清空到的消息ID' AFTER `user_cleared_message_id`;
