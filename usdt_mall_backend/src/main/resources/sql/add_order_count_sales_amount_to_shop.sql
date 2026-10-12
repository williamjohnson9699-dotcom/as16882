-- 为shop表添加订单数量和销售额字段

ALTER TABLE `shop`
ADD COLUMN `order_count` INT DEFAULT 0 COMMENT '订单数量' AFTER `credit_score`,
ADD COLUMN `sales_amount` DECIMAL(15,2) DEFAULT 0.00 COMMENT '销售额' AFTER `order_count`;
