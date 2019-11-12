const http = require('http');
const os = require('os');
const port = process.env.PORT || 3000;

const IP='REMOTE_IP'

function getRemote(req, res) {
  path = '/info'
  http.get('http://' + IP + ':3000' + path, (resp) => {
    let rawData = '';
    resp.on('data', (chunk) => { rawData += chunk; });
    resp.on('end', () => {
      try {
        console.log(rawData)
        rawObj = JSON.parse(rawData)
        res.statusCode = 200;
        res.end(JSON.stringify({remote_info: rawObj}, null, 3))
      } catch (e) {
        console.error(e.message);
      }
    });
  }).on("error", (err) => {
    console.log("Error: " + err.message);
    res.statusCode = 500;
    res.end('error from remote:' + err.message);
  });
}

function ips() {
  var ret = [];
  var ifaces = os.networkInterfaces();

  Object.keys(ifaces).forEach(function (ifname) {
    ifaceIps = []
    ifaces[ifname].forEach(function (iface) {
      if ('IPv4' !== iface.family || iface.internal !== false) {
        // skip over internal (i.e. 127.0.0.1) and non-ipv4 addresses
        return;
      }
      ifaceIps.push(iface.address)
    });
    if (ifaceIps.length > 0) ret.push(ifaceIps)
  });
  return ret
}

const server = http.createServer((req, res) => {
  switch(req.url) {
  case '/info':
    res.statusCode = 200;
    res.setHeader('Content-Type', 'application/json');
    res.end(JSON.stringify({
      req_url:  req.url,
      os_hostname:  os.hostname(),
      ipArrays: ips()
    }, null, 3));
    break
  case '/remote':
    getRemote(req, res)
    break
  default:
    res.statusCode = 200;
    res.end(JSON.stringify({hello: "world"}, null, 3))
    break
  }
});

server.listen(port, () => {
  console.log(`Server running on http://localhost:${port}/`);
});

