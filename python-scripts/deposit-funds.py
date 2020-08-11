import json, hmac, hashlib, time, requests, base64
from requests.auth import AuthBase

API_KEY = "abc"
API_SECRET = "abc"
API_PASS = "abc"
TRANSFER_AMOUNT = 10
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
		# signature = hmac.new(hmac_key, message, hashlib.sha256)
		signature = hmac.new(hmac_key, message.encode('ascii'), hashlib.sha256)
		# signature_b64 = signature.digest().encode('base64').rstrip('\n')
		signature_b64 = base64.b64encode(signature.digest()).decode('utf-8')

		request.headers.update({
			'CB-ACCESS-SIGN': signature_b64,
			'CB-ACCESS-TIMESTAMP': timestamp,
			'CB-ACCESS-KEY': self.api_key,
			'CB-ACCESS-PASSPHRASE': self.passphrase,
			'Content-Type': 'application/json'
		})
		return request

api_url = 'https://api.pro.coinbase.com/'
auth = CoinbaseExchangeAuth(API_KEY, API_SECRET, API_PASS)

payment_methods_response = requests.get(api_url + 'payment-methods', auth=auth)
payment_method_id = payment_methods_response.json()[0]['id']

deposit_data = {
	'amount': TRANSFER_AMOUNT,
	'currency': TRANSFER_CURRENCY,
	'payment_method_id': payment_method_id
}
deposit_data = json.dumps(deposit_data)

deposit_response = requests.post(api_url + 'deposits/payment-method', auth=auth, data=deposit_data)
print(deposit_response.json())
