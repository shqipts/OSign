"""Verify deployed semi-local metadata-only manifest service. No IPA upload."""
import urllib.request, urllib.error, json, plistlib
from pathlib import Path
base='https://87.106.127.145/osign'
token=(Path.home()/'.config/osign-relay/public-manifest-token').read_text().strip()
metadata={'identifier':'local.osign.transporttest','version':'1','title':'OSign metadata-only test','ipaURL':'http://127.0.0.1:5432/12345678-1234-1234-1234-123456789ABC.ipa'}
body=json.dumps(metadata).encode()
try:
    urllib.request.urlopen(urllib.request.Request(base+'/manifest',data=body,headers={'Content-Type':'application/json'}),timeout=15)
    raise AssertionError('Unauthenticated metadata accepted')
except urllib.error.HTTPError as error:
    assert error.code==401
request=urllib.request.Request(base+'/manifest',data=body,headers={'Content-Type':'application/json','Authorization':'Bearer '+token})
with urllib.request.urlopen(request,timeout=30) as response:
    assert response.status==201
    reply=json.load(response)
with urllib.request.urlopen(reply['manifestURL'],timeout=20) as response:
    assert response.status==200
    item=plistlib.loads(response.read())['items'][0]
assert item['assets'][0]['url']==metadata['ipaURL']
assert item['metadata']['bundle-identifier']==metadata['identifier']
try:
    urllib.request.urlopen(reply['manifestURL'].replace('manifest.plist','app.ipa'),timeout=15)
    raise AssertionError('Semi-local endpoint unexpectedly hosts an IPA')
except urllib.error.HTTPError as error:
    assert error.code==403
print('Verified actual VPS HTTPS: unauthorized request 401; metadata POST 201; manifest GET 200; payload points exactly to localhost; VPS IPA URL blocked with 403.')
print('Metadata request bytes:',len(body),'TTL:',reply['expiresIn'],'No IPA bytes or signing credentials were sent.')
print('This does not establish that iOS accepts the localhost installation handoff.')
