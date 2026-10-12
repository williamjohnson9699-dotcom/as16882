-- 添加订单支付和利润相关字段
ALTER TABLE `order`
ADD COLUMN `seller_paid` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '卖家支付状态: 0-未支付, 1-已支付' AFTER `status`,
ADD COLUMN `platform_rebate` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '平台回馈状态: 0-未回馈, 1-已回馈' AFTER `seller_paid`,
ADD COLUMN `profit_rate` DECIMAL(5,2) NOT NULL COMMENT '利润率(0-100)' AFTER `platform_rebate`,
ADD COLUMN `cost` DECIMAL(20,8) NOT NULL COMMENT '成本' AFTER `profit_rate`,
ADD COLUMN `profit` DECIMAL(20,8) NOT NULL COMMENT '利润' AFTER `cost`,
ADD COLUMN `seller_paid_time` DATETIME DEFAULT NULL COMMENT '卖家支付时间' AFTER `profit`,
ADD COLUMN `platform_rebate_time` DATETIME DEFAULT NULL COMMENT '平台回馈时间' AFTER `seller_paid_time`;
