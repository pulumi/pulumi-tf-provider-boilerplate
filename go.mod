module github.com/pulumi/pulumi-xyz

go 1.12

replace (
	github.com/Nvveen/Gotty => github.com/ijc25/Gotty v0.0.0-20170406111628-a8b993ba6abd
	github.com/golang/glog => github.com/pulumi/glog v0.0.0-20180820174630-7eaa6ffb71e4
)

require (
	github.com/hashicorp/terraform-plugin-sdk v1.1.1
	github.com/pulumi/pulumi v1.3.3
	github.com/pulumi/pulumi-terraform-bridge v1.0.0
	github.com/stretchr/testify v1.4.0
)
