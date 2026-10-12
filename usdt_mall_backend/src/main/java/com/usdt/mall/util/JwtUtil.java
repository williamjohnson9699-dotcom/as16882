package com.usdt.mall.util;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;

@Component
public class JwtUtil {

	@Value("${jwt-secret}")
	private String secret;

	@Value("${jwt.expiration}")
	private Long expiration;

	private SecretKey getSigningKey() {
		return Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
	}

	public String generateToken(Long userId, String role) {
		Map<String, Object> claims = new HashMap<>();
		claims.put("userId", userId);
		claims.put("role", role);
		return createToken(claims);
	}

	private String createToken(Map<String, Object> claims) {
		Instant now = Instant.now();
		Instant expiryDate = now.plusMillis(expiration);

		return Jwts.builder()
				.setClaims(claims)
				.setIssuedAt(Date.from(now))
				.setExpiration(Date.from(expiryDate))
				.signWith(getSigningKey(), SignatureAlgorithm.HS256)
				.compact();
	}

	public Claims parseToken(String token) {
		return Jwts.parserBuilder()
				.setSigningKey(getSigningKey())
				.build()
				.parseClaimsJws(token)
				.getBody();
	}

	public Long getUserIdFromToken(String token) {
		Claims claims = parseToken(token);
		return claims.get("userId", Long.class);
	}

	public String getRoleFromToken(String token) {
		Claims claims = parseToken(token);
		return claims.get("role", String.class);
	}

	public boolean isTokenExpired(String token) {
		try {
			Claims claims = parseToken(token);
			return claims.getExpiration().before(Date.from(Instant.now()));
		} catch (Exception e) {
			return true;
		}
	}

	public boolean validateToken(String token) {
		try {
			parseToken(token);
			return !isTokenExpired(token);
		} catch (Exception e) {
			return false;
		}
	}
}
