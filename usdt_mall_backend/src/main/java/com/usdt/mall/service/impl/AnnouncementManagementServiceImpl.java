package com.usdt.mall.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.usdt.mall.entity.Announcement;
import com.usdt.mall.mapper.AnnouncementMapper;
import com.usdt.mall.service.AnnouncementManagementService;
import com.usdt.mall.util.DateTimeUtil;
import com.usdt.mall.vo.request.AnnouncementSaveReqVO;
import com.usdt.mall.vo.response.AnnouncementInfoRespVO;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

/**
 * 系统公告管理服务实现�?
 */
@Slf4j
@Service
public class AnnouncementManagementServiceImpl implements AnnouncementManagementService {

	@Autowired
	private AnnouncementMapper announcementMapper;

	@Override
	public List<AnnouncementInfoRespVO> getAnnouncementList() {
		QueryWrapper<Announcement> queryWrapper = new QueryWrapper<>();
		queryWrapper.orderByDesc("create_time");

		List<Announcement> announcements = announcementMapper.selectList(queryWrapper);

		return announcements.stream()
				.map(this::convertToRespVO)
				.collect(Collectors.toList());
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void saveAnnouncement(AnnouncementSaveReqVO reqVO) {
		Announcement announcement = new Announcement();
		announcement.setTitle(reqVO.getTitle());
		announcement.setContent(reqVO.getContent());

		if (reqVO.getId() != null) {
			// 编辑公告
			announcement.setId(reqVO.getId());
			announcement.setUpdateTime(DateTimeUtil.nowUtc());
			announcementMapper.updateById(announcement);
		} else {
			// 新增公告
			announcement.setCreateTime(DateTimeUtil.nowUtc());
			announcement.setUpdateTime(DateTimeUtil.nowUtc());
			announcementMapper.insert(announcement);
		}
	}

	@Override
	public void deleteAnnouncement(Long id) {
		announcementMapper.deleteById(id);
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void batchDeleteAnnouncements(List<Long> ids) {
		announcementMapper.deleteBatchIds(ids);
	}

	/**
	 * 转换为响应VO
	 */
	private AnnouncementInfoRespVO convertToRespVO(Announcement announcement) {
		AnnouncementInfoRespVO vo = new AnnouncementInfoRespVO();
		vo.setId(announcement.getId());
		vo.setTitle(announcement.getTitle());
		vo.setContent(announcement.getContent());
		vo.setCreateTime(announcement.getCreateTime());
		return vo;
	}
}
