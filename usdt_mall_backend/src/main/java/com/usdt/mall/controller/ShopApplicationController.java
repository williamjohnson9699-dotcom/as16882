package com.usdt.mall.controller;

import com.usdt.mall.common.Result;
import com.usdt.mall.service.ShopApplicationService;
import com.usdt.mall.vo.request.ShopApplicationReqVO;
import com.usdt.mall.vo.response.ShopApplicationRespVO;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

@Tag(name = "店铺申请", description = "店铺申请相关接口")
@RestController
@RequestMapping("/api/v1/shop-application")
public class ShopApplicationController {

	@Autowired
	private ShopApplicationService shopApplicationService;

	@Operation(summary = "提交店铺申请", description = "提交店铺申请")
	@PostMapping("/submit")
	public Result<?> submitApplication(
			@RequestHeader("Authorization") String authorization,
			@RequestBody ShopApplicationReqVO reqVO) {
		String token = authorization.replace("Bearer ", "");
		shopApplicationService.submitApplication(token, reqVO);
		return Result.success();
	}

	@Operation(summary = "获取我的申请", description = "获取当前用户的申请状态")
	@GetMapping("/my")
	public Result<ShopApplicationRespVO> getMyApplication(
			@RequestHeader("Authorization") String authorization) {
		String token = authorization.replace("Bearer ", "");
		ShopApplicationRespVO application = shopApplicationService.getMyApplication(token);
		return Result.successWith(application);
	}

	@Operation(summary = "获取我的申请历史", description = "获取当前用户的所有申请历史")
	@GetMapping("/my/history")
	public Result<?> getMyApplicationHistory(
			@RequestHeader("Authorization") String authorization) {
		String token = authorization.replace("Bearer ", "");
		return Result.successWith(shopApplicationService.getMyApplicationHistory(token));
	}

	@Operation(summary = "分页查询申请列表", description = "管理员分页查询店铺申请列表")
	@GetMapping("/page")
	public Result<?> getApplicationsByPage(
			@RequestHeader("Authorization") String authorization,
			@RequestParam(required = false) String status,
			@RequestParam(required = false) String keyword,
			@RequestParam(defaultValue = "1") Integer page,
			@RequestParam(defaultValue = "10") Integer pageSize) {
		String token = authorization.replace("Bearer ", "");
		return Result.successWith(shopApplicationService.getApplicationsByPage(token, status, keyword, page, pageSize));
	}

	@Operation(summary = "审核通过", description = "管理员审核通过店铺申请")
	@PostMapping("/approve/{id}")
	public Result<?> approveApplication(
			@RequestHeader("Authorization") String authorization,
			@PathVariable Long id) {
		String token = authorization.replace("Bearer ", "");
		shopApplicationService.approveApplication(token, id);
		return Result.success();
	}

	@Operation(summary = "审核拒绝", description = "管理员审核拒绝店铺申请")
	@PostMapping("/reject/{id}")
	public Result<?> rejectApplication(
			@RequestHeader("Authorization") String authorization,
			@PathVariable Long id,
			@RequestParam String reviewNote) {
		String token = authorization.replace("Bearer ", "");
		shopApplicationService.rejectApplication(token, id, reviewNote);
		return Result.success();
	}

	@Operation(summary = "获取待审核数量", description = "获取待审核的店铺申请数量")
	@GetMapping("/pending-count")
	public Result<Integer> getPendingCount(@RequestHeader("Authorization") String authorization) {
		String token = authorization.replace("Bearer ", "");
		int count = shopApplicationService.getPendingCount(token);
		return Result.successWith(count);
	}
}
