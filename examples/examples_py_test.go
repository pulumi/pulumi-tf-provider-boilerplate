// Copyright 2024, Pulumi Corporation.  All rights reserved.
//go:build python || all
// +build python all

package examples

import (
	"path/filepath"
	"testing"

	"github.com/pulumi/pulumi/pkg/v3/testing/integration"
)

func TestBasicPy(t *testing.T) {
	t.Skip("Skipping until the provider has been implemented")

	test := getPythonBaseOptions(t).
		With(integration.ProgramTestOptions{
			Dir: filepath.Join(getCwd(t), "basic-py"),
		})

	integration.ProgramTest(t, &test)
}
