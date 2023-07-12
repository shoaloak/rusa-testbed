# Rusa Testbed
Multiple fuzzers/testers to compare against.

## input:
- `rusa.jar` 		latest Rusa
- `vulnserver.jar` 	the vulnerable server to test
- `openapi.yml` 	the REST API definition of the vulnerable server

## applications
- restler: [RESTler](https://github.com/microsoft/restler-fuzzer)
- zap: [Zed Attack Proxy](https://www.zaproxy.org/) [(src)](https://github.com/zaproxy/zaproxy)
- burp: [Burp Suite](https://portswigger.net/burp)
