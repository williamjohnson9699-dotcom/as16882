-- 修改user表的role字段，添加SYSACCOUNT枚举值
ALTER TABLE `user` MODIFY COLUMN `role` ENUM('USER','SHOP','SERVICE','ADMIN','SYSACCOUNT') NOT NULL DEFAULT 'USER' COMMENT '角色';

-- 插入系统账户用户（平台费用接收者）
-- 用户名: sysaccount
-- 角色: SYSACCOUNT
-- 此账户仅用于记录资源往来，不能进行业务操作
INSERT INTO `user` (`username`, `nickname`, `password`, `role`, `balance`, `status`, `online_status`)
VALUES ('sysaccount', '系统账户', '$2a$10$bdipbhwGDwxHBiMlVjlQ6uf5G2CVs/0wKQfZZeFzg3PgiNnC6QVEO', 'SYSACCOUNT', 0.00000000, 1, 0);
