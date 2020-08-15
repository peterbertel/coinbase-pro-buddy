import json, hmac, hashlib, time, requests, base64
from requests.auth import AuthBase

API_KEY = "abc"
API_SECRET = "abc"
API_PASS = "abc"
CRYPTO_ADDRESS = "abcde12345"
WITHDRAW_AMOUNT = .001
WITHDRAW_CURRENCY = "BTC"

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

def lambda_handler(event, context):
	api_url = 'https://api.pro.coinbase.com/'
	auth = CoinbaseExchangeAuth(API_KEY, API_SECRET, API_PASS)

	withdraw_data = {
		'amount': WITHDRAW_AMOUNT,
		'currency': WITHDRAW_CURRENCY,
		'crypto_address': CRYPTO_ADDRESS
	}
	withdraw_data = json.dumps(withdraw_data)

	withdraw_response = requests.post(api_url + 'withdrawals/crypto', auth=auth, data=withdraw_data)
	print(withdraw_response.json())
	return {
		'statusCode': 200,
		'body': json.dumps('Hello from Lambda!')
	}
