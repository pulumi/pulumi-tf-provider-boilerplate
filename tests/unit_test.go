// Copyright 2016-2019, Pulumi Corporation.(
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
package tests

import (
	"os"
	"testing"

	"github.com/pulumi/pulumi/pkg/testing/integration"
	"github.com/stretchr/testify/assert"
)

func TestMountTarget(t *testing.T) {
	// Get configuration from the CI environment
	configPoint := os.Getenv("XYZ_CONFIG_POINT")
	if configPoint == "" {
		t.Skipf("Skipping test due to missing XYZ_CONFIG_POINT environment variable")
	}
	cwd, err := os.Getwd()
	if !assert.NoError(t, err, "expected a valid working directory: %v", err) {
		return
	}

	base := integration.ProgramTestOptions{
		Config: map[string]string{
			//"xyz:configPoint": configPoint,
		},
	}

	baseJS := base.With(integration.ProgramTestOptions{
		Dependencies: []string{
			"@pulumi/xyz",
		},
	})

	examples := []integration.ProgramTestOptions{
		// Each test runs the program referenced in Dir, and then each of EditDirs
		// runs in turn.
		//baseJS.With(integration.ProgramTestOptions{
		//	Dir: path.Join(cwd, "xyz_test", "step1"),
		//	EditDirs: []integration.EditDir{
		//		{
		//			Dir:      "step2",
		//			Additive: true,
		//		},
		//	},
		//}),
	}

	for _, ex := range examples {
		example := ex
		t.Run(example.Dir, func(t *testing.T) {
			integration.ProgramTest(t, &example)
		})
	}
}
