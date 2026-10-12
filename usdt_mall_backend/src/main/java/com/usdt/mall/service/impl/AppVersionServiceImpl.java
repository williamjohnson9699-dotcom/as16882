package com.usdt.mall.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.usdt.mall.entity.AppVersion;
import com.usdt.mall.mapper.AppVersionMapper;
import com.usdt.mall.service.AppVersionService;
import com.usdt.mall.util.DateTimeUtil;
import com.usdt.mall.vo.request.AppVersionQueryReqVO;
import com.usdt.mall.vo.request.AppVersionSaveReqVO;
import com.usdt.mall.vo.response.AppVersionRespVO;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.BeanUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * APP版本管理服务实现�?
 */
@Slf4j
@Service
public class AppVersionServiceImpl implements AppVersionService {

	@Autowired
	private AppVersionMapper appVersionMapper;

	@Override
	public Map<String, Object> getVersionList(AppVersionQueryReqVO reqVO) {
		QueryWrapper<AppVersion> queryWrapper = new QueryWrapper<>();

		// 平台筛�?
		if (reqVO.getPlatform() != null && !reqVO.getPlatform().isEmpty()) {
			queryWrapper.eq("platform", reqVO.getPlatform());
		}

		// 按创建时间倒序
		queryWrapper.orderByDesc("create_time");

		// 分页查询
		Page<AppVersion> page = new Page<>(reqVO.getPage(), reqVO.getPageSize());
		Page<AppVersion> resultPage = appVersionMapper.selectPage(page, queryWrapper);

		// 转换为响应VO
		List<AppVersionRespVO> records = resultPage.getRecords().stream()
				.map(this::convertToRespVO)
				.collect(Collectors.toList());

		Map<String, Object> result = new HashMap<>();
		result.put("records", records);
		result.put("total", resultPage.getTotal());
		result.put("page", resultPage.getCurrent());
		result.put("pageSize", resultPage.getSize());

		return result;
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void saveVersion(AppVersionSaveReqVO reqVO) {
		AppVersion appVersion = new AppVersion();
		appVersion.setPlatform(reqVO.getPlatform());
		appVersion.setVersionCode(reqVO.getVersionCode());
		appVersion.setVersionName(reqVO.getVersionName());
		appVersion.setDownloadUrl(reqVO.getDownloadUrl());
		appVersion.setUpdateDesc(reqVO.getUpdateDesc());
		appVersion.setIsForceUpdate(reqVO.getIsForceUpdate() != null ? reqVO.getIsForceUpdate() : 0);
		appVersion.setStatus(reqVO.getStatus() != null ? reqVO.getStatus() : 1);
		appVersion.setCreateTime(DateTimeUtil.nowUtc());
		appVersion.setUpdateTime(DateTimeUtil.nowUtc());

		appVersionMapper.insert(appVersion);
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void deleteVersion(Long id) {
		appVersionMapper.deleteById(id);
	}

	@Override
	public AppVersionRespVO getLatestVersion(String platform) {
		QueryWrapper<AppVersion> queryWrapper = new QueryWrapper<>();
		queryWrapper.eq("platform", platform);
		queryWrapper.eq("status", 1);
		queryWrapper.orderByDesc("version_code");
		queryWrapper.last("LIMIT 1");

		AppVersion appVersion = appVersionMapper.selectOne(queryWrapper);

		if (appVersion == null) {
			return null;
		}

		return convertToRespVO(appVersion);
	}

	/**
	 * 转换为响应VO
	 */
	private AppVersionRespVO convertToRespVO(AppVersion appVersion) {
		AppVersionRespVO vo = new AppVersionRespVO();
		BeanUtils.copyProperties(appVersion, vo);
		return vo;
	}
}
