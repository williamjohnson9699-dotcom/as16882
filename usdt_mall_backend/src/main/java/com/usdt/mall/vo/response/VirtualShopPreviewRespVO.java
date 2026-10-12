package com.usdt.mall.vo.response;

import lombok.Data;

import java.util.List;

/**
 * 虚拟商店衔接位置。没有已有账号时 currentMax 为 null。
 */
@Data
public class VirtualShopPreviewRespVO {

	private String prefix;

	private Integer currentMax;

	private Integer startNo;

	private Integer endNo;

	private List<String> usernames;
}
