package com.usdt.mall.controller;

import com.usdt.mall.common.Result;
import com.usdt.mall.service.RechargeService;
import com.usdt.mall.vo.request.RechargeReqVO;
import com.usdt.mall.vo.response.RechargeRespVO;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import javax.servlet.http.HttpServletRequest;

@Tag(name = "充值管理", description = "充值相关接口")
@RestController
@RequestMapping("/api/v1/recharge")
public class RechargeController {

	@Autowired
	private RechargeService rechargeService;

	@Operation(summary = "提交充值申请", description = "用户提交充值申请")
	@PostMapping("/submit")
	public Result<RechargeRespVO> submitRecharge(
			@RequestBody @Validated RechargeReqVO reqVO,
			HttpServletRequest request) {
		RechargeRespVO respVO = rechargeService.submitRecharge(reqVO, request);
		return Result.successWith(respVO);
	}
}
