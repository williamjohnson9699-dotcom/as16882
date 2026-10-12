package com.usdt.mall.controller;

import com.usdt.mall.common.Result;
import com.usdt.mall.common.ResultCode;
import com.usdt.mall.entity.User;
import com.usdt.mall.mapper.UserMapper;
import com.usdt.mall.service.VirtualDataService;
import com.usdt.mall.util.JwtUtil;
import com.usdt.mall.vo.request.VirtualOrderGenerateReqVO;
import com.usdt.mall.vo.request.VirtualProductGenerateReqVO;
import com.usdt.mall.vo.request.VirtualShopGenerateReqVO;
import com.usdt.mall.vo.response.VirtualImportTaskPageRespVO;
import com.usdt.mall.vo.response.VirtualImportTaskRespVO;
import com.usdt.mall.vo.response.VirtualOrderSubmitRespVO;
import com.usdt.mall.vo.response.VirtualProductSubmitRespVO;
import com.usdt.mall.vo.response.VirtualShopOptionPageRespVO;
import com.usdt.mall.vo.response.VirtualShopPreviewRespVO;
import com.usdt.mall.vo.response.VirtualShopSubmitRespVO;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import javax.annotation.Resource;
import javax.servlet.http.HttpServletRequest;

/**
 * 虚拟数据任务。只允许管理员，客服不可调用。
 */
@RestController
@RequestMapping("/api/v1/virtual-data")
public class VirtualDataController {

	@Resource
	private VirtualDataService virtualDataService;

	@Resource
	private UserMapper userMapper;

	@Resource
	private JwtUtil jwtUtil;

	@GetMapping("/tasks")
	public Result<VirtualImportTaskPageRespVO> listTasks(
			@RequestParam(defaultValue = "1") Integer page,
			@RequestParam(defaultValue = "10") Integer pageSize,
			HttpServletRequest request) {
		Long adminUserId = requireAdmin(request);
		if (adminUserId == null) {
			return currentDenied(request);
		}
		return Result.successWith(virtualDataService.listTasks(adminUserId, page, pageSize));
	}

	@GetMapping("/shops")
	public Result<VirtualShopOptionPageRespVO> listShops(
			@RequestParam(required = false) String keyword,
			@RequestParam(defaultValue = "1") Integer page,
			@RequestParam(defaultValue = "20") Integer pageSize,
			HttpServletRequest request) {
		Long adminUserId = requireAdmin(request);
		if (adminUserId == null) {
			return currentDenied(request);
		}
		return Result.successWith(virtualDataService.listShops(keyword, page, pageSize));
	}

	@PostMapping("/shops/preview")
	public Result<VirtualShopPreviewRespVO> previewShops(@RequestBody VirtualShopGenerateReqVO req,
			HttpServletRequest request) {
		Long adminUserId = requireAdmin(request);
		if (adminUserId == null) {
			return currentDenied(request);
		}
		String error = virtualDataService.validateShopGenerate(req);
		if (error != null) {
			return Result.<VirtualShopPreviewRespVO>of(ResultCode.FAIL).newCnMsg(error).newMsg("invalid request");
		}
		try {
			return Result.successWith(virtualDataService.previewShops(req));
		} catch (IllegalArgumentException e) {
			return Result.<VirtualShopPreviewRespVO>of(ResultCode.FAIL).newCnMsg(e.getMessage()).newMsg("invalid request");
		}
	}

	@PostMapping("/shops")
	public Result<VirtualShopSubmitRespVO> submitShops(@RequestBody VirtualShopGenerateReqVO req,
			HttpServletRequest request) {
		Long adminUserId = requireAdmin(request);
		if (adminUserId == null) {
			return currentDenied(request);
		}
		String error = virtualDataService.validateShopGenerate(req);
		if (error != null) {
			return Result.<VirtualShopSubmitRespVO>of(ResultCode.FAIL).newCnMsg(error).newMsg("invalid request");
		}
		try {
			return Result.successWith(virtualDataService.submitShops(adminUserId, req));
		} catch (IllegalArgumentException e) {
			return Result.<VirtualShopSubmitRespVO>of(ResultCode.FAIL).newCnMsg(e.getMessage()).newMsg("invalid request");
		}
	}

	@PostMapping("/orders")
	public Result<VirtualOrderSubmitRespVO> submitOrders(@RequestBody VirtualOrderGenerateReqVO req,
			HttpServletRequest request) {
		Long adminUserId = requireAdmin(request);
		if (adminUserId == null) {
			return currentDenied(request);
		}
		String error = virtualDataService.validateOrderGenerate(req);
		if (error != null) {
			return Result.<VirtualOrderSubmitRespVO>of(ResultCode.FAIL).newCnMsg(error).newMsg("invalid request");
		}
		try {
			return Result.successWith(virtualDataService.submitOrders(adminUserId, req));
		} catch (IllegalArgumentException e) {
			return Result.<VirtualOrderSubmitRespVO>of(ResultCode.FAIL).newCnMsg(e.getMessage()).newMsg("invalid request");
		}
	}

	@PostMapping("/products")
	public Result<VirtualProductSubmitRespVO> submitProducts(@RequestBody VirtualProductGenerateReqVO req,
			HttpServletRequest request) {
		Long adminUserId = requireAdmin(request);
		if (adminUserId == null) {
			return currentDenied(request);
		}
		String error = virtualDataService.validateProductGenerate(req);
		if (error != null) {
			return Result.<VirtualProductSubmitRespVO>of(ResultCode.FAIL).newCnMsg(error).newMsg("invalid request");
		}
		try {
			return Result.successWith(virtualDataService.submitProducts(adminUserId, req));
		} catch (IllegalArgumentException e) {
			return Result.<VirtualProductSubmitRespVO>of(ResultCode.FAIL).newCnMsg(e.getMessage()).newMsg("invalid request");
		}
	}

	@GetMapping("/tasks/{taskId}")
	public Result<VirtualImportTaskRespVO> getTask(@PathVariable Long taskId, HttpServletRequest request) {
		Long adminUserId = requireAdmin(request);
		if (adminUserId == null) {
			return currentDenied(request);
		}
		VirtualImportTaskRespVO task = virtualDataService.getTask(adminUserId, taskId);
		if (task == null) {
			return Result.<VirtualImportTaskRespVO>of(ResultCode.FAIL).newCnMsg("任务不存在").newMsg("task not found");
		}
		return Result.successWith(task);
	}

	private Long requireAdmin(HttpServletRequest request) {
		Long userId = getUserIdFromToken(request);
		if (userId == null) {
			return null;
		}
		User user = userMapper.selectById(userId);
		if (user == null || !"ADMIN".equals(user.getRole())) {
			return null;
		}
		return userId;
	}

	private <T> Result<T> currentDenied(HttpServletRequest request) {
		if (getUserIdFromToken(request) == null) {
			return Result.of(ResultCode.LOGIN_REQUIRED);
		}
		return Result.of(ResultCode.PERMISSION_DENIED);
	}

	private Long getUserIdFromToken(HttpServletRequest request) {
		String token = request.getHeader("Authorization");
		if (token != null && token.startsWith("Bearer ")) {
			token = token.substring(7);
			try {
				return jwtUtil.getUserIdFromToken(token);
			} catch (Exception e) {
				return null;
			}
		}
		return null;
	}
}
