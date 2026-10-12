-- 创建订单信息表
CREATE TABLE order_info (
    id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键ID',
    order_id BIGINT NOT NULL COMMENT '订单ID',
    info_type VARCHAR(50) NOT NULL COMMENT '信息类型：STATUS_CHANGE-状态变化, LOGISTICS_UPDATE-物流更新',
    content TEXT NOT NULL COMMENT '信息内容',
    operator_id BIGINT COMMENT '操作人ID',
    operator_name VARCHAR(100) COMMENT '操作人名称',
    create_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    INDEX idx_order_id (order_id),
    INDEX idx_create_time (create_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='订单信息表';
