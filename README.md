# Rusa Testbed

A testbed to evaluate Rusa, a feedback driven fuzzer for Java REST applications.

## Building

Build images using `build.sh`.

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
