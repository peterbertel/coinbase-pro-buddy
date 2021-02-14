account_id               = "11111111111"
region                   = "us-east-1"
vpc_cidr_block           = "10.10.0.0/16"
subnet_a_cidr_block      = "10.10.0.0/20"
subnet_b_cidr_block      = "10.10.16.0/20"
subnet_c_cidr_block      = "10.10.32.0/20"
deposit_amount           = "200"
deposit_cron_expression  = "cron(0 0 ? * 2 *)"
weekly_cron_expression   = "cron(0 12 ? * 2 *)"
weekly_product_orders    = {
	BTC-USD  = 100
}
