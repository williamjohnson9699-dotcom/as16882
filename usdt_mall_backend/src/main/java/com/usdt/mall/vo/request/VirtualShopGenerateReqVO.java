package com.usdt.mall.vo.request;

import lombok.Data;

/**
 * 生成虚拟商店的预览和提交请求
 */
@Data
public class VirtualShopGenerateReqVO {

	/**
	 * 用户名前缀，只允许字母和数字，长度 2 到 20
	 */
	private String prefix;

	/**
	 * 本次生成数量，1 到 200
	 */
	private Integer count;

	/**
	 * 新商户号的登录密码。支付密码仍使用固定值。
	 */
	private String password;
}
