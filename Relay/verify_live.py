"""Exercise the deployed private HTTPS relay with the built IPA, not credentials."""
import urllib.request, urllib.error, json, plistlib, hashlib, os
from pathlib import Path
vps=os.environ.get('OSIGN_VERIFY_VPS')=='1'
base='https://ubuntu.tail4dcadb.ts.net:8443/osign' if vps else 'https://imac.tail4dcadb.ts.net/osign'
token=(Path.home()/'.config/osign-relay'/('vps-upload-token' if vps else 'upload-token')).read_text().strip()
ipa=Path('/Users/shqipts/Downloads/OSign-unsigned.ipa').read_bytes()
try:
    urllib.request.urlopen(urllib.request.Request(base+'/upload',data=b'bad',method='POST'),timeout=10)
    raise AssertionError('unauthorized upload accepted')
except urllib.error.HTTPError as error: assert error.code==401
request=urllib.request.Request(base+'/upload',data=ipa,headers={'Authorization':'Bearer '+token,'Content-Type':'application/octet-stream'},method='POST')
with urllib.request.urlopen(request,timeout=120) as response:
    assert response.status==201
    reply=json.load(response)
with urllib.request.urlopen(reply['manifestURL'],timeout=20) as response:
    manifest=plistlib.loads(response.read())
item=manifest['items'][0]
assert item['metadata']['bundle-identifier']=='local.osign.app'
url=item['assets'][0]['url']
with urllib.request.urlopen(urllib.request.Request(url,headers={'Range':'bytes=0-3'}),timeout=20) as response:
    assert response.status==206 and response.read()==b'PK\x03\x04'
with urllib.request.urlopen(url,timeout=60) as response:
    downloaded=response.read()
assert hashlib.sha256(downloaded).digest()==hashlib.sha256(ipa).digest()
print('HTTPS verified: auth rejects unauthorized uploads; real IPA uploaded; generated manifest metadata correct; byte-range download 206; full download SHA-256 matches. TTL:',reply['expiresIn'])
print('This transport test uses an unsigned build; it does not prove an iPhone installation.')
