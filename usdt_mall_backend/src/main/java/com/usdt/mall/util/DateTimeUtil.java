package com.usdt.mall.util;

import java.time.LocalDateTime;
import java.time.ZoneOffset;

/**
 * 日期时间工具类
 * 统一使用UTC时间
 */
public class DateTimeUtil {

	/**
	 * 获取当前UTC时间
	 *
	 * @return UTC时间的LocalDateTime
	 */
	public static LocalDateTime nowUtc() {
		return LocalDateTime.now(ZoneOffset.UTC);
	}
}
