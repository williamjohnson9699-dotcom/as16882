package com.usdt.mall.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.UpdateWrapper;
import com.usdt.mall.entity.Address;
import com.usdt.mall.mapper.AddressMapper;
import com.usdt.mall.service.AddressManagementService;
import com.usdt.mall.util.DateTimeUtil;
import com.usdt.mall.util.JwtUtil;
import com.usdt.mall.vo.request.AddressSaveReqVO;
import com.usdt.mall.vo.response.AddressInfoRespVO;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

/**
 * 地址管理服务实现�?
 */
@Slf4j
@Service
public class AddressManagementServiceImpl implements AddressManagementService {

	@Autowired
	private AddressMapper addressMapper;

	@Autowired
	private JwtUtil jwtUtil;

	@Override
	public List<AddressInfoRespVO> getUserAddresses(String token) {
		Long userId = jwtUtil.getUserIdFromToken(token);

		QueryWrapper<Address> queryWrapper = new QueryWrapper<>();
		queryWrapper.eq("user_id", userId);
		queryWrapper.orderByDesc("is_default");
		queryWrapper.orderByDesc("create_time");

		List<Address> addresses = addressMapper.selectList(queryWrapper);

		return addresses.stream()
				.map(this::convertToRespVO)
				.collect(Collectors.toList());
	}

	@Override
	public List<AddressInfoRespVO> getUserAddressesByUserId(Long userId) {
		QueryWrapper<Address> queryWrapper = new QueryWrapper<>();
		queryWrapper.eq("user_id", userId);
		queryWrapper.orderByDesc("is_default");
		queryWrapper.orderByDesc("create_time");

		List<Address> addresses = addressMapper.selectList(queryWrapper);

		return addresses.stream()
				.map(this::convertToRespVO)
				.collect(Collectors.toList());
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void saveAddress(String token, AddressSaveReqVO reqVO) {
		Long userId = jwtUtil.getUserIdFromToken(token);

		Address address = new Address();
		address.setUserId(userId);
		address.setName(reqVO.getName());
		address.setPhone(reqVO.getPhone());
		address.setAddress(reqVO.getAddress());
		address.setIsDefault(reqVO.getIsDefault() ? 1 : 0);

		if (reqVO.getId() != null) {
			// 编辑地址
			address.setId(reqVO.getId());
			address.setUpdateTime(DateTimeUtil.nowUtc());
			addressMapper.updateById(address);
		} else {
			// 新增地址
			address.setCreateTime(DateTimeUtil.nowUtc());
			address.setUpdateTime(DateTimeUtil.nowUtc());
			addressMapper.insert(address);
		}

		// 如果设置为默认地址，需要取消其他地址的默认状�?
		if (reqVO.getIsDefault()) {
			UpdateWrapper<Address> updateWrapper = new UpdateWrapper<>();
			updateWrapper.eq("user_id", userId);
			updateWrapper.ne("id", address.getId());
			updateWrapper.set("is_default", 0);
			addressMapper.update(null, updateWrapper);
		}
	}

	@Override
	public void deleteAddress(String token, Long id) {
		Long userId = jwtUtil.getUserIdFromToken(token);

		// 验证地址是否属于当前用户
		QueryWrapper<Address> queryWrapper = new QueryWrapper<>();
		queryWrapper.eq("id", id);
		queryWrapper.eq("user_id", userId);
		Address address = addressMapper.selectOne(queryWrapper);

		if (address != null) {
			addressMapper.deleteById(id);
		}
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void batchDeleteAddresses(String token, List<Long> ids) {
		Long userId = jwtUtil.getUserIdFromToken(token);

		// 只删除属于当前用户的地址
		QueryWrapper<Address> queryWrapper = new QueryWrapper<>();
		queryWrapper.in("id", ids);
		queryWrapper.eq("user_id", userId);

		addressMapper.delete(queryWrapper);
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void setDefaultAddress(String token, Long id) {
		Long userId = jwtUtil.getUserIdFromToken(token);

		// 取消所有默认地址
		UpdateWrapper<Address> updateWrapper = new UpdateWrapper<>();
		updateWrapper.eq("user_id", userId);
		updateWrapper.set("is_default", 0);
		addressMapper.update(null, updateWrapper);

		// 设置新的默认地址
		Address address = new Address();
		address.setId(id);
		address.setIsDefault(1);
		address.setUpdateTime(DateTimeUtil.nowUtc());
		addressMapper.updateById(address);
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void saveAddressForUser(Long userId, AddressSaveReqVO reqVO) {
		Address address = new Address();
		address.setUserId(userId);
		address.setName(reqVO.getName());
		address.setPhone(reqVO.getPhone());
		address.setAddress(reqVO.getAddress());
		address.setIsDefault(reqVO.getIsDefault() ? 1 : 0);

		if (reqVO.getId() != null) {
			// 编辑地址
			address.setId(reqVO.getId());
			address.setUpdateTime(DateTimeUtil.nowUtc());
			addressMapper.updateById(address);
		} else {
			// 新增地址
			address.setCreateTime(DateTimeUtil.nowUtc());
			address.setUpdateTime(DateTimeUtil.nowUtc());
			addressMapper.insert(address);
		}

		// 如果设置为默认地址，需要取消其他地址的默认状�?
		if (reqVO.getIsDefault()) {
			UpdateWrapper<Address> updateWrapper = new UpdateWrapper<>();
			updateWrapper.eq("user_id", userId);
			updateWrapper.ne("id", address.getId());
			updateWrapper.set("is_default", 0);
			addressMapper.update(null, updateWrapper);
		}
	}

	/**
	 * 转换为响应VO
	 */
	private AddressInfoRespVO convertToRespVO(Address address) {
		AddressInfoRespVO vo = new AddressInfoRespVO();
		vo.setId(address.getId());
		vo.setName(address.getName());
		vo.setPhone(address.getPhone());
		vo.setAddress(address.getAddress());
		vo.setIsDefault(address.getIsDefault() == 1);
		vo.setCreateTime(address.getCreateTime());
		return vo;
	}
}
