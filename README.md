# Rusa Testbed

Multiple fuzzers/testers to compare against.

## Building

Build images from the project root, e.g.,
`docker build --tag testbed-restler -f ./restler/Dockerfile . --target compile`
We also included a `build.sh` file to build all images.

## Dependencies

Don't forget git submodules.

```bash
git submodule update --init --recursive
```

## Shared Inputs

- `rusa.jar`: latest Rusa
- `vulnserver.jar`: vulnerable server to test
- `openapi.yml`: REST API definition of the vulnerable server

## Applications

- restler: [RESTler](https://github.com/microsoft/restler-fuzzer)
- zap: [Zed Attack Proxy](https://www.zaproxy.org/) [(src)](https://github.com/zaproxy/zaproxy)
- burp: [Burp Suite](https://portswigger.net/burp)
