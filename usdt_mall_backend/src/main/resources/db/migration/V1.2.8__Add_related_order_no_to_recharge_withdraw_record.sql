-- 添加关联订单号字段到充值提现记录表
ALTER TABLE recharge_withdraw_record
ADD COLUMN related_order_no VARCHAR(50) NULL COMMENT '关联订单号（用于买家结算、卖家支付、平台回馈）';

-- 添加索引以提高查询性能
CREATE INDEX idx_related_order_no ON recharge_withdraw_record(related_order_no);
