# Rusa Testbed

A testbed to evaluate Rusa, a feedback-driven fuzzer for Java Spring REST applications.

## Building and running

- Build the images using `build.sh` in `scripts`.
- Run the containers using `run.sh` in `scripts`.

## Dependencies

You need Docker and don't forget git submodules.

```bash
git submodule update --init --recursive
```

## Shared Inputs

- `rusa.jar`: latest Rusa
- `vulnserver.jar`: vulnerable server to test
- `openapi.yml`: REST API definition of the vulnerable server

## Applications

- Rusa: [Rusa](https://github.com/shoaloak/rusa)
- RESTler modified: [RESTler /w dynamic feedback](https://github.com/shoaloak/restler-mod)
- RESTler original: [RESTler](https://github.com/microsoft/restler-fuzzer)
