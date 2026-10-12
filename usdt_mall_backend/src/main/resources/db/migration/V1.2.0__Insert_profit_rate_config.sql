-- 插入初始利润率配置
INSERT INTO `system_config` (`config_key`, `config_value`, `config_desc`)
VALUES ('profit_rate', '65', '利润率（百分比）')
ON DUPLICATE KEY UPDATE `config_value` = '65';
