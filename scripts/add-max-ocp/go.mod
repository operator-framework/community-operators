module github.com/operator-framework/community-operators/scripts/add-max-ocp

go 1.16

require (
	github.com/blang/semver v3.5.1+incompatible
	// Ensure that it will use the same code implementation of the validator
	// use by sdk 1.9.0 (https://github.com/operator-framework/operator-sdk/blob/v1.9.0/go.mod)
	github.com/operator-framework/api v0.8.2-0.20210526151024-41d37db9141f
	github.com/sirupsen/logrus v1.8.1
)
