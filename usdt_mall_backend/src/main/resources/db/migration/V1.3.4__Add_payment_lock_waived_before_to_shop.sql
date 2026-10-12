ALTER TABLE `shop`
  ADD COLUMN `payment_lock_waived_before` datetime DEFAULT NULL COMMENT '管理员解封时间，此时间及之前创建的超时未支付订单不再关闭商家页面' AFTER `status`;
