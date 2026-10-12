-- ====================================
-- USDT Mall 默认数据插入脚本
-- ====================================

-- 插入默认管理员账户
-- 密码: admin123 (需要在应用中使用BCrypt加密)
INSERT INTO `user` (`username`, `nickname`, `password`, `role`, `balance`, `status`, `online_status`)
VALUES ('admin', '系统管理员', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z2EHdHkwVdpbwpSJvYNyKZPm', 'ADMIN', 0.00000000, 1, 0);

-- 插入默认分类数据
INSERT INTO `category` (`name`, `icon`, `sort`, `status`) VALUES
('生活', 'assets/pic/life.png', 1, 1),
('男鞋', 'assets/pic/man-shoe.png', 2, 1),
('女鞋', 'assets/pic/woman-shoe.png', 3, 1),
('配饰', 'assets/pic/peishi.png', 4, 1),
('男装', 'assets/pic/man-cloth.png', 5, 1),
('女装', 'assets/pic/woman-cloth.png', 6, 1),
('男包', 'assets/pic/man-bag.png', 7, 1),
('女包', 'assets/pic/woman-bag.png', 8, 1),
('男童', 'assets/pic/man-child.png', 9, 1),
('女童', 'assets/pic/woman-child.png', 10, 1),
('全球购', 'assets/pic/global.png', 11, 1);
