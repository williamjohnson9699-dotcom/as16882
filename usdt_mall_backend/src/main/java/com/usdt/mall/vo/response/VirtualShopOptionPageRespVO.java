package com.usdt.mall.vo.response;

import lombok.Data;

import java.util.List;

/**
 * 可勾选店铺分页
 */
@Data
public class VirtualShopOptionPageRespVO {

	private List<VirtualShopOptionRespVO> records;

	private Long total;

	private Integer page;

	private Integer pageSize;
}
