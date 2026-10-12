package com.usdt.mall.controller;

import com.usdt.mall.common.Result;
import com.usdt.mall.service.WithdrawService;
import com.usdt.mall.vo.request.WithdrawReqVO;
import com.usdt.mall.vo.response.WithdrawRespVO;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import javax.servlet.http.HttpServletRequest;

@Tag(name = "提现管理", description = "提现相关接口")
@RestController
@RequestMapping("/api/v1/withdraw")
public class WithdrawController {

	@Autowired
	private WithdrawService withdrawService;

	@Operation(summary = "提交提现申请", description = "用户提交提现申请")
	@PostMapping("/submit")
	public Result<WithdrawRespVO> submitWithdraw(
			@RequestBody @Validated WithdrawReqVO reqVO,
			HttpServletRequest request) {
		WithdrawRespVO respVO = withdrawService.submitWithdraw(reqVO, request);
		return Result.successWith(respVO);
	}
}
