-- 商品表
CREATE TABLE IF NOT EXISTS `product` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '商品ID',
  `name` VARCHAR(255) NOT NULL COMMENT '商品名称',
  `description` TEXT COMMENT '商品描述',
  `price` DECIMAL(10, 2) NOT NULL COMMENT '商品价格',
  `stock` INT NOT NULL DEFAULT 0 COMMENT '库存数量',
  `sales` INT NOT NULL DEFAULT 0 COMMENT '销量',
  `views` INT NOT NULL DEFAULT 0 COMMENT '浏览量',
  `main_image` VARCHAR(500) COMMENT '商品主图URL',
  `images` TEXT COMMENT '商品图片列表（JSON格式）',
  `shop_id` BIGINT NOT NULL COMMENT '所属店铺ID',
  `category_id` BIGINT NOT NULL COMMENT '所属分类ID',
  `status` TINYINT NOT NULL DEFAULT 1 COMMENT '商品状态：0-下架，1-上架',
  `is_hot` TINYINT NOT NULL DEFAULT 0 COMMENT '是否热卖：0-否，1-是',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_shop_id` (`shop_id`),
  KEY `idx_category_id` (`category_id`),
  KEY `idx_status` (`status`),
  KEY `idx_is_hot` (`is_hot`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='商品表';
