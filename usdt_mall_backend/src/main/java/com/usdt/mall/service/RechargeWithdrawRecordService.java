package com.usdt.mall.service;

import com.usdt.mall.vo.request.RecordQueryReqVO;
import com.usdt.mall.vo.response.RecordPageRespVO;

import java.util.List;
import java.util.Map;

/**
 * 充值/提现记录服务接口
 */
public interface RechargeWithdrawRecordService {

	/**
	 * 分页查询用户的充值/提现记录
	 *
	 * @param token 用户token
	 * @param reqVO 查询条件
	 * @return 分页结果
	 */
	RecordPageRespVO getRecordsByPage(String token, RecordQueryReqVO reqVO);

	/**
	 * 管理员分页查询所有用户的充值/提现记录
	 *
	 * @param token    管理员token
	 * @param keyword  搜索关键词（用户名/昵称）
	 * @param type     记录类型
	 * @param page     页码
	 * @param pageSize 每页数量
	 * @return 分页结果
	 */
	RecordPageRespVO getAllRecordsByPage(String token, String keyword, Integer type, Integer page, Integer pageSize);

	/**
	 * 审核通过记录
	 *
	 * @param token    管理员token
	 * @param recordId 记录ID
	 */
	void approveRecord(String token, Long recordId);

	/**
	 * 拒绝记录
	 *
	 * @param token    管理员token
	 * @param recordId 记录ID
	 */
	void rejectRecord(String token, Long recordId);

	/**
	 * 获取待处理记录数量
	 *
	 * @param token 用户token
	 * @return 待处理数量统计
	 */
	Map<String, Integer> getPendingCount(String token);

	/**
	 * 标记记录为已读
	 *
	 * @param token    用户token
	 * @param recordId 记录ID
	 */
	void markAsRead(String token, Long recordId);

	/**
	 * 批量标记记录为已读
	 *
	 * @param token     用户token
	 * @param recordIds 记录ID列表
	 */
	void batchMarkAsRead(String token, List<Long> recordIds);
}
