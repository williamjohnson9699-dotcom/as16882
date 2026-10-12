package com.usdt.mall.controller;

import com.usdt.mall.common.Result;
import com.usdt.mall.service.AddressManagementService;
import com.usdt.mall.vo.request.AddressSaveReqVO;
import com.usdt.mall.vo.response.AddressInfoRespVO;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Tag(name = "地址管理", description = "地址管理相关接口")
@RestController
@RequestMapping("/api/v1/address-management")
public class AddressManagementController {

	@Autowired
	private AddressManagementService addressManagementService;

	@Operation(summary = "获取地址列表", description = "获取当前用户的地址列表")
	@GetMapping("/list")
	public Result<List<AddressInfoRespVO>> getAddressList(@RequestHeader("Authorization") String authorization) {
		String token = authorization.replace("Bearer ", "");
		List<AddressInfoRespVO> addresses = addressManagementService.getUserAddresses(token);
		return Result.successWith(addresses);
	}

	@Operation(summary = "获取指定用户的地址列表", description = "根据用户ID获取地址列表（用于代下订单）")
	@GetMapping("/user/{userId}/addresses")
	public Result<List<AddressInfoRespVO>> getUserAddressesByUserId(@PathVariable Long userId) {
		List<AddressInfoRespVO> addresses = addressManagementService.getUserAddressesByUserId(userId);
		return Result.successWith(addresses);
	}

	@Operation(summary = "保存地址", description = "新增或编辑地址")
	@PostMapping("/save")
	public Result<?> saveAddress(
			@RequestHeader("Authorization") String authorization,
			@RequestBody AddressSaveReqVO reqVO) {
		String token = authorization.replace("Bearer ", "");
		addressManagementService.saveAddress(token, reqVO);
		return Result.success();
	}

	@Operation(summary = "删除地址", description = "删除单个地址")
	@DeleteMapping("/{id}")
	public Result<?> deleteAddress(
			@RequestHeader("Authorization") String authorization,
			@PathVariable Long id) {
		String token = authorization.replace("Bearer ", "");
		addressManagementService.deleteAddress(token, id);
		return Result.success();
	}

	@Operation(summary = "批量删除地址", description = "批量删除多个地址")
	@PostMapping("/batch-delete")
	public Result<?> batchDeleteAddresses(
			@RequestHeader("Authorization") String authorization,
			@RequestBody List<Long> ids) {
		String token = authorization.replace("Bearer ", "");
		addressManagementService.batchDeleteAddresses(token, ids);
		return Result.success();
	}

	@Operation(summary = "设置默认地址", description = "设置某个地址为默认地址")
	@PutMapping("/set-default/{id}")
	public Result<?> setDefaultAddress(
			@RequestHeader("Authorization") String authorization,
			@PathVariable Long id) {
		String token = authorization.replace("Bearer ", "");
		addressManagementService.setDefaultAddress(token, id);
		return Result.success();
	}

	@Operation(summary = "为指定用户保存地址", description = "管理员/客服为指定用户新增或编辑地址")
	@PostMapping("/user/{userId}/save")
	public Result<?> saveAddressForUser(
			@PathVariable Long userId,
			@RequestBody AddressSaveReqVO reqVO) {
		addressManagementService.saveAddressForUser(userId, reqVO);
		return Result.success();
	}
}
