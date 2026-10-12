-- 添加取消原因字段到订单表
ALTER TABLE `order` ADD COLUMN `cancel_reason` VARCHAR(500) NULL COMMENT '取消原因' AFTER `remark`;
