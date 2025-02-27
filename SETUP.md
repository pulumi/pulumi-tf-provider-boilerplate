# Terraform Bridge Provider Boilerplate

This repository is the template for authoring a Pulumi package from an existing Terraform provider as part of the guide for [authoring and publishing Pulumi packages](https://www.pulumi.com/docs/iac/packages-and-automation/pulumi-packages/authoring/).

This repository is initially set up as a fictitious provider named "xyz" to demonstrate a resource, a data source and configuration derived from the [github.com/pulumi/terraform-provider-xyz provider](https://github.com/pulumi/terraform-provider-xyz).

## Prerequisites

Ensure the following tools are installed and present in your `$PATH`:

- [`pulumictl`](https://github.com/pulumi/pulumictl#installation)
- [Go](https://golang.org/dl/) or 1.latest
- [`golangci-lint`](https://golangci-lint.run/welcome/install/)
- [NodeJS](https://nodejs.org/en/) Active or maintenance version ([Node.js Releases](https://nodejs.org/en/about/previous-releases)).  We recommend using [nvm](https://github.com/nvm-sh/nvm) to manage NodeJS installations.
- [Yarn](https://yarnpkg.com/)
- [TypeScript](https://www.typescriptlang.org/)
- [Python](https://www.python.org/downloads/) (called as `python3`).  For recent versions of MacOS, the system-installed version is fine.
- [.NET](https://dotnet.microsoft.com/download)

## Creating the Repository

Pulumi offers this repository as a [GitHub template repository](https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-repository-from-a-template) for convenience.  From this repository:

1. Click "Use this template".
1. Follow the new repository options:
    - Owner: select your GitHub organization or username
    - Repository name: A name prefixed with `pulumi-` as is the standard convention for Pulumi providers
    - Description: E.g. "Pulumi provider for ..."
    - Repository type: This must be Public to be published to the Pulumi registry
1. Clone your new repository ready for development.

## Initializing the Provider

From the templated repository run the init program and follow the prompts to replace the name "xyz" with the name of your provider:

```bash
./setup.sh
```

> [!TIP]
> This program can also be run non-interactively, passing the options via arguments. Run `./setup.sh -h` for the usage instructions.

Pulumi provider repositories have the following general structure:

- `examples/` sample code which may optionally be included as integration tests to be run as part of a CI/CD pipeline
- `provider/` Go code used to create the provider as well as generate the SDKs in the various languages that Pulumi supports
  - `provider/cmd/pulumi-tfgen-xyz` executable program to generate the Pulumi resource schema
  - `provider/cmd/pulumi-resource-xyz` provider plugin executable
  - `provider/resources.go` Terraform-to-Pulumi mappings and configuration
- `sdk/` generated SDKs for each language in a separate subfolder

### Review & Customise Your Provider

1. Review the updated `README.md` to include the following:
    - Short introductory paragraph describing the type of resources the provider manages.
    - In the "Installing" section, correct package names for the various SDK libraries in the languages Pulumi supports.
    - In the "Configuration" section, any configurable options for the provider.  These may include, but are not limited to, environment variables or options that can be set via [`pulumi config set`](https://www.pulumi.com/docs/reference/cli/pulumi_config_set/).
    - In the "Reference" section, provide a link to the to-be-published documentation.

1. Update the `DisplayName`, `Publisher`, and `Homepage` values in `provider/resources.go`.

1. Verify the upstream Terraform provider module import in the `provider/go.mod` and `provider/resources.go` are correct.
   - If the name of the desired Pulumi provider differs from the name of the Terraform provider, you will need to carefully distinguish between the references - see <https://github.com/pulumi/pulumi-azure> for an example.

1. Verify and download dependencies in the `provider/go.mod`:

    ```bash
    (cd provider && go mod tidy)
    ```

1. Generate the provider's schema:

    ```bash
    make tfgen
    ```

> [!TIP]
> Take note of warnings & errors in the output when generating the schema.

## Build the Provider and SDKs

> [!NOTE]
> Most providers can use [automatic token mapping](https://github.com/pulumi/pulumi-terraform-bridge/blob/master/docs/guides/automatic-token-mapping.md) which generates the `bridge-metadata.json` file. If you have warnings about unmapped resources in the step above, refer to the section on [Manual Mappings](#manual-mappings).
> If you need to customise the behaviour of the provider configuration, refer to the section [Customise Provider Configuration](#customise-provider-configuration).

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

    Some issues found by the linter can be fixed automatically by running `make lint_provider.fix`.

> [!NOTE]
> If you make revisions to code in `resources.go`, you must re-run the `make tfgen` target to regenerate the schema.

## Sample Program

In this section, we will create a Pulumi program in TypeScript that utilizes the provider we created to ensure everything is working properly.

1. Create an account with the provider's service and generate any necessary credentials, e.g. API keys.
    - Email: <bot@pulumi.com>
    - Password: (Create a random password in 1Password with the  maximum length and complexity allowed by the provider.)
    - Ensure all secrets (passwords, generated API keys) are stored in Pulumi's 1Password vault.

1. Copy the `pulumi-resource-xyz` binary generated by `make provider` and place it in your `$PATH` (`$GOPATH/bin` is a convenient choice), e.g.:

    ```bash
    cp bin/pulumi-resource-xyz $GOPATH/bin
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
    yarn link @pulumi/xyz
    ```

1. Create a minimal program for the provider, i.e. one that creates the smallest-footprint resource.  Place this code in `index.ts`.
1. Configure any necessary environment variables for authentication, e.g `$XYZ_USERNAME`, `$XYZ_TOKEN`, in your local environment.
1. Ensure the program runs successfully via `pulumi up`.
1. Once the program completes successfully, verify the resource was created in the provider's UI.
1. Destroy any resources created by the program via `pulumi destroy`.

## End-to-end Testing

Integration tests are Go tests residing in `examples/*_test.go`. Each test executes a program from a subdirectory within `examples/`. All tests are initially marked to be skipped as the example `xyz` provider is not fully implemented and will fail with "not implemented".

1. Update an example to update to use a resource generated from your provider SDK (e.g. update the code in `index.ts` of `examples/basic-ts`)

1. Locate the Go test for the example (e.g. `examples/basic-ts` is tested by `TestBasicTs` in `examples/examples_nodejs_test.go`)

1. Remove the "skip" directive on the first line: `t.Skip(...)`

1. Run the tests:

    ```bash
    make test
    ```

    You can also run each test file separately via test tags:

    ```bash
    (cd examples && go test -v -tags=nodejs)
    ```

1. Repeat the process for each language and add new examples and tests as needed.

## Configure GitHub Actions CI

This template utilizes Pulumi's [ci-mgmt templates](https://github.com/pulumi/ci-mgmt/) to automatically generate CI workflows and other build tooling.

This is configured via the [`.ci-mgmt.yaml`](.ci-mgmt.yaml) file and can be re-generated by running `make ci-mgmt` which also updates to the latest version of the tool.

The default configuration is designed for third-party use and will need to be adjusted for Pulumi internal providers.

### CI Management

When you have set up your provider with this template, your `.github/workflows` folder will contain a `resync-build.yml` Workflow
which runs a once-a week cronjob to upgrade the workflow files to match the latest process for Pulumi providers.

The Workflow will open a pull request so you can review the changes, make adjustments to your `.ci-mgmt.yaml` config file, and merge.

We recommend setting `PULUMI_PROVIDER_AUTOMATION_TOKEN` to a token with `pull-requests: write` permissions on your repository so that acceptance tests run on these automated pull requests.

Documentation for the settings available in `.ci-mgmt.yaml` is a work in progress, but the [source code comments](https://github.com/pulumi/ci-mgmt/blob/master/provider-ci/internal/pkg/config.go)
or [default config descriptions](https://github.com/pulumi/ci-mgmt/blob/master/provider-ci/internal/pkg/templates/defaults.config.yaml) may be useful.

## Final Steps

1. Ensure all required configurations (API keys, etc.) are documented in README-PROVIDER.md.

1. Delete the boilerplate's `SETUP.md` and `setup.sh` files.

1. Register your provider in the Pulumi Registry. See [Publishing a Community Package on the Registry](https://github.com/pulumi/registry#publishing-a-community-package-on-the-registry).

Now you are ready to use the provider, cut releases, and have some well-deserved :ice_cream:!

## Manual Mappings

In this section we will add the mappings that allow the interoperation between the Pulumi provider and the Terraform provider.  Terraform resources map to an identically named concept in Pulumi.  Terraform data sources map to plain old functions in your supported programming language of choice.  Pulumi also allows provider functions and resources to be grouped into _namespaces_ to improve the cohesion of a provider's code, thereby making it easier for developers to use.  If your provider has a large number of resources, consider using namespaces to improve usability.

The following instructions all pertain to `provider/resources.go`, in the section of the code where we construct a `tfbridge.ProviderInfo` object:

1. **Add resource mappings:** For each resource in the provider, add an entry in the `Resources` property of the `tfbridge.ProviderInfo`, e.g.:

    ```go
    // Most providers will have all resources (and data sources) in the main module.
    // Note the mapping from snake_case HCL naming conventions to UpperCamelCase Pulumi SDK naming conventions.
    // The name of the provider is omitted from the mapped name due to the presence of namespaces in all supported Pulumi languages.
    "xyz_something":      {Tok: tfbridge.MakeResource(mainPkg, mainMod, "Something")},
    "xyz_something_else": {Tok: tfbridge.MakeResource(mainPkg, mainMod, "SomethingElse")},
    ```

1. **Add CSharpName (if necessary):** Dotnet does not allow for fields named the same as the enclosing type, which sometimes results in errors during the dotnet SDK build.
    If you see something like

    ```text
    error CS0542: 'ApiKey': member names cannot be the same as their enclosing type [/Users/guin/go/src/github.com/pulumi/pulumi-artifactory/sdk/dotnet/Pulumi.Artifactory.csproj]
    ```

    you'll want to give your Resource a CSharpName, which can have any value that makes sense:

    ```go
    "xyz_something": {
        Tok: tfbridge.MakeResource(mainPkg, mainMod, "Something"),
        Fields: map[string]*tfbridge.SchemaInfo{
            "something": {
                CSharpName: "SomethingField",
            },
        },
    },
    ```

   [See the underlying terraform-bridge code here.](https://github.com/pulumi/pulumi-terraform-bridge/blob/master/pkg/tfbridge/info.go#L168)
1. **Add data source mappings:** For each data source in the provider, add an entry in the `DataSources` property of the `tfbridge.ProviderInfo`, e.g.:

    ```go
    // Note the 'get' prefix for data sources
    "xyz_something":      {Tok: tfbridge.MakeDataSource(mainPkg, mainMod, "getSomething")},
    "xyz_something_else": {Tok: tfbridge.MakeDataSource(mainPkg, mainMod, "getSomethingElse")},
    ```

1. **Add documentation mapping (sometimes needed):**  If the upstream provider's repo is not a part of the `terraform-providers` GitHub organization, specify the `GitHubOrg` property of `tfbridge.ProviderInfo` to ensure that documentation is picked up by the codegen process, and that attribution for the upstream provider is correct, e.g.:

    ```go
    GitHubOrg: "my-gh-org",
    ```

## Customise Provider Configuration

Pulumi's Terraform bridge automatically detects configuration options for the upstream provider.  However, in rare cases these settings may need to be overridden, e.g. if we want to change an environment variable default from `API_KEY` to `XYZ_API_KEY`.  Examples of common uses cases:

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
        EnvVars: []string{"XYZ_API_KEY"},
    },
```

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
