# Terraform Bridge Provider Boilerplate

This repository contains boilerplate code for building a new Pulumi provider which wraps an existing
Terraform provider.

Modify this README to describe:

- The type of resources the provider manages
- Add a build status image from Travis at the top of the README
- Update package names in the information below
- Add any important documentation of concepts (e.g. the "serverless" components in the AWS provider).

## Creating a Pulumi Terraform Bridge Provider

First, clone this repo with the name of the desired provider in place of `xyz`:

```
git clone https://github.com/pulumi/pulumi-tf-provider-boilerplate pulumi-xyz
```

Next, replace references to `xyz` with the name of your provider:
- Search/replace the string `xyz` with the name of your provider throughout this repo
- Rename the `cmd/pulumi-{resource,tfgen}-xyz` directories to match the provider name

> Note: If the name of the desired Pulumi provider differs from the name of the Terraform provider, you will need to carefully distinguish between the references - see https://github.com/pulumi/pulumi-azure for an example.


Lock in dependency versions:

- `go get github.com/pulumi/scripts/govendor-override`
- Update the version number of the Terraform provider in `Gopkg.template.toml` to match the latest available version.
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

    $ go get github.com/pulumi/pulumi-xyz/sdk/go/...

## Reference

For detailed reference documentation, please visit [the API docs][1].


[1]: https://pulumi.io/reference/pkg/nodejs/@pulumi/x/index.html
