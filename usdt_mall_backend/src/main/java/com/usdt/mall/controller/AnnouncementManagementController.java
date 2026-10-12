package com.usdt.mall.controller;

import com.usdt.mall.common.Result;
import com.usdt.mall.service.AnnouncementManagementService;
import com.usdt.mall.vo.request.AnnouncementSaveReqVO;
import com.usdt.mall.vo.response.AnnouncementInfoRespVO;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Tag(name = "系统公告管理", description = "系统公告管理相关接口")
@RestController
@RequestMapping("/api/v1/announcement-management")
public class AnnouncementManagementController {

	@Autowired
	private AnnouncementManagementService announcementManagementService;

	@Operation(summary = "获取公告列表", description = "获取所有系统公告列表")
	@GetMapping("/list")
	public Result<List<AnnouncementInfoRespVO>> getAnnouncementList() {
		List<AnnouncementInfoRespVO> announcements = announcementManagementService.getAnnouncementList();
		return Result.successWith(announcements);
	}

	@Operation(summary = "保存公告", description = "新增或编辑公告")
	@PostMapping("/save")
	public Result<?> saveAnnouncement(@RequestBody AnnouncementSaveReqVO reqVO) {
		announcementManagementService.saveAnnouncement(reqVO);
		return Result.success();
	}

	@Operation(summary = "删除公告", description = "删除单个公告")
	@DeleteMapping("/{id}")
	public Result<?> deleteAnnouncement(@PathVariable Long id) {
		announcementManagementService.deleteAnnouncement(id);
		return Result.success();
	}

	@Operation(summary = "批量删除公告", description = "批量删除多个公告")
	@PostMapping("/batch-delete")
	public Result<?> batchDeleteAnnouncements(@RequestBody List<Long> ids) {
		announcementManagementService.batchDeleteAnnouncements(ids);
		return Result.success();
	}
}
