-- 会话只从自己的列表隐藏，不删除消息，不影响对方
ALTER TABLE `chat_session`
ADD COLUMN `user_hidden` TINYINT NOT NULL DEFAULT 0 COMMENT '用户侧是否隐藏: 0-显示, 1-隐藏' AFTER `status`,
ADD COLUMN `handler_hidden` TINYINT NOT NULL DEFAULT 0 COMMENT '处理人侧是否隐藏: 0-显示, 1-隐藏' AFTER `user_hidden`;
