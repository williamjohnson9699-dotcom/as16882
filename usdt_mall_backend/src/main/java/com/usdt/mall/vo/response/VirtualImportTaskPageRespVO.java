package com.usdt.mall.vo.response;

import lombok.Data;

import java.util.List;

/**
 * 虚拟导入任务分页
 */
@Data
public class VirtualImportTaskPageRespVO {

	private List<VirtualImportTaskRespVO> records;

	private Long total;

	private Integer page;

	private Integer pageSize;

	private Integer totalPages;
}
