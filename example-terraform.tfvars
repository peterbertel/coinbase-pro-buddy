account_id          = "11111111111"
region              = "us-east-1"
vpc_cidr_block      = "10.10.0.0/16"
subnet_a_cidr_block = "10.10.0.0/20"
subnet_b_cidr_block = "10.10.16.0/20"
subnet_c_cidr_block = "10.10.32.0/20"
order_size_in_usd   = "20"
product_id          = "BTC-USD"
product_order_pairs = [
  {product_name = "bitcoin", product_id = "BTC-USD", order_size = 100},
	{product_name = "ethereum", product_id = "ETH-USD", order_size = 100},
]
