package com.usdt.mall.vo.response;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 店铺信息响应VO
 */
@Schema(description = "店铺信息响应")
@Data
public class ShopInfoRespVO {

	@Schema(description = "店铺ID")
	private Long id;

	@Schema(description = "用户ID")
	private Long userId;

	@Schema(description = "店铺名称")
	private String shopName;

	@Schema(description = "店铺Logo")
	private String logo;

	@Schema(description = "联系人名称")
	private String contactName;

	@Schema(description = "联系人电话")
	private String contactPhone;

	@Schema(description = "证件号码")
	private String idNumber;

	@Schema(description = "证件正面")
	private String idFrontImage;

	@Schema(description = "证件反面")
	private String idBackImage;

	@Schema(description = "主营业务")
	private String category;

	@Schema(description = "邀请码")
	private String inviteCode;

	@Schema(description = "地址")
	private String address;

	@Schema(description = "店主昵称")
	private String ownerNickname;

	@Schema(description = "店铺等级")
	private Integer level;

	@Schema(description = "店铺评分")
	private Double rating;

	@Schema(description = "关注数量")
	private Integer followCount;

	@Schema(description = "浏览量")
	private Integer views;

	@Schema(description = "信誉分")
	private Integer creditScore;

	@Schema(description = "商品数量")
	private Integer productCount;

	@Schema(description = "订单数")
	private Integer orderCount;

	@Schema(description = "销售额")
	private Double salesAmount;

	@Schema(description = "店铺状态")
	private String status;

	@Schema(description = "是否因超时未支付而关闭商家页面")
	private Boolean paymentOverdue;

	@Schema(description = "创建时间")
	private LocalDateTime createTime;
}
