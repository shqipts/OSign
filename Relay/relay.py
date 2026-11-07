"""OSign private tailnet relay. Stores signed IPAs only; no signing API."""
import os, secrets, time, threading, plistlib, zipfile, hmac
from pathlib import Path
from urllib.parse import urlsplit
from uuid import UUID
from flask import Flask, request, jsonify, abort, send_file, Response

MAX_IPA=1024*1024*1024

def create_app(state, token, public_base, ttl=1800, manifest_only=False):
    state=Path(state); state.mkdir(parents=True,exist_ok=True,mode=0o700)
    os.chmod(state,0o700)
    app=Flask(__name__); app.config['MAX_CONTENT_LENGTH']=16384 if manifest_only else MAX_IPA
    @app.before_request
    def public_surface():
        if manifest_only and request.endpoint not in {'health','local_manifest','download'}: abort(404)
    records={}; lock=threading.RLock()
    def purge():
        now=time.time()
        with lock:
            for key,entry in list(records.items()):
                if entry['expires']<=now:
                    if entry.get('file') is not None: entry['file'].unlink(missing_ok=True)
                    del records[key]
    @app.get('/health')
    def health(): return jsonify(service='osign-install-relay',status='ok')
    @app.post('/upload')
    def upload():
        if not hmac.compare_digest(request.headers.get('Authorization',''), 'Bearer '+token): abort(401)
        purge()
        if not request.content_length or request.content_length>MAX_IPA: abort(413)
        with lock:
            if sum(entry.get('file') is not None for entry in records.values())>=4: abort(429,description='Too many temporary IPAs. Wait for expiry.')
            key=secrets.token_urlsafe(32); path=state/(key+'.ipa')
            try:
                with path.open('xb') as out:
                    os.chmod(path,0o600)
                    total=0
                    while True:
                        chunk=request.stream.read(1024*1024)
                        if not chunk: break
                        total+=len(chunk)
                        if total>MAX_IPA: abort(413)
                        out.write(chunk)
                with zipfile.ZipFile(path) as z:
                    infos=z.infolist()
                    if len(infos)>100000: raise ValueError('Too many archive entries')
                    roots=[i for i in infos if i.filename.startswith('Payload/') and i.filename.count('/')==2 and i.filename.endswith('.app/Info.plist')]
                    if len(roots)!=1 or roots[0].file_size>1024*1024: raise ValueError('Missing or oversized app metadata')
                    metadata=plistlib.loads(z.read(roots[0]))
                    identifier=metadata.get('CFBundleIdentifier'); version=metadata.get('CFBundleVersion')
                    title=metadata.get('CFBundleDisplayName') or metadata.get('CFBundleName') or identifier
                    if not all(isinstance(x,str) and x.strip() and len(x)<512 for x in [identifier,version,title]): raise ValueError('Invalid app metadata')
                records[key]={'file':path,'expires':time.time()+ttl,'identifier':identifier,'version':version,'title':title}
            except Exception:
                path.unlink(missing_ok=True); abort(400,description='Invalid IPA or metadata')
        return jsonify(manifestURL=f'{public_base}/files/{key}/manifest.plist',expiresIn=ttl),201
    @app.post('/manifest')
    def local_manifest():
        if not hmac.compare_digest(request.headers.get('Authorization',''), 'Bearer '+token): abort(401)
        if not request.content_length or request.content_length > 16384: abort(413)
        data=request.get_json(silent=True)
        if not isinstance(data,dict): abort(400)
        identifier,version,title=(data.get(key) for key in ['identifier','version','title'])
        if not all(isinstance(value,str) and value.strip() and len(value)<512 for value in [identifier,version,title]): abort(400)
        try:
            payload=data['ipaURL']
            parsed=urlsplit(payload)
            if parsed.scheme!='http' or parsed.hostname!='127.0.0.1' or parsed.username or parsed.password or parsed.query or parsed.fragment or not parsed.port or not 4000 <= parsed.port <= 8000: raise ValueError()
            if not parsed.path.endswith('.ipa') or parsed.path.count('/')!=1: raise ValueError()
            UUID(parsed.path[1:-4])
        except (KeyError,TypeError,ValueError): abort(400,description='Only a localhost IPA URL with a UUID path is accepted')
        purge()
        with lock:
            if sum(entry.get('file') is None for entry in records.values())>=32: abort(429)
            key=secrets.token_urlsafe(32)
            records[key]={'file':None,'payload':payload,'expires':time.time()+min(ttl,600),'identifier':identifier,'version':version,'title':title}
        return jsonify(manifestURL=f'{public_base}/files/{key}/manifest.plist',expiresIn=min(ttl,600)),201
    @app.get('/files/<key>/<name>')
    def download(key,name):
        purge()
        with lock: entry=records.get(key)
        if not entry: abort(404)
        if name=='app.ipa':
            if entry.get('file') is None: abort(404)
            response=send_file(entry['file'],mimetype='application/octet-stream',conditional=True,download_name='app.ipa')
        elif name=='manifest.plist':
            manifest={'items':[{'assets':[{'kind':'software-package','url':entry.get('payload') or f'{public_base}/files/{key}/app.ipa'}], 'metadata':{'bundle-identifier':entry['identifier'],'bundle-version':entry['version'],'kind':'software','title':entry['title']}}]}
            response=Response(plistlib.dumps(manifest),mimetype='application/xml')
        else: abort(404)
        response.headers['Cache-Control']='no-store'
        return response
    app.osign_purge=purge
    return app

if __name__=='__main__':
    root=Path(os.environ['OSIGN_RELAY_STATE'])
    # Reboots invalidate all capabilities; remove only this service's IPA files.
    root.mkdir(parents=True,exist_ok=True,mode=0o700)
    for old in root.glob('*.ipa'): old.unlink()
    manifest_only=os.environ.get('OSIGN_RELAY_MANIFEST_ONLY')=='1'
    app=create_app(root,Path(os.environ['OSIGN_RELAY_TOKEN_FILE']).read_text().strip(),os.environ['OSIGN_RELAY_PUBLIC_BASE'],manifest_only=manifest_only)
    def janitor():
        while True:
            time.sleep(30); app.osign_purge()
    threading.Thread(target=janitor,daemon=True).start()
    from waitress import serve
    serve(app,host='127.0.0.1',port=int(os.environ.get('OSIGN_RELAY_PORT','8081')),threads=4,max_request_body_size=16384 if manifest_only else MAX_IPA,channel_timeout=60 if manifest_only else 600)
