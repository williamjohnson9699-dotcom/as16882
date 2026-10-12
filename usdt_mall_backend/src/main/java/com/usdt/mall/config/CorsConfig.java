package com.usdt.mall.config;

import org.springframework.boot.web.servlet.FilterRegistrationBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.Ordered;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;
import org.springframework.web.filter.CorsFilter;

/**
 * 跨域配置
 */
@Configuration
public class CorsConfig {

	@Bean
	public FilterRegistrationBean<CorsFilter> corsFilter() {
		CorsConfiguration config = new CorsConfiguration();

		// 允许所有域名跨域（使用 OriginPattern 支持通配符）
		config.addAllowedOriginPattern("*");

		// 允许所有请求头
		config.addAllowedHeader("*");

		// 允许所有请求方法
		config.addAllowedMethod("*");

		// 不允许携带凭证（与通配符 * 冲突）
		config.setAllowCredentials(false);

		// 暴露响应头（让前端可以访问这些响应头）
		config.addExposedHeader("*");

		// 预检请求的有效期，单位为秒
		config.setMaxAge(3600L);

		UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
		source.registerCorsConfiguration("/**", config);

		FilterRegistrationBean<CorsFilter> bean = new FilterRegistrationBean<>(new CorsFilter(source));
		bean.setOrder(Ordered.HIGHEST_PRECEDENCE);
		return bean;
	}
}
