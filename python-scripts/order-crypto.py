import json, hmac, hashlib, time, requests, base64, os
from requests.auth import AuthBase

API_PERMISSION = "trade"
ORDER_SIZE_IN_USD = os.environ['ORDER_SIZE_IN_USD']
ORDER_SIDE = "buy"
PRODUCT_ID = "BTC-USD"

class CoinbaseExchangeAuth(AuthBase):
	def __init__(self, api_key, secret_key, passphrase):
		self.api_key = api_key
		self.secret_key = secret_key
		self.passphrase = passphrase
	
	def __call__(self, request):
		timestamp = str(time.time())
		message = timestamp + request.method + request.path_url + (request.body or '')
		hmac_key = base64.b64decode(self.secret_key)
		signature = hmac.new(hmac_key, message.encode('ascii'), hashlib.sha256)
		signature_b64 = base64.b64encode(signature.digest()).decode('utf-8')

		request.headers.update({
			'CB-ACCESS-SIGN': signature_b64,
			'CB-ACCESS-TIMESTAMP': timestamp,
			'CB-ACCESS-KEY': self.api_key,
			'CB-ACCESS-PASSPHRASE': self.passphrase,
			'Content-Type': 'application/json'
		})
		return request

def get_api_keys():
	client = boto3.client('ssm')
	api_keys = {}
	api_keys_ssm_parameter_names = ["api_key", "api_secret", "api_pass"]

	for ssm_parameter_name in api_keys_ssm_parameter_names:
		response = client.get_parameter(
			Name='/coinbase/{}/{}'.format(ssm_parameter_name, API_PERMISSION),
			WithDecryption=True
		)
		api_keys.update({ssm_parameter_name: response['Parameter']['Value']})

	return api_keys

def lambda_handler(event, context):
	api_url = 'https://api.pro.coinbase.com/'
	keys = get_api_keys()
	auth = CoinbaseExchangeAuth(keys['api_key'], keys['api_secret'], keys['api_pass'])

	product_response = requests.get(api_url + 'products/{}/ticker'.format(PRODUCT_ID))
	ask_price = product_response.json()['ask']

	maximum_fee = ORDER_SIZE_IN_USD * .005
	order_size = round((ORDER_SIZE_IN_USD - maximum_fee) / float(ask_price), 7)

	order_data = {
		'size': order_size,
		'price': ask_price,
		'side': ORDER_SIDE,
		'product_id': PRODUCT_ID
	}
	order_data = json.dumps(order_data)

	order_response = requests.post(api_url + 'orders', auth=auth, data=order_data)
	print(order_response.json())

	return {
		'statusCode': 200,
		'body': json.dumps('Hello from Lambda!')
	}
