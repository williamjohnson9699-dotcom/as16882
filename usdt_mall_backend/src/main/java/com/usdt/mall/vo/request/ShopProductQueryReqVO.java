package com.usdt.mall.vo.request;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

/**
 * 店铺商品查询请求VO
 */
@Schema(description = "店铺商品查询请求")
@Data
public class ShopProductQueryReqVO {

	@Schema(description = "关键词（商品名称）")
	private String keyword;

	@Schema(description = "分类")
	private String category;

	@Schema(description = "页码", example = "1")
	private Integer page = 1;

	@Schema(description = "每页数量", example = "10")
	private Integer pageSize = 10;
}
