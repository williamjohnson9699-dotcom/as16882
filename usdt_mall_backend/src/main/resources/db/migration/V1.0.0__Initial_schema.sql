-- ====================================
-- USDT Mall 数据库初始化脚本
-- ====================================

-- 创建用户表
CREATE TABLE IF NOT EXISTS `user` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键',
  `username` VARCHAR(100) NOT NULL COMMENT '用户名（邮箱或手机号）',
  `nickname` VARCHAR(50) NOT NULL COMMENT '昵称',
  `password` VARCHAR(255) NOT NULL COMMENT '密码hash',
  `payment_password` VARCHAR(255) DEFAULT NULL COMMENT '支付密码hash',
  `avatar` VARCHAR(255) DEFAULT NULL COMMENT '头像URL',
  `role` ENUM('USER','SHOP','SERVICE','ADMIN') NOT NULL DEFAULT 'USER' COMMENT '角色',
  `invite_code` VARCHAR(50) DEFAULT NULL COMMENT '邀请码',
  `balance` DECIMAL(20,8) NOT NULL DEFAULT 0.00000000 COMMENT '余额',
  `status` TINYINT NOT NULL DEFAULT 1 COMMENT '状态: 0-禁用, 1-正常',
  `online_status` TINYINT NOT NULL DEFAULT 0 COMMENT '登录状态: 0-离线, 1-在线',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_username` (`username`),
  KEY `idx_role` (`role`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户表';

-- 创建用户地址表
CREATE TABLE IF NOT EXISTS `user_address` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键',
  `user_id` BIGINT NOT NULL COMMENT '用户ID',
  `receiver_name` VARCHAR(50) NOT NULL COMMENT '收货人',
  `receiver_phone` VARCHAR(20) NOT NULL COMMENT '联系电话',
  `detail_address` VARCHAR(500) NOT NULL COMMENT '详细地址',
  `is_default` TINYINT NOT NULL DEFAULT 0 COMMENT '是否默认: 0-否, 1-是',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户地址表';

-- 创建店铺关注表
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

-- 创建店铺表
CREATE TABLE IF NOT EXISTS `shop` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '店铺ID',
  `name` VARCHAR(255) NOT NULL COMMENT '店铺名称',
  `logo` VARCHAR(500) COMMENT '店铺图标URL',
  `level` INT NOT NULL DEFAULT 1 COMMENT '店铺等级',
  `rating` DECIMAL(3, 1) NOT NULL DEFAULT 5.0 COMMENT '店铺评分',
  `follow_count` INT NOT NULL DEFAULT 0 COMMENT '关注数量',
  `views` INT NOT NULL DEFAULT 0 COMMENT '浏览量',
  `credit_score` INT NOT NULL DEFAULT 100 COMMENT '信誉分',
  `user_id` BIGINT NOT NULL COMMENT '店主用户ID',
  `invite_code` VARCHAR(10) COMMENT '邀请码',
  `category` VARCHAR(50) COMMENT '主营业务类别',
  `contact_name` VARCHAR(100) COMMENT '联系人姓名',
  `contact_phone` VARCHAR(20) COMMENT '联系人电话',
  `address` VARCHAR(500) COMMENT '店铺地址',
  `status` TINYINT NOT NULL DEFAULT 1 COMMENT '店铺状态：0-关闭，1-营业',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='店铺表';

-- 创建店铺统计表
CREATE TABLE IF NOT EXISTS `shop_statistics` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键',
  `shop_id` BIGINT NOT NULL COMMENT '店铺ID',
  `stat_date` DATE NOT NULL COMMENT '统计日期',
  `order_count` INT NOT NULL DEFAULT 0 COMMENT '订单数量',
  `sales_amount` DECIMAL(20,8) NOT NULL DEFAULT 0.00000000 COMMENT '销售额',
  `profit_amount` DECIMAL(20,8) NOT NULL DEFAULT 0.00000000 COMMENT '利润',
  `profit_rate` DECIMAL(5,2) NOT NULL DEFAULT 0.00 COMMENT '利润率',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_shop_id` (`shop_id`),
  KEY `idx_stat_date` (`stat_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='店铺统计表';

-- 创建系统公告表
CREATE TABLE IF NOT EXISTS `system_announcement` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '公告ID',
  `title` VARCHAR(200) NOT NULL COMMENT '公告标题',
  `content` TEXT NOT NULL COMMENT '公告内容',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='系统公告表';

-- 创建店铺申请表
CREATE TABLE IF NOT EXISTS `shop_application` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '申请ID',
  `user_id` BIGINT NOT NULL COMMENT '用户ID',
  `shop_name` VARCHAR(100) NOT NULL COMMENT '店铺名称',
  `shop_logo` VARCHAR(500) COMMENT '店铺Logo',
  `contact_name` VARCHAR(50) NOT NULL COMMENT '联系人姓名',
  `contact_phone` VARCHAR(20) NOT NULL COMMENT '联系人电话',
  `id_number` VARCHAR(50) NOT NULL COMMENT '证件号码',
  `id_front_image` VARCHAR(500) COMMENT '证件正面照片',
  `id_back_image` VARCHAR(500) COMMENT '证件反面照片',
  `category` VARCHAR(50) NOT NULL COMMENT '主营业务',
  `address` VARCHAR(255) NOT NULL COMMENT '详细地址',
  `invite_code` VARCHAR(50) COMMENT '邀请码',
  `status` VARCHAR(20) NOT NULL DEFAULT 'pending' COMMENT '申请状态：pending-待审核，approved-已通过，rejected-已拒绝',
  `review_note` VARCHAR(500) COMMENT '审核备注',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='店铺申请表';

-- 创建充值/提现记录表
CREATE TABLE IF NOT EXISTS `recharge_withdraw_record` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '记录ID',
  `user_id` BIGINT NOT NULL COMMENT '用户ID',
  `order_no` VARCHAR(50) NOT NULL COMMENT '订单号',
  `type` INT NOT NULL COMMENT '类型: 1-充值, 2-提现',
  `payment_method` VARCHAR(20) COMMENT '充值方式: USDT, BTC, ETH',
  `amount` DECIMAL(20, 2) NOT NULL COMMENT '金额',
  `status` INT NOT NULL DEFAULT 0 COMMENT '状态: 0-待审核, 1-已通过, 2-已拒绝',
  `proof_image` VARCHAR(500) COMMENT '凭证图片URL',
  `auditor_id` BIGINT COMMENT '审核人ID',
  `audit_time` DATETIME COMMENT '审核时间',
  `remark` VARCHAR(500) COMMENT '备注',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_order_no` (`order_no`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_type` (`type`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='充值/提现记录表';

-- 创建商品表
CREATE TABLE IF NOT EXISTS `product` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键',
  `name` VARCHAR(200) NOT NULL COMMENT '商品名称',
  `description` TEXT COMMENT '商品描述',
  `price` DECIMAL(20,8) NOT NULL COMMENT '单价',
  `stock` INT NOT NULL DEFAULT 0 COMMENT '库存',
  `sales` INT NOT NULL DEFAULT 0 COMMENT '销量',
  `views` INT NOT NULL DEFAULT 0 COMMENT '浏览量',
  `main_image` VARCHAR(255) COMMENT '商品主图URL',
  `images` TEXT COMMENT '商品图片列表（JSON格式）',
  `shop_id` BIGINT NOT NULL COMMENT '所属店铺ID',
  `category_id` BIGINT COMMENT '所属分类ID',
  `status` TINYINT NOT NULL DEFAULT 1 COMMENT '状态: 0-下架, 1-上架',
  `is_hot` TINYINT NOT NULL DEFAULT 0 COMMENT '是否热卖: 0-否, 1-是',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_shop_id` (`shop_id`),
  KEY `idx_category_id` (`category_id`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='商品表';

-- 创建店铺商品关联表
CREATE TABLE IF NOT EXISTS `shop_product` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键',
  `shop_id` BIGINT NOT NULL COMMENT '店铺ID',
  `product_id` BIGINT NOT NULL COMMENT '商品ID',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_shop_product` (`shop_id`, `product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='店铺商品关联表';

-- 创建分类表
CREATE TABLE IF NOT EXISTS `category` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键',
  `name` VARCHAR(50) NOT NULL COMMENT '分类名称',
  `icon` VARCHAR(255) COMMENT '分类图标URL',
  `sort` INT NOT NULL DEFAULT 0 COMMENT '排序',
  `status` TINYINT NOT NULL DEFAULT 1 COMMENT '状态: 0-禁用, 1-启用',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='分类表';

-- 创建购物车表
CREATE TABLE IF NOT EXISTS `cart` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键',
  `user_id` BIGINT NOT NULL COMMENT '用户ID',
  `product_id` BIGINT NOT NULL COMMENT '商品ID',
  `quantity` INT NOT NULL COMMENT '数量',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_product_id` (`product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='购物车表';

-- 创建订单表
CREATE TABLE IF NOT EXISTS `order` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键',
  `order_no` VARCHAR(32) NOT NULL COMMENT '订单号',
  `user_id` BIGINT NOT NULL COMMENT '购买用户ID',
  `shop_id` BIGINT NOT NULL COMMENT '店铺ID',
  `address_id` BIGINT NOT NULL COMMENT '收货地址ID',
  `total_amount` DECIMAL(20,8) NOT NULL COMMENT '订单总金额',
  `order_type` TINYINT NOT NULL COMMENT '订单类型: 1-用户购买, 2-系统代理',
  `agent_id` BIGINT DEFAULT NULL COMMENT '代理人ID',
  `status` TINYINT NOT NULL DEFAULT 1 COMMENT '订单状态: 1-待支付, 2-待发货, 3-待收货, 4-已完成, 5-已取消',
  `remark` VARCHAR(500) DEFAULT NULL COMMENT '备注',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_order_no` (`order_no`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_shop_id` (`shop_id`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='订单表';

-- 创建订单明细表
CREATE TABLE IF NOT EXISTS `order_item` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键',
  `order_id` BIGINT NOT NULL COMMENT '订单ID',
  `product_id` BIGINT NOT NULL COMMENT '商品ID',
  `product_name` VARCHAR(200) NOT NULL COMMENT '商品名称快照',
  `product_image` VARCHAR(255) DEFAULT NULL COMMENT '商品图片快照',
  `price` DECIMAL(20,8) NOT NULL COMMENT '购买单价',
  `quantity` INT NOT NULL COMMENT '购买数量',
  `subtotal` DECIMAL(20,8) NOT NULL COMMENT '小计',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`),
  KEY `idx_order_id` (`order_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='订单明细表';

-- 创建账户交易记录表
CREATE TABLE IF NOT EXISTS `account_transaction` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键',
  `user_id` BIGINT NOT NULL COMMENT '用户ID',
  `transaction_no` VARCHAR(32) NOT NULL COMMENT '交易流水号',
  `transaction_type` TINYINT NOT NULL COMMENT '交易类型: 1-充值, 2-提现, 3-订单支出, 4-订单收入',
  `amount` DECIMAL(20,8) NOT NULL COMMENT '金额',
  `balance_before` DECIMAL(20,8) NOT NULL COMMENT '交易前余额',
  `balance_after` DECIMAL(20,8) NOT NULL COMMENT '交易后余额',
  `related_order_id` BIGINT NOT NULL COMMENT '关联订单ID',
  `remark` VARCHAR(500) DEFAULT NULL COMMENT '备注',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_transaction_no` (`transaction_no`),
  KEY `idx_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='账户交易记录表';

-- 创建聊天会话表
CREATE TABLE IF NOT EXISTS `chat_session` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键',
  `user_id` BIGINT NOT NULL COMMENT '用户/店铺ID',
  `handler_id` BIGINT DEFAULT NULL COMMENT '处理人ID',
  `last_message` TEXT COMMENT '最后一条消息',
  `last_message_time` DATETIME DEFAULT NULL COMMENT '最后消息时间',
  `unread_count` INT NOT NULL DEFAULT 0 COMMENT '未读消息数',
  `status` TINYINT NOT NULL DEFAULT 1 COMMENT '状态: 1-待处理, 2-处理中, 3-已结束',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_id` (`user_id`),
  KEY `idx_handler_id` (`handler_id`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='聊天会话表';

-- 创建聊天消息表
CREATE TABLE IF NOT EXISTS `chat_message` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键',
  `session_id` BIGINT NOT NULL COMMENT '会话ID',
  `sender_id` BIGINT NOT NULL COMMENT '发送者ID',
  `sender_type` TINYINT NOT NULL COMMENT '发送者类型: 1-用户, 2-客服/管理员',
  `message_type` TINYINT NOT NULL COMMENT '消息类型: 1-文字, 2-图片, 3-表情',
  `content` TEXT NOT NULL COMMENT '消息内容',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`),
  KEY `idx_session_id` (`session_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='聊天消息表';

-- 创建系统配置表
CREATE TABLE IF NOT EXISTS `system_config` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键',
  `config_key` VARCHAR(100) NOT NULL COMMENT '配置键',
  `config_value` TEXT COMMENT '配置值',
  `config_desc` VARCHAR(255) DEFAULT NULL COMMENT '配置描述',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_config_key` (`config_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='系统配置表';

-- 创建利润率配置表
CREATE TABLE IF NOT EXISTS `profit_rate_config` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键',
  `profit_rate` INT NOT NULL COMMENT '利润率(1-99)',
  `effective_date` DATE NOT NULL COMMENT '生效日期',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_effective_date` (`effective_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='利润率配置表';

-- 创建系统统计表
CREATE TABLE IF NOT EXISTS `system_statistics` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键',
  `stat_date` DATE NOT NULL COMMENT '统计日期',
  `order_count` INT NOT NULL DEFAULT 0 COMMENT '订单数量',
  `sales_amount` DECIMAL(20,8) NOT NULL DEFAULT 0.00000000 COMMENT '销售额',
  `cost_amount` DECIMAL(20,8) NOT NULL DEFAULT 0.00000000 COMMENT '成本',
  `profit_amount` DECIMAL(20,8) NOT NULL DEFAULT 0.00000000 COMMENT '利润',
  `avg_profit_rate` DECIMAL(5,2) NOT NULL DEFAULT 0.00 COMMENT '平均利润率',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_stat_date` (`stat_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='系统统计表';

-- 创建APP版本管理表
CREATE TABLE IF NOT EXISTS `app_version` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键',
  `platform` VARCHAR(20) NOT NULL COMMENT '平台: android/ios',
  `version_code` INT NOT NULL COMMENT '版本号',
  `version_name` VARCHAR(20) NOT NULL COMMENT '版本名称',
  `download_url` VARCHAR(500) NOT NULL COMMENT '下载地址',
  `update_desc` TEXT COMMENT '更新说明',
  `is_force_update` TINYINT NOT NULL DEFAULT 0 COMMENT '是否强制更新: 0-否, 1-是',
  `status` TINYINT NOT NULL DEFAULT 1 COMMENT '状态: 0-禁用, 1-启用',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_platform` (`platform`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='APP版本管理表';
