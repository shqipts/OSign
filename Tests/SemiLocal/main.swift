import Foundation
let id=UUID(uuidString:"12345678-1234-1234-1234-123456789ABC")!
guard let payload=LocalDelivery.payloadURL(id:id,port:5432) else { fatalError("No local URL") }
assert(payload.absoluteString == "http://127.0.0.1:5432/12345678-1234-1234-1234-123456789ABC.ipa")
assert(LocalDelivery.payloadURL(id:id,port:80)==nil)
let body=try LocalDelivery.manifestRequest(identifier:"local.test",version:"1",title:"Test & App",payload:payload)
let json=try JSONSerialization.jsonObject(with:body) as! [String:String]
assert(json["ipaURL"]==payload.absoluteString)
assert(json.keys.sorted()==["identifier","ipaURL","title","version"])
do {
    _=try LocalDelivery.manifestRequest(identifier:"local.test",version:"1",title:"Test",payload:URL(string:"http://192.168.1.1:5432/test.ipa")!)
    fatalError("LAN URL accepted")
} catch { }
let page=LocalDelivery.installPage(for:URL(string:"https://ubuntu.tail4dcadb.ts.net:8443/osign/files/test/manifest.plist")!)
assert(page.contains("itms-services"))
assert(!page.contains("api.palera.in"))
print("PASS: localhost-only URL, bounded port, metadata-only request, LAN rejection, system handoff page")
