-- 店铺关注表
CREATE TABLE IF NOT EXISTS `shop_follow` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '关注ID',
  `user_id` BIGINT NOT NULL COMMENT '用户ID',
  `shop_id` BIGINT NOT NULL COMMENT '店铺ID',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_shop` (`user_id`, `shop_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_shop_id` (`shop_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='店铺关注表';
