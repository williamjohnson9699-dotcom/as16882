package com.usdt.mall.service;

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

public interface VirtualDataService {

	VirtualImportTaskPageRespVO listTasks(Long adminUserId, Integer page, Integer pageSize);

	VirtualImportTaskRespVO getTask(Long adminUserId, Long taskId);

	/**
	 * 分页列出可勾选店铺。没有在售商品的店也返回，在售数量为 0。
	 */
	VirtualShopOptionPageRespVO listShops(String keyword, Integer page, Integer pageSize);

	/**
	 * 校验前缀和数量。通过时返回 null，并去掉前缀前后空格。
	 */
	String validateShopGenerate(VirtualShopGenerateReqVO req);

	/**
	 * 只查询衔接位置，不写库。
	 */
	VirtualShopPreviewRespVO previewShops(VirtualShopGenerateReqVO req);

	/**
	 * 创建任务后立即返回，建店在后台按每批 20 个执行。
	 */
	VirtualShopSubmitRespVO submitShops(Long adminUserId, VirtualShopGenerateReqVO req);

	/**
	 * 校验店铺和六个数量。通过时返回 null，并把店铺 id 去重后写回请求。
	 */
	String validateOrderGenerate(VirtualOrderGenerateReqVO req);

	/**
	 * 创建订单和资金任务后立即返回。写入由 VirtualOrderLedgerWorker 执行。
	 */
	VirtualOrderSubmitRespVO submitOrders(Long adminUserId, VirtualOrderGenerateReqVO req);

	/**
	 * 校验店铺和商品条数。通过时返回 null，并把店铺 id 去重后写回请求。
	 */
	String validateProductGenerate(VirtualProductGenerateReqVO req);

	/**
	 * 创建商品任务后立即返回。写入由 VirtualProductWorker 执行。
	 */
	VirtualProductSubmitRespVO submitProducts(Long adminUserId, VirtualProductGenerateReqVO req);
}
