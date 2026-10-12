package com.usdt.mall.exception;

import com.usdt.mall.common.ResultCode;
import lombok.Getter;

@Getter
public class CustomException extends RuntimeException {
	private final ResultCode resultCode;

	public CustomException(ResultCode resultCode) {
		super(resultCode.getCnMsg());
		this.resultCode = resultCode;
	}

	public CustomException(ResultCode resultCode, String message) {
		super(message);
		this.resultCode = resultCode;
	}
}
