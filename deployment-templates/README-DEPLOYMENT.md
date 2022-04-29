# Configure

1. Create a directory at the root of your repo called .github/workflows

1. Place the release.yml from this directory there

1. Place the .goreleaser.yml from this directory at the root of your repo

1. Obtain needed accounts and tokens from the language specific package managers you will use

1. Add any needed tokens to the actions secrets for your repository or organization

1. Customize the release.yml with the correct tokens using the format:  

      `${{ secrets.MyTokenName }}`

1. Customize .goreleaser.yml for your provider, paying special attention that the ldlflags are set to match your provider/go.mod exactly: 

     `-X github.com/pulumi/pulumi-aws/provider/v5/pkg/version.Version={{.Tag}}`

1. Delete this directory if desired


# Deploy

1. Push a tag to your repo in the format "v0.0.0" to initiate a release

1. IMPORTANT: also add a tag in the format "sdk/v0.0.0" for the Go SDK
