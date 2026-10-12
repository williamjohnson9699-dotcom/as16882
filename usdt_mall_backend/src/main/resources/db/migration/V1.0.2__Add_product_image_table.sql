-- 创建商品图片表
CREATE TABLE IF NOT EXISTS `product_image` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键',
  `product_id` BIGINT NOT NULL COMMENT '商品ID',
  `image_url` VARCHAR(500) NOT NULL COMMENT '图片地址',
  `sort_order` INT NOT NULL DEFAULT 0 COMMENT '排序顺序',
  `is_main` TINYINT NOT NULL DEFAULT 0 COMMENT '是否主图: 0-否, 1-是',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`),
  KEY `idx_product_id` (`product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='商品图片表';
