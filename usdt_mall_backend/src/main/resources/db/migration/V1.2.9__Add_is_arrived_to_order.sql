-- 添加是否到货字段到订单表
ALTER TABLE `order`
ADD COLUMN is_arrived TINYINT(1) NOT NULL DEFAULT 0 COMMENT '是否到货: 0-未到货, 1-已到货';

-- 添加索引以提高查询性能
CREATE INDEX idx_is_arrived ON `order`(is_arrived);
