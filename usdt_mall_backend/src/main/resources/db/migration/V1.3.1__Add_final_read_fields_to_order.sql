-- 添加订单终态已读字段
-- 终态指：已完成(status=2)或已取消(status=3)

ALTER TABLE `order`
ADD COLUMN `buyer_final_read` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '买家终态已读: 0-未读, 1-已读' AFTER `is_arrived`,
ADD COLUMN `seller_final_read` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '卖家终态已读: 0-未读, 1-已读' AFTER `buyer_final_read`,
ADD COLUMN `service_final_read` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '客服终态已读: 0-未读, 1-已读' AFTER `seller_final_read`;

-- 为已存在的终态订单设置为已读（避免显示历史订单的未读角标）
UPDATE `order` SET `buyer_final_read` = 1, `seller_final_read` = 1, `service_final_read` = 1 WHERE `status` IN (2, 3);
