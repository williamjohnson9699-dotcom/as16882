package com.usdt.mall.service;

import com.usdt.mall.vo.request.ShopApplicationReqVO;
import com.usdt.mall.vo.response.ShopApplicationRespVO;

import java.util.List;
import java.util.Map;

/**
 * 店铺申请服务接口
 */
public interface ShopApplicationService {
	/**
	 * 提交店铺申请
	 */
	void submitApplication(String token, ShopApplicationReqVO reqVO);

	/**
	 * 获取当前用户的申请状态
	 */
	ShopApplicationRespVO getMyApplication(String token);

	/**
	 * 获取当前用户的所有申请历史
	 */
	List<ShopApplicationRespVO> getMyApplicationHistory(String token);

	/**
	 * 分页查询申请列表
	 */
	Map<String, Object> getApplicationsByPage(String token, String status, String keyword, Integer page, Integer pageSize);

	/**
	 * 审核通过
	 */
	void approveApplication(String token, Long id);

	/**
	 * 审核拒绝
	 */
	void rejectApplication(String token, Long id, String reviewNote);

	/**
	 * 获取待审核数量
	 */
	int getPendingCount(String token);
}
