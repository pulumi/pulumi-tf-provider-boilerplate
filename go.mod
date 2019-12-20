module github.com/pulumi/pulumi-xyz

go 1.13

replace github.com/Azure/go-autorest => github.com/Azure/go-autorest v12.4.3+incompatible

require (
	github.com/hashicorp/terraform-plugin-sdk v1.4.1
	github.com/pulumi/pulumi v1.8.0
	github.com/pulumi/pulumi-terraform-bridge v1.5.2
	github.com/stretchr/testify v1.4.1-0.20191106224347-f1bd0923b832
)
