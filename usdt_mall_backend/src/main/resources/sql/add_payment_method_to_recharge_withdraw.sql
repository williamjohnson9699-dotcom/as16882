-- 为充值/提现记录表添加充值方式字段
ALTER TABLE `recharge_withdraw_record`
ADD COLUMN `payment_method` VARCHAR(20) DEFAULT NULL COMMENT '充值方式: USDT-TRC20, USDT-ERC20, BTC, ETH' AFTER `type`;
