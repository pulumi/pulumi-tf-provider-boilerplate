# Terraform Bridge Provider Boilerplate

This repository contains boilerplate code for building a new Pulumi provider which wraps an existing Terraform provider.  These instructions are primarily intended for internal use by Pulumi as we have not yet refined the process for general consumption by the community at large, but this document may serve as a rough guide for community members who want to create their own Pulumi providers that wrap an existing Terraform provider.

## Creating a Pulumi Terraform Bridge Provider

The following instructions assume a Pulumi-owned provider based on an upstream provider named `terraform-provider-foo`.  Substitute appropriate values below for your use case.

> Note: If the name of the desired Pulumi provider differs from the name of the Terraform provider, you will need to carefully distinguish between the references - see <https://github.com/pulumi/pulumi-azure> for an example.

### Prerequisites

Ensure the following tools are installed and present in your `$PATH`:

* [`pulumictl`](https://github.com/pulumi/pulumictl#installation)
* [Go 1.16](https://golang.org/dl/) or 1.latest
* [NodeJS](https://nodejs.org/en/) 14.x.  We recommend using [nvm](https://github.com/nvm-sh/nvm) to manage NodeJS installations.
* [Yarn](https://yarnpkg.com/)
* [TypeScript](https://www.typescriptlang.org/)
* [Python](https://www.python.org/downloads/) (called as `python3`).  For recent versions of MacOS, the system-installed version is fine.
* [.NET](https://dotnet.microsoft.com/download)

### Creating and Initializing the Repository

Pulumi offers this repository as a [GitHub template repository](https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-repository-from-a-template) for convenience.  From this repository:

1. Click "Use this template".
1. Set the following options:
    * Owner: pulumi (or your GitHub organization/username)
    * Repository name: pulumi-foo
    * Description: Pulumi provider for Foo
    * Repository type: Public
1. Clone the generated repository to the appropriate location in your `$GOPATH`.

From the templated repository:

1. Run the following command to update files to use the name of your provider:

    ```bash
    make prepare NAME=foo REPOSITORY=github.com/pulumi/pulumi-foo
    ```

1. Modify `README-PROVIDER.md` to include the following (we'll rename it to `README.md` toward the end of this guide):
    * Any desired build status badges.
    * An introductory paragraph describing the type of resources the provider manages, e.g. "The Foo provider for Pulumi manages resources for [Foo](http://example.com/).
    * In the "Installing" section, correct package names for the various SDK libraries in the languages Pulumi supports.
    * In the "Configuration" section, any configurable options for the provider.  These may include, but are not limited to, environment variables or options that can be set via [`pulumi config set`](https://www.pulumi.com/docs/reference/cli/pulumi_config_set/).
    * In the "Reference" section, provide a link to the to-be-published documentation.

### Composing the Provider Code - Prerequisites

Pulumi provider repositories have the following general structure:

* `examples/` contains sample code which may optionally be included as integration tests to be run as part of a CI/CD pipeline.
* `provider/` contains the Go code used to create the provider as well as generate the SDKs in the various languages that Pulumi supports.
* `sdk/` contains the generated SDK code for each of the language platforms that Pulumi supports, with each supported platform in a separate subfolder.

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
    cd provider && go mod tidy && popd
    ```

1. Validate the schema by running the following command:

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
    "foo_something":      {Tok: makeResource(mainMod, "Something")},
    "foo_something_else": {Tok: makeResource(mainMod, "SomethingElse")},
    ```

1. **Add data source mappings:** For each data source in the provider, add an entry in the `DataSources` property of the `tfbridge.ProviderInfo`, e.g.:

    ```go
    "foo_something":      {Tok: makeDataSource(mainMod, "getSomething")},
    "foo_something_else": {Tok: makeDataSource(mainMod, "getSomethingElse")},
    ```

1. **Add documentation mapping (sometimes needed):**  If the upstream provider's repo is not a part of the `terraform-providers` GitHub organization, specify the `GitHubOrg` property of `tfbridge.ProviderInfo` to ensure that documentation is picked up by the codegen process, and that attribution for the upstream provider is correct, e.g.:

    ```go
    GitHubOrg: "foo",
    ```

1. **Add provider configuration overrides (not typically needed):** Pulumi's Terraform bridge automatically detects configuration options for the upstream provider.  However, in rare cases these settings may need to be overrideen, e.g. if we want to change an environment variable default from `API_KEY` to `FOO_API_KEY`.  Examples of common uses cases:

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
    // Reanmed environment variables can be accounted for like so:
    "apikey": {
        Default: &tfbridge.DefaultInfo{
            EnvVars: []string{"FOO_API_KEY"},
        },
    ```

1. Build the provider and ensure there are no warnings about unmapped resources and no warnings about unmaped data sources:

    ```bash
    make provider
    ```

    You may see warnings about documentation and examples.  These can be safely ignored for now.  Pulumi will add additional documentation on mapping docs in a future revision of this guide.

1. Build the SDKs in the various languages Pulumi supports:

    ```bash
    make build_sdks
    ```

1. Ensure the SDK is a proper go module:

    ```bash
    cd sdk && go mod tidy && popd
    ```

    This will pull in the correct dependencies in `sdk/go.mod` as well as setting the dependency tree in `sdk/go.sum`.

1. Finally, ensure the provider code conforms to Go standards:

    ```bash
    make lint_provider
    ```

    Fix any issues found by the linter.

**Note:** If you make revisions to code in `resources.go`, you must re-run the `make tfgen` target to regenerate the schema.  Pulumi providers use Go 1.16, which does not have the ability to directly embed text files.  The `make tfgen` target will take the file `schema.json` and serialize it to a byte array so that it can be included in the build output.  (Go 1.17 will remove the need for this step.)

## Sample Program and End-to-end Testing

In this section, we will create a Pulumi program in TypeScript that utilizes the provider we created to ensure everything is working properly.

1. Create an account with the provider's service and generate any necessary credentials, e.g. API keys:
    * Email: bot@pulumi.com
    * Password: (Create a random password in 1Password with the  maximum length and complexity allowed by the provider.)
    * Ensure all secrets (passwords, generated API keys) are stored in Pulumi's 1Password vault.
    * Enter any secrets consumed by integration tests as repository-level secrets in GitHub.  These will be used by the integration tests during the CI/CD process.
1. Generate GitHub workflows per [the instructions in the ci-cmgmt repository](https://github.com/pulumi/ci-mgmt/#readme) and copy to `.github/` in this repository.
1. Copy the binary generated by the build and place it in your `$PATH` (`$GOPATH/bin` is a convenient choice), e.g.:

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

1. Create a minmal program for the provider, i.e. one that creates the smallest-footprint resource.  Place this code in `index.ts`.
1. Configure any necessary environmental variables and ensure the program runs successfully via `pulumi up`.
1. Once the program completes successfully, verify the resource was created in the provider's UI.
1. Destroy any resources created by the progam via `pulumi destroy`.

Optionally, you may create additional examples for SDKs in other languages supported by Pulumi.

## Configuring CI/CD with GitHub Actions

In this section, we'll add the necessary configuration to work with GitHub Actions for Pulumi's standard CI/CD workflows for providers.

1. Per the [README in the `ci-mgmt` repo](https://github.com/pulumi/ci-mgmt/#readme), generate the necessary GitHub Actions files and place them in the `.github/actions` directory in this repository.
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

    Add a similar function for each example that you want to run in an integration tests.  For examples written in other languages, create similar files for `examples_${LANGUAGE}_test.go`.
1. Ensure that any required secrets (API keys, etc.) are present in GitHub.

## Final Steps

1. Replace this file with the README for the provider and push your changes:

    ```bash
    mv README-PROVIDER.md README.md
    ```
