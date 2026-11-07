import io, tempfile, unittest, zipfile, plistlib, time
from pathlib import Path
from relay import create_app

def ipa():
    data=io.BytesIO()
    with zipfile.ZipFile(data,'w') as z:
        z.writestr(zipfile.ZipInfo('Payload/Test.app/Info.plist',date_time=(2020,1,1,0,0,0)), plistlib.dumps({'CFBundleIdentifier':'local.fixture.test','CFBundleVersion':'1','CFBundleDisplayName':'Fixture'}))
    return data.getvalue()

class RelayTests(unittest.TestCase):
    def test_upload_download_manifest_auth_and_expiry(self):
        with tempfile.TemporaryDirectory() as d:
            app=create_app(Path(d),'test-token','https://imac.tail4dcadb.ts.net/osign', ttl=1)
            c=app.test_client()
            self.assertEqual(c.post('/upload',data=ipa()).status_code,401)
            r=c.post('/upload',data=ipa(),headers={'Authorization':'Bearer test-token','Content-Type':'application/octet-stream'})
            self.assertEqual(r.status_code,201)
            url=r.json['manifestURL']; route=url.split('/osign')[1]
            m=c.get(route); self.assertEqual(m.status_code,200)
            p=plistlib.loads(m.data)['items'][0]
            self.assertEqual(p['metadata']['bundle-identifier'],'local.fixture.test')
            payload=p['assets'][0]['url'].split('/osign')[1]
            with c.get(payload) as response:
                self.assertEqual(response.data,ipa())
            with c.get(payload,headers={'Range':'bytes=0-3'}) as response:
                self.assertEqual(response.status_code,206)
            self.assertEqual(c.post('/upload',data=b'bad',headers={'Authorization':'Bearer test-token'}).status_code,400)
            time.sleep(1.1)
            self.assertEqual(c.get(route).status_code,404)
            self.assertFalse(list(Path(d).glob('*.ipa')))
    def test_semi_local_manifest_never_uploads_or_hosts_an_ipa(self):
        with tempfile.TemporaryDirectory() as d:
            app=create_app(Path(d),'test-token','https://ubuntu.tail4dcadb.ts.net:8443/osign',ttl=1)
            c=app.test_client()
            payload={'identifier':'local.fixture.test','version':'1','title':'Fixture & Test','ipaURL':'http://127.0.0.1:5432/12345678-1234-1234-1234-123456789ABC.ipa'}
            self.assertEqual(c.post('/manifest',json=payload).status_code,401)
            r=c.post('/manifest',json=payload,headers={'Authorization':'Bearer test-token'})
            self.assertEqual(r.status_code,201)
            route=r.json['manifestURL'].split('/osign')[1]
            m=plistlib.loads(c.get(route).data)['items'][0]
            self.assertEqual(m['assets'][0]['url'],payload['ipaURL'])
            self.assertEqual(m['metadata']['title'],'Fixture & Test')
            self.assertEqual(list(Path(d).iterdir()),[])
            self.assertEqual(c.get(route.replace('manifest.plist','app.ipa')).status_code,404)
            for bad in ['http://192.168.1.2:5432/file.ipa','https://example.com/a.ipa','http://user:pass@127.0.0.1:5432/file.ipa','http://127.0.0.1:80/file.ipa']:
                self.assertEqual(c.post('/manifest',json={**payload,'ipaURL':bad},headers={'Authorization':'Bearer test-token'}).status_code,400)
            time.sleep(1.1)
            self.assertEqual(c.get(route).status_code,404)
    def test_public_mode_blocks_legacy_upload_and_limits_body(self):
        with tempfile.TemporaryDirectory() as d:
            app=create_app(Path(d),'test-token','https://87.106.127.145:8443/osign',manifest_only=True)
            c=app.test_client()
            self.assertEqual(c.post('/upload',data=ipa(),headers={'Authorization':'Bearer test-token'}).status_code,404)
            self.assertEqual(c.post('/manifest',data=b'x'*16385,headers={'Authorization':'Bearer test-token'}).status_code,413)
            self.assertEqual(c.get('/health').status_code,200)
if __name__=='__main__': unittest.main()
