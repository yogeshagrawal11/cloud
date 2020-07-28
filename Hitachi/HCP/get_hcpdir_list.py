import pycurl
import os

namespacename = "namespace_name.tenantname.hcpname.domain.com"
access_token = "tokenid"

curl = pycurl.Curl()
curl.setopt(pycurl.URL, "http://" + namespacename + "/rest/")
curl.setopt(pycurl.HTTPHEADER, ["Authorization: HCP " + access_token ])
curl.setopt(pycurl.SSL_VERIFYPEER, 0)
curl.setopt(pycurl.SSL_VERIFYHOST, 0)
curl.perform()

### prints response for HCP
print (curl.getinfo(pycurl.RESPONSE_CODE))
curl.close()
