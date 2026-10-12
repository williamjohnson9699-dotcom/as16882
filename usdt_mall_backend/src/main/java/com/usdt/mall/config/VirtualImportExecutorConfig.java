package com.usdt.mall.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor;

import java.util.concurrent.ThreadPoolExecutor;

/**
 * 虚拟数据导入使用单独线程，避免占用请求线程。
 */
@Configuration
public class VirtualImportExecutorConfig {

	@Bean(name = "virtualImportExecutor")
	public ThreadPoolTaskExecutor virtualImportExecutor() {
		ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
		executor.setCorePoolSize(1);
		executor.setMaxPoolSize(2);
		executor.setQueueCapacity(100);
		executor.setThreadNamePrefix("virtual-import-");
		executor.setRejectedExecutionHandler(new ThreadPoolExecutor.AbortPolicy());
		executor.initialize();
		return executor;
	}
}
