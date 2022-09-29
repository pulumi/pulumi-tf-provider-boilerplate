# Terraform Bridge Provider Boilerplate

This repository contains boilerplate code for building a new Pulumi provider which wraps an existing Terraform provider.  

## Background

This repository is part of the [guide for authoring and publishing a Pulumi Package](https://www.pulumi.com/docs/guides/pulumi-packages/how-to-author).

Learn about the concepts behind [Pulumi Packages](https://www.pulumi.com/docs/guides/pulumi-packages/#pulumi-packages).

## Creating a Pulumi Terraform Bridge Provider

The following instructions cover:

- providers maintained by Pulumi (denoted with a "Pulumi Official" checkmark on the Pulumi registry)
- providers published and maintained by the Pulumi community, referred to as "third-party" providers

We showcase a Pulumi-owned provider based on an upstream provider named `terraform-provider-foo`.  Substitute appropriate values below for your use case.

> Note: If the name of the desired Pulumi provider differs from the name of the Terraform provider, you will need to carefully distinguish between the references - see <https://github.com/pulumi/pulumi-azure> for an example.

### Prerequisites

Ensure the following tools are installed and present in your `$PATH`:

- [`pulumictl`](https://github.com/pulumi/pulumictl#installation)
- [Go 1.17](https://golang.org/dl/) or 1.latest
- [NodeJS](https://nodejs.org/en/) 14.x.  We recommend using [nvm](https://github.com/nvm-sh/nvm) to manage NodeJS installations.
- [Yarn](https://yarnpkg.com/)
- [TypeScript](https://www.typescriptlang.org/)
- [Python](https://www.python.org/downloads/) (called as `python3`).  For recent versions of MacOS, the system-installed version is fine.
- [.NET](https://dotnet.microsoft.com/download)

### Creating and Initializing the Repository

Pulumi offers this repository as a [GitHub template repository](https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-repository-from-a-template) for convenience.  From this repository:

1. Click "Use this template".
1. Set the following options:
    - Owner: pulumi (third-party: your GitHub organization/username)
    - Repository name: pulumi-foo (third-party: preface your repo name with "pulumi" as standard practice)
    - Description: Pulumi provider for Foo
    - Repository type: Public
1. Clone the generated repository.

From the templated repository:

1. Run the following command to update files to use the name of your provider (third-party: use your GitHub organization/username):

    ```bash
    make prepare NAME=foo REPOSITORY=github.com/pulumi/pulumi-foo
    ```

   This will do the following:
   - rename folders in `provider/cmd` to `pulumi-resource-foo` and `pulumi-tfgen-foo`
   - replace dependencies in `provider/go.mod` to reflect your repository name
   - find and replace all instances of the boilerplate `xyz` with the `NAME` of your provider.

   Note for third-party providers:
   - Make sure to set the correct GitHub organization/username in all files referencing your provider as a dependency:
     - `examples/go.mod`
     - `provider/resources.go`
     - `sdk/go.mod`
     - `provider/cmd/pulumi-resource-foo/main.go`
     - `provider/cmd/pulumi-tfgen-foo/main.go`

2. Modify `README-PROVIDER.md` to include the following (we'll rename it to `README.md` toward the end of this guide):
    - Any desired build status badges.
    - An introductory paragraph describing the type of resources the provider manages, e.g. "The Foo provider for Pulumi manages resources for [Foo](http://example.com/).
    - In the "Installing" section, correct package names for the various SDK libraries in the languages Pulumi supports.
    - In the "Configuration" section, any configurable options for the provider.  These may include, but are not limited to, environment variables or options that can be set via [`pulumi config set`](https://www.pulumi.com/docs/reference/cli/pulumi_config_set/).
    - In the "Reference" section, provide a link to the to-be-published documentation.
    - Feel free to refer to [the Pulumi AWS provider README](https://github.com/pulumi/pulumi-aws) as an example.

### Composing the Provider Code - Prerequisites

Pulumi provider repositories have the following general structure:

- `examples/` contains sample code which may optionally be included as integration tests to be run as part of a CI/CD pipeline.
- `provider/` contains the Go code used to create the provider as well as generate the SDKs in the various languages that Pulumi supports.
  - `provider/cmd/pulumi-tfgen-foo` generates the Pulumi resource schema (`schema.json`), based on the Terraform provider's resources.
  - `provider/cmd/pulumi-resource-foo` generates the SDKs in all supported languages from the schema, placing them in the `sdk/` folder.
  - `provider/pkg/resources.go` is the location where we will define the Terraform-to-Pulumi mappings for resources.
- `sdk/` contains the generated SDK code for each of the language platforms that Pulumi supports, with each supported platform in a separate subfolder.

1. In `provider/go.mod`, add a reference to the upstream Terraform provider in the `require` section, e.g.

    ```go
    github.com/foo/terraform-provider-foo v0.4.0
    ```

1. In `provider/resources.go`, ensure the reference in the `import` section uses the correct Go module path, e.g.:

    ```go
    github.com/foo/terraform-provider-foo/foo
    ```

1. Download the dependencies:

    ```bash
    cd provider && go mod tidy && cd -
    ```

1. Create the schema by running the following command:

    ```bash
    make tfgen
    ```

    Note warnings about unmapped resources and data sources in the command's output.  We map these in the next section, e.g.:

    ```text
    warning: resource foo_something not found in provider map; skipping
    warning: resource foo_something_else not found in provider map; skipping
    warning: data source foo_something not found in provider map; skipping
    warning: data source foo_something_else not found in provider map; skipping
    ```

## Adding Mappings, Building the Provider and SDKs

In this section we will add the mappings that allow the interoperation between the Pulumi provider and the Terraform provider.  Terraform resources map to an identically named concept in Pulumi.  Terraform data sources map to plain old functions in your supported programming language of choice.  Pulumi also allows provider functions and resources to be grouped into _namespaces_ to improve the cohesion of a provider's code, thereby making it easier for developers to use.  If your provider has a large number of resources, consider using namespaces to improve usability.

The following instructions all pertain to `provider/resources.go`, in the section of the code where we construct a `tfbridge.ProviderInfo` object:

1. **Add resource mappings:** For each resource in the provider, add an entry in the `Resources` property of the `tfbridge.ProviderInfo`, e.g.:

    ```go
    // Most providers will have all resources (and data sources) in the main module.
    // Note the mapping from snake_case HCL naming conventions to UpperCamelCase Pulumi SDK naming conventions.
    // The name of the provider is omitted from the mapped name due to the presence of namespaces in all supported Pulumi languages.
    "foo_something":      {Tok: tfbridge.MakeResource(mainPkg, mainMod, "Something")},
    "foo_something_else": {Tok: tfbridge.MakeResource(mainPkg, mainMod, "SomethingElse")},
    ```

1. **Add CSharpName (if necessary):** Dotnet does not allow for fields named the same as the enclosing type, which sometimes results in errors during the dotnet SDK build.
    If you see something like

    ```text
    error CS0542: 'ApiKey': member names cannot be the same as their enclosing type [/Users/guin/go/src/github.com/pulumi/pulumi-artifactory/sdk/dotnet/Pulumi.Artifactory.csproj]
    ```

    you'll want to give your Resource a CSharpName, which can have any value that makes sense:

    ```go
    "foo_something_dotnet": {
        Tok: tfbridge.MakeResource(mainPkg, mainMod, "SomethingDotnet"),
        Fields: map[string]*tfbridge.SchemaInfo{
            "something_dotnet": {
                CSharpName: "SpecialName",
            },
        },
    },
    ```

   [See the underlying terraform-bridge code here.](https://github.com/pulumi/pulumi-terraform-bridge/blob/master/pkg/tfbridge/info.go#L168)
1. **Add data source mappings:** For each data source in the provider, add an entry in the `DataSources` property of the `tfbridge.ProviderInfo`, e.g.:

    ```go
    // Note the 'get' prefix for data sources
    "foo_something":      {Tok: tfbridge.MakeDataSource(mainPkg, mainMod, "getSomething")},
    "foo_something_else": {Tok: tfbridge.MakeDataSource(mainPkg, mainMod, "getSomethingElse")},
    ```

1. **Add documentation mapping (sometimes needed):**  If the upstream provider's repo is not a part of the `terraform-providers` GitHub organization, specify the `GitHubOrg` property of `tfbridge.ProviderInfo` to ensure that documentation is picked up by the codegen process, and that attribution for the upstream provider is correct, e.g.:

    ```go
    GitHubOrg: "foo",
    ```

1. **Add provider configuration overrides (not typically needed):** Pulumi's Terraform bridge automatically detects configuration options for the upstream provider.  However, in rare cases these settings may need to be overridden, e.g. if we want to change an environment variable default from `API_KEY` to `FOO_API_KEY`.  Examples of common uses cases:

    ```go
    "additional_required_parameter": {},
    "additional_optional_string_parameter": {
        Default: &tfbridge.DefaultInfo{
            Value: "default_value",
        },
    "additional_optional_boolean_parameter": {
        Default: &tfbridge.DefaultInfo{
            Value: true,
        },
    // Renamed environment variables can be accounted for like so:
    "apikey": {
        Default: &tfbridge.DefaultInfo{
            EnvVars: []string{"FOO_API_KEY"},
        },
    ```

1. Build the provider binary and ensure there are no warnings about unmapped resources and no warnings about unmapped data sources:

    ```bash
    make provider
    ```

    You may see warnings about documentation and examples, including "unexpected code snippets".  These can be safely ignored for now.  Pulumi will add additional documentation on mapping docs in a future revision of this guide.

1. Build the SDKs in the various languages Pulumi supports:

    ```bash
    make build_sdks
    ```

1. Ensure the Golang SDK is a proper go module:

    ```bash
    cd sdk && go mod tidy && cd -
    ```

    This will pull in the correct dependencies in `sdk/go.mod` as well as setting the dependency tree in `sdk/go.sum`.

1. Finally, ensure the provider code conforms to Go standards:

    ```bash
    make lint_provider
    ```

    Fix any issues found by the linter.

**Note:** If you make revisions to code in `resources.go`, you must re-run the `make tfgen` target to regenerate the schema.
The `make tfgen` target will take the file `schema.json` and serialize it to a byte array so that it can be included in the build output.
(This is a holdover from Go 1.16, which does not have the ability to directly embed text files. We are working on removing the need for this step.)

## Sample Program

In this section, we will create a Pulumi program in TypeScript that utilizes the provider we created to ensure everything is working properly.

1. Create an account with the provider's service and generate any necessary credentials, e.g. API keys.
    - Email: bot@pulumi.com
    - Password: (Create a random password in 1Password with the  maximum length and complexity allowed by the provider.)
    - Ensure all secrets (passwords, generated API keys) are stored in Pulumi's 1Password vault.

1. Copy the `pulumi-resource-foo` binary generated by `make provider` and place it in your `$PATH` (`$GOPATH/bin` is a convenient choice), e.g.:

    ```bash
    cp bin/pulumi-resource-foo $GOPATH/bin
    ```

1. Tell Yarn to use your local copy of the SDK:

    ```bash
    make install_nodejs_sdk
    ```

1. Create a new Pulumi program in the `examples/` directory, e.g.:

    ```bash
    mkdir examples/my-example/ts # Change "my-example" to something more meaningful.
    cd examples/my-example/ts
    pulumi new typescript
    # (Go through the prompts with the default values)
    npm install
    yarn link @pulumi/foo
    ```

1. Create a minimal program for the provider, i.e. one that creates the smallest-footprint resource.  Place this code in `index.ts`.
1. Configure any necessary environment variables for authentication, e.g `$FOO_USERNAME`, `$FOO_TOKEN`, in your local environment.
1. Ensure the program runs successfully via `pulumi up`.
1. Once the program completes successfully, verify the resource was created in the provider's UI.
1. Destroy any resources created by the program via `pulumi destroy`.

Optionally, you may create additional examples for SDKs in other languages supported by Pulumi:

1. Python:

    ```bash
    mkdir examples/my-example/py
    cd examples/my-example/py
    pulumi new python
    # (Go through the prompts with the default values)
    source venv/bin/activate # use the virtual Python env that Pulumi sets up for you
    pip install pulumi_foo
    ```

1. Follow the steps above to verify the program runs successfully.

## Add End-to-end Testing

We can run integration tests on our examples using the `*_test.go` files in the `examples/` folder.

1. Add code to `examples_nodejs_test.go` to call the example you created, e.g.:

    ```go
    // Swap out MyExample and "my-example" below with the name of your integration test.
    func TestAccMyExampleTs(t *testing.T) {
        test := getJSBaseOptions(t).
            With(integration.ProgramTestOptions{
                Dir: filepath.Join(getCwd(t), "my-example", "ts"),
            })
        integration.ProgramTest(t, &test)
    }
    ```

1. Add a similar function for each example that you want to run in an integration test.  For examples written in other languages, create similar files for `examples_${LANGUAGE}_test.go`.

1. You can run these tests locally via Make:

    ```bash
    make test
    ```

    You can also run each test file separately via test tags:

    ```bash
    cd examples && go test -v -tags=nodejs
    ```

## Configuring CI with GitHub Actions

### Third-party providers

1. Follow the instructions laid out in the [deployment templates](./deployment-templates/README-DEPLOYMENT.md).

### Pulumi Internal

In this section, we'll add the necessary configuration to work with GitHub Actions for Pulumi's standard CI/CD workflows for providers.

1. Generate GitHub workflows per [the instructions in the ci-mgmt repository](https://github.com/pulumi/ci-mgmt/) and copy to `.github/` in this repository.

1. Ensure that any required secrets are present as repository-level [secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets) in GitHub.  These will be used by the integration tests during the CI/CD process.

1. Repository settings: Toggle `Allow auto-merge` on in your provider repo to automate GitHub Actions workflow updates.

## Final Steps

1. Ensure all required configurations (API keys, etc.) are documented in README-PROVIDER.md.

1. Replace this file with the README for the provider and push your changes:

    ```bash
    mv README-PROVIDER.md README.md
    ```

1. If publishing the npm package fails during the "Publish SDKs" Action, perform the following steps:
    1. Go to [NPM Packages](https://www.npmjs.com/) and sign in as pulumi-bot.
    1. Click on the bot's profile pic and navigate to "Packages".
    1. On the left, under "Organizations, click on the Pulumi organization.
    1. On the last page of the listed packages, you should see the new package.
    1. Under "Settings", set the Package Status to "public".

Now you are ready to use the provider, cut releases, and have some well-deserved :ice_cream:!

## Building the Provider Locally

There are 2 ways the provider can be built locally:

`make provider` will use the current operating system and architecture to create a binary that can be used on your PATH.

To build the provider for another set of operating systems / architectures, the project uses [goreleaser](https://goreleaser.com/).
Goreleaser, a CLI tool, that allows a user to build a matrix of binaries.

Create a `.goreleaser.yml` file in the root of your project:

```yaml

archives:
- id: archive
  name_template: "{{ .Binary }}-{{ .Tag }}-{{ .Os }}-{{ .Arch }}"
before:
  hooks:
  - make tfgen
builds:
- binary: pulumi-resource-xyz
  dir: provider
  goarch:
  - amd64
  - arm64
  goos:
  - darwin
  - windows
  - linux
  ignore: []
  ldflags:
  - -X github.com/pulumi/pulumi-xyz/provider/pkg/version.Version={{.Tag}}
  main: ./cmd/pulumi-resource-xyz/
  sort: asc
  use: git
release:
  disable: false
snapshot:
  name_template: "{{ .Tag }}-SNAPSHOT"
```

To build the provider for the combination of architectures and operating systems, you can run the following CLI command:

```bash
goreleaser build --rm-dist --skip-validate
```

That will ensure that a list of binaries are available to use:

```bash

▶ tree dist
dist
├── CHANGELOG.md
├── artifacts.json
├── config.yaml
├── metadata.json
├── pulumi-xyz_darwin_amd64_v1
│   └── pulumi-resource-xyz
├── pulumi-xyz_darwin_arm64
│   └── pulumi-resource-xyz
├── pulumi-xyz_linux_amd64_v1
│   └── pulumi-resource-xyz
├── pulumi-xyz_linux_arm64
│   └── pulumi-resource-xyz
├── pulumi-xyz_windows_amd64_v1
│   └── pulumi-resource-xyz.exe
└── pulumi-xyz_windows_arm64
    └── pulumi-resource-xyz.exe
```

Any of the provider binaries can be used to target the correct machine architecture

## The Shim Pattern

If you receive the following error: `use of internal package github.com/example/terraform-provider-example/internal/provider not allowed`, you need to use
the shim model below, and replace the example item:
<!-- markdownlint-disable MD010 -->
```bash

mkdir -p provider/shim
cat <<-EOF> provider/shim/go.mod
module github.com/example/terraform-provider-example/shim

go 1.18

require github.com/hashicorp/terraform-plugin-sdk/v2 v2.22.0
require github.com/example/terraform-provider-example v1.0.0

EOF

cat <<-EOF> provider/shim/shim.go
package shim

import (
	"github.com/hashicorp/terraform-plugin-sdk/v2/helper/schema"
	"github.com/example/terraform-provider-example/internal/provider"
)

// fix provider.Provider here to match whats in internal/provider
func Provider() *schema.Provider {
	return provider.Provider()
}

EOF

cd provider/shim/ && go mod tidy && cd ../../

cat <<EOF>> provider/go.mod
replace github.com/example/terraform-provider-example/shim => ./shim
require github.com/example/terraform-provider-example/shim v0.0.0
EOF

cd provider && go mod tidy

```
<!-- markdownlint-enable MD010 -->