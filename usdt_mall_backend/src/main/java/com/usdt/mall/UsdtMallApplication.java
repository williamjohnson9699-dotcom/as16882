package com.usdt.mall;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * USDT Mall Backend Application
 *
 * @author USDT Mall Team
 * @since 2024
 */
@SpringBootApplication
public class UsdtMallApplication {

	public static void main(String[] args) {
		SpringApplication.run(UsdtMallApplication.class, args);
		System.out.println("=================================");
		System.out.println("USDT Mall Backend Started Successfully!");
		System.out.println("Swagger UI: http://localhost:8080/swagger-ui.html");
		System.out.println("=================================");
	}
}
