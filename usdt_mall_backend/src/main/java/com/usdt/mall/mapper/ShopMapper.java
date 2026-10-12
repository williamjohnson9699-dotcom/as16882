package com.usdt.mall.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.usdt.mall.entity.Shop;
import com.usdt.mall.vo.response.VirtualShopOptionRespVO;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

/**
 * 店铺Mapper接口
 */
@Mapper
public interface ShopMapper extends BaseMapper<Shop> {

	/**
	 * 只列出店主角色为 SHOP 的店铺。keyword 为空时不过滤用户名和店名。
	 */
	@Select("SELECT s.id AS shopId, s.user_id AS userId, u.username AS username, s.name AS shopName "
			+ "FROM shop s INNER JOIN `user` u ON u.id = s.user_id AND u.role = 'SHOP' "
			+ "WHERE (#{keyword} IS NULL OR #{keyword} = '' "
			+ "OR u.username LIKE CONCAT('%', #{keyword}, '%') ESCAPE '\\\\' "
			+ "OR s.name LIKE CONCAT('%', #{keyword}, '%') ESCAPE '\\\\') "
			+ "ORDER BY u.username ASC, s.id ASC")
	IPage<VirtualShopOptionRespVO> selectVirtualShopOptions(Page<VirtualShopOptionRespVO> page,
			@Param("keyword") String keyword);
}
