// Copyright 2016-2017, Pulumi Corporation.  All rights reserved.

package examples

import (
	"io/ioutil"
	"net/http"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"

	"github.com/pulumi/pulumi/pkg/testing/integration"
)

func TestExamples(t *testing.T) {
	// Ensure we have any required configuration points
	// region := os.Getenv("AWS_REGION")
	// if region == "" {
	// 	t.Skipf("Skipping test due to missing AWS_REGION environment variable")
	// }
	// cwd, err := os.Getwd()
	// if !assert.NoError(t, err, "expected a valid working directory: %v", err) {
	// 	return
	// }

	// base options shared amongst all tests.
	base := integration.ProgramTestOptions{
		Config: map[string]string{
			// Configuration map
		},
		Tracing: "https://tracing.pulumi-engineering.com/collector/api/v1/spans",
	}
	baseJS := base.With(integration.ProgramTestOptions{
		Dependencies: []string{
			// JavaScript dependencies
		},
	})

	examples := []integration.ProgramTestOptions{
		// List each test
		// baseJS.With(integration.ProgramTestOptions{
		// 	Dir: path.Join(cwd, "api"),
		// 	ExtraRuntimeValidation: validateAPITest(func(body string) {
		// 		assert.Equal(t, "Hello, world!", body)
		// 	}),
		// 	EditDirs: []integration.EditDir{{
		// 		Dir:      "./api/step2",
		// 		Additive: true,
		// 		ExtraRuntimeValidation: validateAPITest(func(body string) {
		// 			assert.Equal(t, "<h1>Hello world!</h1>", body)
		// 		}),
		// 	}},
		// 	ExpectRefreshChanges: true,
		// }),
	}

	if !testing.Short() {
		// Append any longer running tests
	}

	for _, ex := range examples {
		example := ex
		t.Run(example.Dir, func(t *testing.T) {
			integration.ProgramTest(t, &example)
		})
	}
}

func createEditDir(dir string) integration.EditDir {
	return integration.EditDir{Dir: dir, ExtraRuntimeValidation: nil}
}

func validateAPITest(isValid func(body string)) func(t *testing.T, stack integration.RuntimeValidationStackInfo) {
	return func(t *testing.T, stack integration.RuntimeValidationStackInfo) {
		var resp *http.Response
		var err error
		url := stack.Outputs["url"].(string)
		// Retry a couple times on 5xx
		for i := 0; i < 2; i++ {
			resp, err = http.Get(url + "/b")
			if !assert.NoError(t, err) {
				return
			}
			if resp.StatusCode < 500 {
				break
			}
			time.Sleep(10 * time.Second)
		}
		defer resp.Body.Close()
		body, err := ioutil.ReadAll(resp.Body)
		assert.NoError(t, err)
		isValid(string(body))
	}
}
