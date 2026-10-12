package com.usdt.mall.controller;

import com.usdt.mall.common.Result;
import com.usdt.mall.common.ResultCode;
import com.usdt.mall.exception.CustomException;
import com.usdt.mall.service.FileService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

/**
 * 文件管理控制器
 */
@Slf4j
@Tag(name = "文件管理", description = "文件上传下载相关接口")
@RestController
@RequestMapping("/api/v1/file")
public class FileController {

	@Autowired
	private FileService fileService;

	@Operation(summary = "上传文件")
	@PostMapping("/upload")
	public Result<String> uploadFile(
			@RequestParam("file") MultipartFile file,
			@RequestParam(value = "pathPrefix", required = false, defaultValue = "avatar") String pathPrefix) {
		try {
			String filename = fileService.uploadFile(file, pathPrefix);
			return Result.successWith(filename);
		} catch (Exception e) {
			log.error("文件上传失败", e);
			throw new CustomException(ResultCode.PARAMETER_ERROR, e.getMessage());
		}
	}

	@Operation(summary = "下载文件")
	@GetMapping("/download/**")
	public void downloadFile(HttpServletRequest request, HttpServletResponse response) {
		try {
			// 从请求路径中提取文件名（支持带路径的文件名）
			String requestURI = request.getRequestURI();
			String filename = requestURI.substring(requestURI.indexOf("/download/") + 10);

			fileService.downloadFile(filename, response);
		} catch (Exception e) {
			log.error("文件下载失败", e);
			throw new CustomException(ResultCode.PARAMETER_ERROR, e.getMessage());
		}
	}

	@Operation(summary = "删除文件")
	@DeleteMapping("/{filename}")
	public Result<?> deleteFile(@PathVariable String filename) {
		try {
			fileService.deleteFile(filename);
			return Result.success();
		} catch (Exception e) {
			log.error("文件删除失败: {}", filename, e);
			throw new CustomException(ResultCode.PARAMETER_ERROR, e.getMessage());
		}
	}

	@Operation(summary = "获取文件预览URL")
	@GetMapping("/preview/{filename}")
	public Result<String> getPreviewUrl(@PathVariable String filename) {
		try {
			String url = fileService.getPreviewUrl(filename);
			return Result.successWith(url);
		} catch (Exception e) {
			log.error("获取文件预览URL失败: {}", filename, e);
			throw new CustomException(ResultCode.PARAMETER_ERROR, e.getMessage());
		}
	}
}
