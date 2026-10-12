package com.usdt.mall.vo.request;

import lombok.Data;

import java.util.List;

/**
 * 给已选店铺生成商品。count 是每家店各添加这么多条。
 */
@Data
public class VirtualProductGenerateReqVO {

	private List<Long> shopIds;

	private Integer count;
}
