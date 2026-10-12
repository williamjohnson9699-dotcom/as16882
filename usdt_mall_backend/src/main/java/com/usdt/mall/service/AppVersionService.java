package com.usdt.mall.service;

import com.usdt.mall.vo.request.AppVersionQueryReqVO;
import com.usdt.mall.vo.request.AppVersionSaveReqVO;
import com.usdt.mall.vo.response.AppVersionRespVO;

import java.util.Map;

/**
 * APP版本管理服务接口
 */
public interface AppVersionService {
	/**
	 * 获取版本列表（分页）
	 */
	Map<String, Object> getVersionList(AppVersionQueryReqVO reqVO);

	/**
	 * 保存版本信息
	 */
	void saveVersion(AppVersionSaveReqVO reqVO);

	/**
	 * 删除版本
	 */
	void deleteVersion(Long id);

	/**
	 * 获取最新版本
	 */
	AppVersionRespVO getLatestVersion(String platform);
}
