-- 添加shop_id字段到cart表
ALTER TABLE cart ADD COLUMN shop_id BIGINT NOT NULL COMMENT '店铺ID';
