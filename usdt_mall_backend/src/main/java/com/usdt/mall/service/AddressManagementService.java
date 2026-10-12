package com.usdt.mall.service;

import com.usdt.mall.vo.request.AddressSaveReqVO;
import com.usdt.mall.vo.response.AddressInfoRespVO;

import java.util.List;

/**
 * 地址管理服务接口
 */
public interface AddressManagementService {
	/**
	 * 获取当前用户的地址列表
	 */
	List<AddressInfoRespVO> getUserAddresses(String token);

	/**
	 * 根据用户ID获取地址列表
	 */
	List<AddressInfoRespVO> getUserAddressesByUserId(Long userId);

	/**
	 * 保存地址（新增或编辑）
	 */
	void saveAddress(String token, AddressSaveReqVO reqVO);

	/**
	 * 删除地址
	 */
	void deleteAddress(String token, Long id);

	/**
	 * 批量删除地址
	 */
	void batchDeleteAddresses(String token, List<Long> ids);

	/**
	 * 设置默认地址
	 */
	void setDefaultAddress(String token, Long id);

	/**
	 * 为指定用户保存地址（管理员/客服使用）
	 */
	void saveAddressForUser(Long userId, AddressSaveReqVO reqVO);
}
