package com.usdt.mall.util;

import io.minio.*;
import io.minio.messages.Bucket;
import io.minio.messages.Item;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import javax.annotation.Resource;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.List;

/**
 * MinIO工具类
 */
@Slf4j
@Component
public class MinioUtil {

	@Resource
	private MinioClient minioClient;

	/**
	 * 创建bucket
	 */
	public void createBucket(String bucket) throws Exception {
		boolean exists = minioClient.bucketExists(BucketExistsArgs.builder().bucket(bucket).build());
		if (!exists) {
			minioClient.makeBucket(MakeBucketArgs.builder().bucket(bucket).build());
		}
	}

	/**
	 * 上传文件
	 */
	public void uploadFile(InputStream inputStream, String bucket, String objectName) throws Exception {
		minioClient.putObject(
				PutObjectArgs.builder().bucket(bucket).object(objectName)
						.stream(inputStream, -1, 5242889L).build());
	}

	/**
	 * 下载文件
	 */
	public InputStream downloadFile(String bucket, String objectName) throws Exception {
		return minioClient.getObject(GetObjectArgs.builder().bucket(bucket).object(objectName).build());
	}

	/**
	 * 删除文件
	 */
	public void deleteObject(String bucket, String objectName) throws Exception {
		minioClient.removeObject(RemoveObjectArgs.builder().bucket(bucket).object(objectName).build());
	}

	/**
	 * 获取文件预览URL
	 */
	public String getPreviewFileUrl(String bucket, String objectName) throws Exception {
		return minioClient.getPresignedObjectUrl(
				GetPresignedObjectUrlArgs.builder()
						.method(io.minio.http.Method.GET)
						.bucket(bucket)
						.object(objectName)
						.expiry(60 * 60 * 24 * 7) // 7天有效期
						.build());
	}

	/**
	 * 获取所有bucket
	 */
	public List<String> getAllBucket() throws Exception {
		List<Bucket> buckets = minioClient.listBuckets();
		List<String> bucketNames = new ArrayList<>();
		for (Bucket bucket : buckets) {
			bucketNames.add(bucket.name());
		}
		return bucketNames;
	}

	/**
	 * 获取bucket中的所有文件
	 */
	public List<String> getAllFile(String bucket) throws Exception {
		List<String> fileNames = new ArrayList<>();
		Iterable<Result<Item>> results = minioClient.listObjects(
				ListObjectsArgs.builder().bucket(bucket).build());
		for (Result<Item> result : results) {
			Item item = result.get();
			fileNames.add(item.objectName());
		}
		return fileNames;
	}
}
