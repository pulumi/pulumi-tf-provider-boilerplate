module github.com/pulumi/pulumi-xyz/provider

go 1.18

replace (
	github.com/hashicorp/terraform-plugin-sdk/v2 => github.com/pulumi/terraform-plugin-sdk/v2 upstream-v2.21.0
)

require (
	github.com/pulumi/pulumi-terraform-bridge/v3 v3.47.2
	github.com/pulumi/pulumi/sdk/v3 v3.67.1
)
