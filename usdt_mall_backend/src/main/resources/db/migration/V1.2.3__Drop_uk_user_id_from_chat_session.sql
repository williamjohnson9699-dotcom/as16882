-- 删除chat_session表的uk_user_id唯一索引，允许用户有多个会话
ALTER TABLE chat_session DROP INDEX uk_user_id;
