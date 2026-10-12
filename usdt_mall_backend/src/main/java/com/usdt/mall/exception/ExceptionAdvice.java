package com.usdt.mall.exception;

import com.usdt.mall.common.Result;
import com.usdt.mall.common.ResultCode;
import lombok.extern.slf4j.Slf4j;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@Slf4j
@RestControllerAdvice
public class ExceptionAdvice {

	@ExceptionHandler(Exception.class)
	public Result<?> handleException(Exception ex) {
		log.error(ex.getMessage(), ex);
		return Result.error();
	}

	@ExceptionHandler(MethodArgumentNotValidException.class)
	public Result<?> handleValidationException(MethodArgumentNotValidException ex) {
		log.error(ex.getMessage(), ex);
		Result<?> result = Result.of(ResultCode.PARAMETER_ERROR);
		FieldError fieldError = ex.getBindingResult().getFieldError();
		if (fieldError != null) {
			String message = fieldError.getDefaultMessage();
			return result.newMsg(message).newCnMsg(message);
		}
		return result;
	}

	@ExceptionHandler(CustomException.class)
	public Result<?> handleCustomException(CustomException ex) {
		log.error(ex.getMessage(), ex);
		return Result.of(ex.getResultCode());
	}
}
