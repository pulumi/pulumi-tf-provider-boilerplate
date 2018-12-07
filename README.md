# Terraform Bridge Provider Boilerplate

This repository contains boilerplate code for building a new Pulumi provider which wraps an existing
Terraform provider.

Modify this README to describe:

- The type of resources the provider manages
- Add a build status image from Travis at the top of the README
- Update package names in the information below
- Add any important documentation of concepts (e.g. the "serverless" components in the AWS provider).

Then:

- Rename the `cmd/pulumi-{resource,tfgen}-x` directories to match the provider name
- Update `scripts/publish-package.sh` with the provider name
- Update `Makefile` with the provider name
- Update `Gopkg.template.toml` with the upstream provider and version information

Lock in dependency versions:

- `go get github.com/pulumi/scripts/govendor-override`
- `govendor-override < Gopkg.template.toml > Gopkg.toml`
- `make ensure`

Finally, build the provider:

- Edit `resources.go` to map each resource, and specify provider information
- Enumerate any examples in `examples/examples_test.go`
- `make`

## Installing

This package is available in many languages in the standard packaging formats.

### Node.js (Java/TypeScript)

To use from JavaScript or TypeScript in Node.js, install using either `npm`:

    $ npm install @pulumi/x

or `yarn`:

    $ yarn add @pulumi/x

### Python

To use from Python, install using `pip`:

    $ pip install pulumi_x

### Go

To use from Go, use `go get` to grab the latest version of the library

    $ go get github.com/pulumi/pulumi-x/sdk/go/...

## Reference

For detailed reference documentation, please visit [the API docs][1].


[1]: https://pulumi.io/reference/pkg/nodejs/@pulumi/x/index.html
