package com.usdt.mall.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 虚拟数据导入任务
 */
@Data
@TableName("virtual_import_task")
public class VirtualImportTask {

	@TableId(type = IdType.AUTO)
	private Long id;

	/**
	 * SHOP、PRODUCT 或 ORDER_LEDGER
	 */
	private String type;

	/**
	 * PENDING、RUNNING、SUCCESS、PARTIAL、FAILED
	 */
	private String status;

	private Long adminUserId;

	private String requestJson;

	private Integer totalCount;

	private Integer successCount;

	private Integer failCount;

	private String message;

	private String failDetails;

	private LocalDateTime createTime;

	private LocalDateTime updateTime;

	private LocalDateTime finishTime;
}
