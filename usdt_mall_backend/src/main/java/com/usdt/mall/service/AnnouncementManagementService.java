package com.usdt.mall.service;

import com.usdt.mall.vo.request.AnnouncementSaveReqVO;
import com.usdt.mall.vo.response.AnnouncementInfoRespVO;

import java.util.List;

/**
 * 系统公告管理服务接口
 */
public interface AnnouncementManagementService {
	/**
	 * 获取公告列表
	 */
	List<AnnouncementInfoRespVO> getAnnouncementList();

	/**
	 * 保存公告（新增或编辑）
	 */
	void saveAnnouncement(AnnouncementSaveReqVO reqVO);

	/**
	 * 删除公告
	 */
	void deleteAnnouncement(Long id);

	/**
	 * 批量删除公告
	 */
	void batchDeleteAnnouncements(List<Long> ids);
}
