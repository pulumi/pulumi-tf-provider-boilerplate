// Copyright 2024, Pulumi Corporation.  All rights reserved.
//go:build nodejs || all
// +build nodejs all

package examples

import (
	"path/filepath"
	"testing"

	"github.com/pulumi/pulumi/pkg/v3/testing/integration"
)

func TestBasicTs(t *testing.T) {
	t.Skip("Skipping until the provider has been implemented")

	opts := getJSBaseOptions(t).With(integration.ProgramTestOptions{
		Dir: filepath.Join(getCwd(t), "basic-ts"),
	})

	integration.ProgramTest(t, &opts)
}
