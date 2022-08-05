module github.com/pulumi/pulumi-xyz/provider

go 1.18

replace (
	github.com/hashicorp/go-getter v1.5.0 => github.com/hashicorp/go-getter v1.4.0
	github.com/hashicorp/terraform-plugin-sdk/v2 => github.com/pulumi/terraform-plugin-sdk/v2 v2.0.0-20220725190814-23001ad6ec03
	github.com/hashicorp/terraform-exec => github.com/hashicorp/terraform-exec v0.17.2
)

require (
	github.com/pulumi/pulumi-terraform-bridge/v3 v3.26.1
	github.com/pulumi/pulumi/sdk/v3 v3.36.0
)
