package com.usdt.mall.common;

import com.fasterxml.jackson.annotation.JsonInclude;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Getter;
import lombok.Setter;

@Schema(description = "统一响应结果")
@Getter
@Setter
@JsonInclude(JsonInclude.Include.NON_NULL)
public class Result<T> {
	@Schema(description = "中文提示信息", example = "操作成功")
	private String cnMsg;

	@Schema(description = "英文提示信息", example = "Success")
	private String msg;

	@Schema(description = "响应状态码", example = "200")
	private Integer code;

	@Schema(description = "响应数据")
	private T data;

	private Result(ResultCode resultCode) {
		this.code = resultCode.getCode();
		this.msg = resultCode.getEnMsg();
		this.cnMsg = resultCode.getCnMsg();
	}

	public static Result<?> success() {
		return Result.of(ResultCode.SUCCESS);
	}

	public static <T> Result<T> successWith(T data) {
		return Result.<T>of(ResultCode.SUCCESS).with(data);
	}

	public static <T> Result<T> error() {
		return Result.of(ResultCode.FAIL);
	}

	public static <T> Result<T> errorWith(T data) {
		return Result.<T>of(ResultCode.FAIL).with(data);
	}

	public static <T> Result<T> of(ResultCode code) {
		return new Result<>(code);
	}

	public Result<T> with(T data) {
		this.data = data;
		return this;
	}

	public Result<T> newCode(Integer newCode) {
		this.code = newCode;
		return this;
	}

	public Result<T> newMsg(String newMsg) {
		this.msg = newMsg;
		return this;
	}

	public Result<T> newCnMsg(String newCnMsg) {
		this.cnMsg = newCnMsg;
		return this;
	}
}
