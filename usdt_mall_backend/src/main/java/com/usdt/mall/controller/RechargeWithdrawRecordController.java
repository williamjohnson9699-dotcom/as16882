package com.usdt.mall.controller;

import com.usdt.mall.common.Result;
import com.usdt.mall.service.RechargeWithdrawRecordService;
import com.usdt.mall.vo.request.RecordQueryReqVO;
import com.usdt.mall.vo.response.RecordPageRespVO;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@Tag(name = "账户记录", description = "充值/提现记录相关接口")
@RestController
@RequestMapping("/api/v1/account-records")
public class RechargeWithdrawRecordController {

	@Autowired
	private RechargeWithdrawRecordService recordService;

	@Operation(summary = "分页查询记录", description = "分页查询用户的充值/提现记录")
	@GetMapping("/page")
	public Result<RecordPageRespVO> getRecordsByPage(
			@RequestHeader("Authorization") String authorization,
			@RequestParam(required = false) Integer type,
			@RequestParam(defaultValue = "1") Integer page,
			@RequestParam(defaultValue = "10") Integer pageSize) {
		String token = authorization.replace("Bearer ", "");

		RecordQueryReqVO reqVO = new RecordQueryReqVO();
		reqVO.setType(type);
		reqVO.setPage(page);
		reqVO.setPageSize(pageSize);

		RecordPageRespVO respVO = recordService.getRecordsByPage(token, reqVO);
		return Result.successWith(respVO);
	}

	@Operation(summary = "管理员分页查询所有记录", description = "管理员/客服分页查询所有用户的充值/提现记录，支持搜索")
	@GetMapping("/admin/page")
	public Result<RecordPageRespVO> getAllRecordsByPage(
			@RequestHeader("Authorization") String authorization,
			@RequestParam(required = false) String keyword,
			@RequestParam(required = false) Integer type,
			@RequestParam(defaultValue = "1") Integer page,
			@RequestParam(defaultValue = "10") Integer pageSize) {
		String token = authorization.replace("Bearer ", "");
		RecordPageRespVO respVO = recordService.getAllRecordsByPage(token, keyword, type, page, pageSize);
		return Result.successWith(respVO);
	}

	@Operation(summary = "审核通过", description = "管理员/客服审核通过充值/提现记录")
	@PostMapping("/admin/approve/{recordId}")
	public Result<?> approveRecord(
			@RequestHeader("Authorization") String authorization,
			@PathVariable Long recordId) {
		String token = authorization.replace("Bearer ", "");
		recordService.approveRecord(token, recordId);
		return Result.success();
	}

	@Operation(summary = "审核拒绝", description = "管理员/客服拒绝充值/提现记录")
	@PostMapping("/admin/reject/{recordId}")
	public Result<?> rejectRecord(
			@RequestHeader("Authorization") String authorization,
			@PathVariable Long recordId) {
		String token = authorization.replace("Bearer ", "");
		recordService.rejectRecord(token, recordId);
		return Result.success();
	}

	@Operation(summary = "获取待处理记录数量", description = "获取待处理的充值和提现记录数量")
	@GetMapping("/pending-count")
	public Result<Map<String, Integer>> getPendingCount(@RequestHeader("Authorization") String authorization) {
		String token = authorization.replace("Bearer ", "");
		Map<String, Integer> counts = recordService.getPendingCount(token);
		return Result.successWith(counts);
	}

	@Operation(summary = "标记为已读", description = "标记记录为已读")
	@PostMapping("/{recordId}/mark-read")
	public Result<?> markAsRead(
			@RequestHeader("Authorization") String authorization,
			@PathVariable Long recordId) {
		String token = authorization.replace("Bearer ", "");
		recordService.markAsRead(token, recordId);
		return Result.success();
	}

	@Operation(summary = "批量标记为已读", description = "批量标记记录为已读")
	@PostMapping("/batch-mark-read")
	public Result<?> batchMarkAsRead(
			@RequestHeader("Authorization") String authorization,
			@RequestBody Map<String, Object> params) {
		String token = authorization.replace("Bearer ", "");
		@SuppressWarnings("unchecked")
		List<Object> recordIdsObj = (List<Object>) params.get("recordIds");
		List<Long> recordIds = recordIdsObj.stream()
				.map(obj -> ((Number) obj).longValue())
				.collect(java.util.stream.Collectors.toList());
		recordService.batchMarkAsRead(token, recordIds);
		return Result.success();
	}
}
