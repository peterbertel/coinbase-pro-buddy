import json, hmac, hashlib, time, requests, base64, os, boto3
from requests.auth import AuthBase
from requests.exceptions import HTTPError

API_PERMISSION = "transfer"
TRANSFER_CURRENCY = "USD"

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
	try:
		api_url = 'https://api.pro.coinbase.com/'
		keys = get_api_keys()
		auth = CoinbaseExchangeAuth(keys['api_key'], keys['api_secret'], keys['api_pass'])
		deposit_amount = event["deposit_amount"]

		payment_methods_response = requests.get(api_url + 'payment-methods', auth=auth)
		payment_method_id = payment_methods_response.json()[0]['id']

		deposit_data = {
			'amount': deposit_amount,
			'currency': TRANSFER_CURRENCY,
			'payment_method_id': payment_method_id
		}
		deposit_data = json.dumps(deposit_data)

		deposit_response = requests.post(api_url + 'deposits/payment-method', auth=auth, data=deposit_data)
		print(deposit_response.json())
		deposit_response.raise_for_status()
	except HTTPError as http_error:
		return {
			'statusCode': deposit_response.status_code,
			'body': http_error.response.json()
		}
	except Exception as error:
		return {
			'statusCode': 400,
			'body': json.dumps(str(error))
		}
	else:
		return {
			'statusCode': deposit_response.status_code,
			'body': json.dumps('Successfully deposited funds.')
		}
