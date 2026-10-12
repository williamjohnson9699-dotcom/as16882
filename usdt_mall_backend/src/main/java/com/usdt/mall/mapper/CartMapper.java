package com.usdt.mall.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.usdt.mall.entity.Cart;
import org.apache.ibatis.annotations.Mapper;

/**
 * 购物车Mapper接口
 */
@Mapper
public interface CartMapper extends BaseMapper<Cart> {
}
