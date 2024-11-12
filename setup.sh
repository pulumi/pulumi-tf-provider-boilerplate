#!/usr/bin/env bash

set -eE

handle_error() {
  echo "Error occurred at $0:${1}. Run with verbose '-v' flag to enable command logging."
  exit 1
}

trap 'handle_error $LINENO' ERR

usage() {
  cat <<EOF
NAME
  setup.sh - Initialize the project

SYNOPSIS
  setup.sh [OPTION]

DESCRIPTION
  Initializes the project for a specific provider. Inputs can be provided as command line arguments or
  will be prompted for if omitted and in an interactive shell.

OPTIONS
  -h, --help
    Print this help message and exit.

  -n <provider>
    The provider name to initialize the project for (e.g. aws).

  -r <repository>
    The repository name to initialize the project for (defaults to "pulumi-\${provider}).

  -o <organization>
    The organization name to initialize the project for. This is typically the
    GitHub username or organization name where the repository will live.

  -u <upstream>
    The upstream tf provider Go module to bridge into a Pulumi provider.
    (e.g. hashicorp/terraform-provider-aws).

  -v
    Enable verbose mode. Prints each command executed.
EOF
}

while getopts "h?dvp:o:r:u:" opt; do
  case ${opt} in
    h|\?)
      usage
      exit 0
      ;;
    v)
      verbose=true
      ;;
    p)
      provider=${OPTARG}
      ;;
    o)
      organization=${OPTARG}
      ;;
    r)
      repository=${OPTARG}
      ;;
    u)
      upstream=${OPTARG}
      ;;
    *)
      usage
      exit 1
      ;;
  esac
done

# Check if we have interactive inputs & outputs
if [[ -t 0 && -t 1 ]]; then
  interactive=true
else
  interactive=false
fi

# Enable verbose mode
if [[ "${verbose}" = "true" ]]; then
  echo "Verbose mode enabled"
  echo "  provider: ${provider}"
  echo "  organization: ${organization}"
  echo "  repository: ${repository}"
  echo "  upstream: ${upstream}"
  echo "  interactive: ${interactive}"
  echo "  verbose: ${verbose}"
  set -o xtrace
fi

# Prompt for missing options
if [[ "${interactive}" = "true" ]]; then
  echo "Starting interactive mode. Run $0 -h for usage help."
  while [[ -z "${provider}" ]]; do
    read -r -p "What's the name of the provider (e.g. aws)? " provider
  done
  while [[ -z "${organization}" ]]; do
    read -r -p "What's the GitHub organisation or username where this repo will reside (e.g. pulumi)? " organization
  done
  while [[ -z "${upstream}" ]]; do
    read -r -p "What's the upstream Terraform provider Go module to bridge into a Pulumi provider (e.g. hashicorp/terraform-provider-aws)? " upstream
  done
fi

# Validate options
if [[ -z "${provider}" ]]; then
  echo "Provider is required"
  usage
  exit 1
fi
if [[ -z "${organization}" ]]; then
  echo "Organization is required"
  usage
  exit 1
fi
if [[ -z "${repository}" ]]; then
  repository=pulumi-${provider}
fi

# Check if we're in a clean state
if test ! -d "provider/cmd/pulumi-tfgen-xyz"; then
  echo "Project already renamed, provider/cmd/pulumi-tfgen-xyz not found"
  exit 1
fi

# Replace tokens in resources.go and .ci-mgmt.yaml and README.md
OS=$(uname)
sed_inplace() {
  if [[ "${OS}" == "Darwin" ]]; then
    # In MacOS the -i parameter needs an empty string to execute in place.
    sed -i '' "${2}" "${1}" &> /dev/null
  else
    sed -i "${2}" "${1}" &> /dev/null
  fi
}
replace() {
  sed_inplace "${1}" "s,${2},${3},g"
}

# ci-mgmt
replace .ci-mgmt.yaml "provider: xyz" "provider: ${provider}"
replace .ci-mgmt.yaml "organization: pulumi" "organization: ${organization}"
make ci-mgmt

# Readme
# Delete README.md prelude up to the provider title line
provider_title_line_number=$(grep -n '# Xyz Resource Provider' README.md | cut -f1 -d:)
sed_inplace README.md "1,$((provider_title_line_number-1))d"
replace README.md "xyz" "${provider}"
replace README.md "Xyz" "$(echo "${provider}" | awk '{print toupper(substr($0,1,1)) substr($0,2)}' || true)"
replace README.md "XYZ" "$(echo "${provider}" | awk '{print toupper($0)}' || true)"

# Remove bridge metadata
rm -f provider/cmd/pulumi-resource-xyz/bridge-metadata.json

# Go modules & code
replace_go_src() {
  replace "${1}" github.com/pulumi/terraform-provider-xyz "${upstream}"
  replace "${1}" "github\.com/pulumi/pulumi-xyz" "github\.com/${organization}/${repository}"
  replace "${1}" xyz "${provider}"
}
replace provider/go.mod "github\.com/pulumi/pulumi-xyz" "github\.com/${organization}/${repository}"
replace provider/go.mod "github.com/pulumi/terraform-provider-xyz v.*" "${upstream} latest"
replace_go_src provider/resources.go
replace_go_src provider/cmd/pulumi-tfgen-xyz/main.go
replace_go_src provider/cmd/pulumi-resource-xyz/main.go
if [[ "${provider}" != "xyz" ]]; then # Don't fail on no-op rename
  mv provider/cmd/pulumi-tfgen-xyz "provider/cmd/pulumi-tfgen-${provider}"
  mv provider/cmd/pulumi-resource-xyz "provider/cmd/pulumi-resource-${provider}"
fi
# Resolve to a real upstream version in the go.mod
(cd provider && go get "${upstream}")
replace examples/go.mod "github\.com/pulumi/pulumi-xyz" "github\.com/${organization}/${repository}"
replace_go_src examples/examples_test.go

echo "Automated repository initialization complete. Please review changes and commit."
