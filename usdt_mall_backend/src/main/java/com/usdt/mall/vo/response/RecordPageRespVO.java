package com.usdt.mall.vo.response;

import lombok.Data;

import java.util.List;

/**
 * 记录分页响应VO
 */
@Data
public class RecordPageRespVO {

	/**
	 * 记录列表
	 */
	private List<RecordInfoRespVO> records;

	/**
	 * 总记录数
	 */
	private Long total;

	/**
	 * 当前页码
	 */
	private Integer page;

	/**
	 * 每页数量
	 */
	private Integer pageSize;

	/**
	 * 总页数
	 */
	private Integer totalPages;
}
