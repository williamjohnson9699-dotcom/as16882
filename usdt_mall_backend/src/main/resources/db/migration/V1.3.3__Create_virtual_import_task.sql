CREATE TABLE `virtual_import_task` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `type` varchar(32) NOT NULL COMMENT '任务类型: SHOP-生成商店, ORDER_LEDGER-生成订单和资金',
  `status` varchar(32) NOT NULL COMMENT '任务状态: PENDING, RUNNING, SUCCESS, PARTIAL, FAILED',
  `admin_user_id` bigint NOT NULL COMMENT '提交任务的管理员',
  `request_json` json NOT NULL COMMENT '提交时的原始参数',
  `total_count` int NOT NULL DEFAULT 0 COMMENT '计划条数',
  `success_count` int NOT NULL DEFAULT 0 COMMENT '成功条数',
  `fail_count` int NOT NULL DEFAULT 0 COMMENT '失败条数',
  `message` varchar(500) DEFAULT NULL COMMENT '进度说明',
  `fail_details` json DEFAULT NULL COMMENT '失败项，每项含 target 和 reason',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `finish_time` datetime DEFAULT NULL COMMENT '结束时间',
  PRIMARY KEY (`id`),
  KEY `idx_admin_create_time` (`admin_user_id`, `create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='虚拟数据导入任务';
