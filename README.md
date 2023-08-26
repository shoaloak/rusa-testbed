# Rusa Testbed

A testbed to evaluate Rusa, a feedback driven fuzzer for Java REST applications.

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
  - this one is moot, since RESTler doesn't understand SQLi, only 500
