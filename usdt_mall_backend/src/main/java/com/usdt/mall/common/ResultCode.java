package com.usdt.mall.common;

import lombok.Getter;

@Getter
public enum ResultCode {
	// 通用错误码
	SUCCESS(101100, "成功", "success"),
	FAIL(101101, "失败", "fail"),
	PARAMETER_ERROR(101113, "参数错误", "parameter error"),

	// 用户相关错误码
	EMAIL_ALREADY_EXISTS(101104, "邮箱已存在", "email already exists"),
	USER_NOT_FOUND(101105, "用户未找到", "user not found"),
	INVALID_CREDENTIALS(101107, "邮箱或密码错误", "invalid credentials"),
	INVALID_EMAIL_FORMAT(101125, "邮箱格式无效", "invalid email format"),
	ACCOUNT_DISABLED(101108, "账户已被禁用", "account disabled"),
	INVALID_CURRENT_PASSWORD(101187, "当前密码错误", "invalid current password"),
	PAYMENT_PASSWORD_ALREADY_SET(101188, "支付密码已设置", "payment password already set"),
	PAYMENT_PASSWORD_NOT_SET(101189, "支付密码未设置", "payment password not set"),
	INVALID_PAYMENT_PASSWORD(101191, "支付密码错误", "invalid payment password"),
	INSUFFICIENT_BALANCE(101192, "余额不足", "insufficient balance"),
	SYSTEM_ACCOUNT_NOT_FOUND(101193, "系统账户不存在", "system account not found"),
	SYSTEM_ACCOUNT_INSUFFICIENT_BALANCE(101194, "系统账户余额不足，请平台处理", "system account insufficient balance, please contact platform"),

	// 权限相关错误码
	TOKEN_REQUIRED(101190, "令牌必需", "token required"),
	INVALID_TOKEN(101112, "无效的令牌", "invalid token"),
	PERMISSION_DENIED(101165, "权限不足", "permission denied"),
	LOGIN_REQUIRED(101124, "请先登录", "login required"),

	// 文件相关错误码
	FILE_EMPTY(101114, "文件为空", "file is empty"),
	FILE_TOO_LARGE(101115, "文件过大", "file too large"),
	FILE_NAME_INVALID(101116, "文件名无效", "file name invalid"),
	FILE_TYPE_NOT_ALLOWED(101117, "文件类型不允许", "file type not allowed"),
	FILE_NOT_FOUND(101118, "文件未找到", "file not found"),
	FILE_UPLOAD_FAILED(101119, "文件上传失败", "file upload failed"),
	FILE_DOWNLOAD_FAILED(101120, "文件下载失败", "file download failed"),
	FILE_DELETE_FAILED(101179, "删除文件失败", "delete file failed"),

	// 商品相关错误码
	PRODUCT_NOT_FOUND(101121, "商品不存在", "product not found"),
	PRODUCT_OUT_OF_STOCK(101122, "库存不足", "product out of stock"),

	// 购物车相关错误码
	CART_ITEM_NOT_FOUND(101123, "购物车记录不存在", "cart item not found"),

	// 店铺相关错误码
	SHOP_NOT_FOUND(101126, "店铺不存在", "shop not found"),
	SHOP_APPLICATION_PENDING(101127, "您已有待审核的申请，请等待审核结果", "shop application pending"),
	SHOP_APPLICATION_APPROVED(101128, "您已有通过的店铺申请，一个用户只能拥有一个店铺", "shop application approved"),
	SHOP_APPLICATION_NOT_FOUND(101129, "申请不存在", "shop application not found"),
	SHOP_APPLICATION_ALREADY_PROCESSED(101130, "该申请已处理", "shop application already processed"),
	USER_ALREADY_HAS_SHOP(101131, "该用户已拥有店铺", "user already has shop"),
	INVITE_CODE_REQUIRED(101132, "邀请码不能为空", "invite code required"),
	INVITE_CODE_INVALID(101133, "邀请码无效，未找到对应用户", "invite code invalid"),
	INVITE_CODE_NOT_ADMIN(101134, "邀请码无效，该用户不是管理员", "invite code not admin"),

	// 轮播商品相关错误码
	CAROUSEL_PRODUCT_ALREADY_EXISTS(101135, "该商品已在轮播列表中", "carousel product already exists"),
	CAROUSEL_PRODUCT_LIMIT_EXCEEDED(101136, "轮播商品最多只能添加5个", "carousel product limit exceeded"),
	CAROUSEL_PRODUCT_NOT_FOUND(101137, "轮播商品不存在", "carousel product not found"),
	PRODUCT_ID_LIST_EMPTY(101138, "商品ID列表不能为空", "product id list empty"),

	// 订单相关错误码
	CART_ITEMS_NOT_FOUND(101139, "购物车商品不存在", "cart items not found"),
	CART_ITEMS_NOT_BELONG_TO_USER(101140, "购物车商品不属于当前用户", "cart items not belong to user"),
	ADDRESS_NOT_FOUND_OR_NO_ACCESS(101141, "收货地址不存在或不属于当前用户", "address not found or no access"),
	PRODUCT_NOT_FOUND_WITH_ID(101142, "商品不存在", "product not found with id"),
	PRODUCT_STOCK_INSUFFICIENT(101143, "商品库存不足", "product stock insufficient"),
	ORDER_NOT_FOUND_OR_NO_ACCESS(101144, "订单不存在或无权访问", "order not found or no access"),
	ORDER_STATUS_INVALID_FOR_SHIPMENT(101145, "订单状态不正确，无法发货", "order status invalid for shipment"),
	ORDER_STATUS_INVALID_FOR_RECEIPT(101146, "订单状态不正确，无法确认收货", "order status invalid for receipt"),
	ORDER_NOT_ARRIVED(101195, "订单尚未到货，无法确认收货", "order not arrived yet"),
	ORDER_CANNOT_BE_CANCELLED(101147, "订单已完成或已取消，无法取消", "order cannot be cancelled"),

	// 商品管理相关错误码
	PRODUCT_IMAGES_LIMIT_EXCEEDED(101148, "最多只能上传5张图片", "product images limit exceeded"),
	CATEGORY_NOT_FOUND(101149, "分类不存在", "category not found"),

	// 充值提现记录相关错误码
	RECORD_NOT_FOUND(101150, "记录不存在", "record not found"),
	RECORD_ALREADY_AUDITED(101151, "记录已审核，无法重复操作", "record already audited"),

	// 店铺管理相关错误码
	SHOP_NOT_EXISTS(101152, "店铺不存在", "shop not exists"),
	USER_HAS_NO_SHOP(101153, "您还没有店铺", "user has no shop"),
	PRODUCT_NOT_BELONG_TO_SHOP(101154, "该商品不属于您的店铺", "product not belong to shop"),
	PRODUCT_ALREADY_IN_SHOP(101155, "该商品已在店铺中", "product already in shop"),
	NO_PERMISSION_TO_MODIFY_SHOP(101156, "无权限修改此店铺", "no permission to modify shop"),

	// 系统配置相关错误码
	PROFIT_RATE_INVALID(101157, "利润率必须在0-100之间", "profit rate invalid");

	private final Integer code;
	private final String cnMsg;
	private final String enMsg;

	ResultCode(Integer code, String cnMsg, String enMsg) {
		this.code = code;
		this.cnMsg = cnMsg;
		this.enMsg = enMsg;
	}
}
