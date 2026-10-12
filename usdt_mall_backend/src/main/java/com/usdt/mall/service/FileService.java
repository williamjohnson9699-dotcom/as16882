package com.usdt.mall.service;

import org.springframework.web.multipart.MultipartFile;

import javax.servlet.http.HttpServletResponse;

/**
 * 文件服务接口
 */
public interface FileService {

	/**
	 * 上传文件
	 *
	 * @param file 文件
	 * @return 文件URL
	 */
	String uploadFile(MultipartFile file) throws Exception;

	/**
	 * 上传文件到指定路径
	 *
	 * @param file       文件
	 * @param pathPrefix 路径前缀（如：avatar, proof_image）
	 * @return 文件URL
	 */
	String uploadFile(MultipartFile file, String pathPrefix) throws Exception;

	/**
	 * 下载文件
	 *
	 * @param filename 文件名
	 * @param response HTTP响应
	 */
	void downloadFile(String filename, HttpServletResponse response) throws Exception;

	/**
	 * 删除文件
	 *
	 * @param filename 文件名
	 */
	void deleteFile(String filename) throws Exception;

	/**
	 * 获取文件预览URL
	 *
	 * @param filename 文件名
	 * @return 预览URL
	 */
	String getPreviewUrl(String filename) throws Exception;
}
