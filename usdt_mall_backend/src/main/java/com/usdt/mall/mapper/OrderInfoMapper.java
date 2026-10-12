package com.usdt.mall.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.usdt.mall.entity.OrderInfo;
import org.apache.ibatis.annotations.Mapper;

/**
 * 订单信息Mapper
 */
@Mapper
public interface OrderInfoMapper extends BaseMapper<OrderInfo> {
}
