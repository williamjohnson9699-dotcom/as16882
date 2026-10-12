package com.usdt.mall.controller;

import com.usdt.mall.common.Result;
import com.usdt.mall.service.AppVersionService;
import com.usdt.mall.service.FileService;
import com.usdt.mall.vo.request.AppVersionQueryReqVO;
import com.usdt.mall.vo.request.AppVersionSaveReqVO;
import com.usdt.mall.vo.response.AppVersionRespVO;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.Map;

/**
 * APP版本管理控制器
 */
@Slf4j
@Tag(name = "APP版本管理", description = "APP版本管理相关接口")
@RestController
@RequestMapping("/api/v1/app-version")
public class AppVersionController {

	@Autowired
	private AppVersionService appVersionService;

	@Autowired
	private FileService fileService;

	@Operation(summary = "获取版本列表", description = "分页获取APP版本列表")
	@GetMapping("/list")
	public Result<Map<String, Object>> getVersionList(AppVersionQueryReqVO reqVO) {
		Map<String, Object> result = appVersionService.getVersionList(reqVO);
		return Result.successWith(result);
	}

	@Operation(summary = "上传APP文件", description = "上传APK或IPA文件")
	@PostMapping("/upload")
	public Result<String> uploadAppFile(
			@RequestParam("file") MultipartFile file,
			@RequestParam("platform") String platform) {
		try {
			// 使用平台作为路径前缀（android 或 ios）
			String pathPrefix = "app/" + platform.toLowerCase();
			String fileUrl = fileService.uploadFile(file, pathPrefix);
			return Result.successWith(fileUrl);
		} catch (Exception e) {
			log.error("APP文件上传失败", e);
			return Result.<String>error().newCnMsg("文件上传失败: " + e.getMessage());
		}
	}

	@Operation(summary = "保存版本信息", description = "创建新的APP版本")
	@PostMapping("/save")
	public Result<?> saveVersion(@RequestBody AppVersionSaveReqVO reqVO) {
		try {
			appVersionService.saveVersion(reqVO);
			return Result.success();
		} catch (Exception e) {
			log.error("保存版本信息失败", e);
			return Result.error().newCnMsg("保存失败: " + e.getMessage());
		}
	}

	@Operation(summary = "删除版本", description = "删除指定的APP版本")
	@DeleteMapping("/{id}")
	public Result<?> deleteVersion(@PathVariable Long id) {
		try {
			appVersionService.deleteVersion(id);
			return Result.success();
		} catch (Exception e) {
			log.error("删除版本失败: {}", id, e);
			return Result.error().newCnMsg("删除失败: " + e.getMessage());
		}
	}

	@Operation(summary = "获取最新版本", description = "获取指定平台的最新版本")
	@GetMapping("/latest")
	public Result<AppVersionRespVO> getLatestVersion(@RequestParam("platform") String platform) {
		try {
			AppVersionRespVO version = appVersionService.getLatestVersion(platform);
			if (version == null) {
				return Result.<AppVersionRespVO>error().newCnMsg("未找到该平台的版本信息");
			}
			return Result.successWith(version);
		} catch (Exception e) {
			log.error("获取最新版本失败: {}", platform, e);
			return Result.<AppVersionRespVO>error().newCnMsg("获取失败: " + e.getMessage());
		}
	}
}
