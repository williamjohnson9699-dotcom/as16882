package com.usdt.mall.service.impl;

import com.usdt.mall.common.ResultCode;
import com.usdt.mall.exception.CustomException;
import com.usdt.mall.service.FileService;
import com.usdt.mall.util.MinioUtil;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import javax.annotation.Resource;
import javax.servlet.ServletOutputStream;
import javax.servlet.http.HttpServletResponse;
import java.io.InputStream;
import java.util.Arrays;
import java.util.List;
import java.util.UUID;

/**
 * 文件服务实现类
 */
@Slf4j
@Service
public class FileServiceImpl implements FileService {

	@Resource
	private MinioUtil minioUtil;

	@Value("${minio.bucket}")
	private String bucket;

	@Value("${file.max-size:10485760}")
	private Long maxFileSize; // 默认10MB

	@Value("${file.allowed-types:jpg,jpeg,png,gif,pdf,doc,docx}")
	private String allowedTypes;

	/**
	 * 验证文件
	 */
	private void validateFile(MultipartFile file) {
		// 检查文件是否为空
		if (file == null || file.isEmpty()) {
			throw new CustomException(ResultCode.FILE_EMPTY);
		}

		// 检查文件大小
		if (file.getSize() > maxFileSize) {
			throw new CustomException(ResultCode.FILE_TOO_LARGE);
		}

		// 检查文件类型
		String originalFilename = file.getOriginalFilename();
		if (originalFilename == null || !originalFilename.contains(".")) {
			throw new CustomException(ResultCode.FILE_TYPE_NOT_ALLOWED);
		}

		String extension = originalFilename.substring(originalFilename.lastIndexOf(".") + 1).toLowerCase();
		List<String> allowedTypeList = Arrays.asList(allowedTypes.split(","));
		if (!allowedTypeList.contains(extension)) {
			throw new CustomException(ResultCode.FILE_TYPE_NOT_ALLOWED);
		}
	}

	@Override
	public String uploadFile(MultipartFile file) throws Exception {
		return uploadFile(file, "avatar");
	}

	@Override
	public String uploadFile(MultipartFile file, String pathPrefix) throws Exception {
		// 验证文件
		validateFile(file);

		// 生成唯一文件名
		String originalFilename = file.getOriginalFilename();
		String extension = originalFilename.substring(originalFilename.lastIndexOf("."));
		String filename = pathPrefix + "/" + UUID.randomUUID().toString().replace("-", "") + extension;

		// 确保bucket存在
		minioUtil.createBucket(bucket);

		// 上传文件
		minioUtil.uploadFile(file.getInputStream(), bucket, filename);

		log.info("文件上传成功: {}", filename);
		return filename;
	}

	@Override
	public void downloadFile(String filename, HttpServletResponse response) throws Exception {
		if (filename == null || filename.isEmpty()) {
			throw new CustomException(ResultCode.FILE_NOT_FOUND);
		}

		try (InputStream inputStream = minioUtil.downloadFile(bucket, filename);
			 ServletOutputStream outputStream = response.getOutputStream()) {

			// 根据文件扩展名设置Content-Type
			String contentType = getContentType(filename);
			response.setContentType(contentType);

			// 如果是图片，设置为inline显示；否则设置为attachment下载
			if (contentType.startsWith("image/")) {
				response.setHeader("Content-Disposition", "inline; filename=\"" + filename + "\"");
			} else {
				response.setHeader("Content-Disposition", "attachment; filename=\"" + filename + "\"");
			}

			// 流式传输文件
			byte[] buffer = new byte[8192];
			int bytesRead;
			while ((bytesRead = inputStream.read(buffer)) != -1) {
				outputStream.write(buffer, 0, bytesRead);
			}
			outputStream.flush();

			log.info("文件下载成功: {}", filename);
		} catch (Exception e) {
			log.error("文件下载失败: {}", filename, e);
			throw new CustomException(ResultCode.FILE_DOWNLOAD_FAILED);
		}
	}

	/**
	 * 根据文件扩展名获取Content-Type
	 */
	private String getContentType(String filename) {
		String extension = "";
		int lastDotIndex = filename.lastIndexOf(".");
		if (lastDotIndex > 0) {
			extension = filename.substring(lastDotIndex + 1).toLowerCase();
		}

		switch (extension) {
			case "jpg":
			case "jpeg":
				return "image/jpeg";
			case "png":
				return "image/png";
			case "gif":
				return "image/gif";
			case "bmp":
				return "image/bmp";
			case "webp":
				return "image/webp";
			case "svg":
				return "image/svg+xml";
			case "pdf":
				return "application/pdf";
			case "doc":
				return "application/msword";
			case "docx":
				return "application/vnd.openxmlformats-officedocument.wordprocessingml.document";
			default:
				return "application/octet-stream";
		}
	}

	@Override
	public void deleteFile(String filename) throws Exception {
		if (filename == null || filename.isEmpty()) {
			throw new CustomException(ResultCode.FILE_NOT_FOUND);
		}

		minioUtil.deleteObject(bucket, filename);
		log.info("文件删除成功: {}", filename);
	}

	@Override
	public String getPreviewUrl(String filename) throws Exception {
		if (filename == null || filename.isEmpty()) {
			throw new CustomException(ResultCode.FILE_NOT_FOUND);
		}

		return minioUtil.getPreviewFileUrl(bucket, filename);
	}
}
