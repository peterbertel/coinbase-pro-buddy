import json, hmac, hashlib, time, requests, base64, boto3
from requests.auth import AuthBase

API_PERMISSION = "view"

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
	print("Hello world")
	api_url = 'https://api.pro.coinbase.com/'
	keys = get_api_keys()
	auth = CoinbaseExchangeAuth(keys['api_key'], keys['api_secret'], keys['api_pass'])

	# # Get accounts
	account_response = requests.get(api_url + 'accounts', auth=auth)
	print(account_response.json())

	time_response = requests.get(api_url + 'time')
	print(time_response.json())

	return {
		'statusCode': 200,
		'body': json.dumps('Hello from Lambda!')
	}
