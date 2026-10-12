-- 删除订单号唯一索引
ALTER TABLE recharge_withdraw_record DROP INDEX uk_order_no;

-- 创建订单号和类型的联合唯一索引
ALTER TABLE recharge_withdraw_record ADD UNIQUE KEY uk_order_no_type (order_no, type);
