package com.usdt.mall.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.usdt.mall.entity.OrderItem;
import org.apache.ibatis.annotations.Mapper;

/**
 * 订单明细Mapper接口
 */
@Mapper
public interface OrderItemMapper extends BaseMapper<OrderItem> {
}
