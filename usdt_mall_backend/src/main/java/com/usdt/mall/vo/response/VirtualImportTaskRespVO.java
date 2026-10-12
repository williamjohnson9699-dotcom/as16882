package com.usdt.mall.vo.response;

import lombok.Data;

import java.time.LocalDateTime;

/**
 * 虚拟导入任务
 */
@Data
public class VirtualImportTaskRespVO {

	private Long id;

	private String type;

	private String status;

	private Long adminUserId;

	/**
	 * 提交时的原始参数
	 */
	private Object requestJson;

	private Integer totalCount;

	private Integer successCount;

	private Integer failCount;

	private String message;

	/**
	 * 失败项，每项含 target 和 reason
	 */
	private Object failDetails;

	private LocalDateTime createTime;

	private LocalDateTime updateTime;

	private LocalDateTime finishTime;
}
