-- 添加是否已读字段到账户记录表
ALTER TABLE recharge_withdraw_record ADD COLUMN is_read TINYINT(1) DEFAULT 0 COMMENT '是否已读: 0-未读, 1-已读';
