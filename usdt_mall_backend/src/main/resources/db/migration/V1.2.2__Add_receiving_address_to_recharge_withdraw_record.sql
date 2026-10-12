-- 添加收款地址字段到充值提现记录表
ALTER TABLE recharge_withdraw_record ADD COLUMN receiving_address VARCHAR(200) NULL COMMENT '收款地址';
