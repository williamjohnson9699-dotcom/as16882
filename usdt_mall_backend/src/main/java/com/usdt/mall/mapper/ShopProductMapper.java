package com.usdt.mall.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.usdt.mall.entity.ShopProduct;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

import java.util.List;

@Mapper
public interface ShopProductMapper extends BaseMapper<ShopProduct> {

	/**
	 * 在售商品：店铺已关联，且商品状态为上架。
	 */
	@Select("<script>SELECT sp.shop_id AS shopId, COUNT(*) AS onSaleCount "
			+ "FROM shop_product sp INNER JOIN product p ON p.id = sp.product_id AND p.status = 1 "
			+ "WHERE sp.shop_id IN "
			+ "<foreach collection='shopIds' item='id' open='(' separator=',' close=')'>#{id}</foreach> "
			+ "GROUP BY sp.shop_id</script>")
	List<ShopOnSaleCount> countOnSaleByShopIds(@Param("shopIds") List<Long> shopIds);
}
