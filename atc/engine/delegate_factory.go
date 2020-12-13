package engine

import (
	"code.cloudfoundry.org/clock"

	"github.com/concourse/concourse/atc"
	"github.com/concourse/concourse/atc/db"
	"github.com/concourse/concourse/atc/exec"
	"github.com/concourse/concourse/atc/policy"
	"github.com/concourse/concourse/atc/worker"
)

type DelegateFactory struct {
	build         db.Build
	plan          atc.Plan
	rateLimiter   RateLimiter
	policyChecker policy.Checker
	artifactWirer worker.ArtifactWirer
}

func buildDelegateFactory(
	build db.Build,
	plan atc.Plan,
	rateLimiter RateLimiter,
	policyChecker policy.Checker,
	artifactWirer worker.ArtifactWirer,
) DelegateFactory {
	return DelegateFactory{
		build:         build,
		plan:          plan,
		rateLimiter:   rateLimiter,
		policyChecker: policyChecker,
		artifactWirer: artifactWirer,
	}
}

func (delegate DelegateFactory) GetDelegate(state exec.RunState) exec.GetDelegate {
	return NewGetDelegate(delegate.build, delegate.plan.ID, state, clock.NewClock(), delegate.policyChecker, delegate.artifactWirer)
}

func (delegate DelegateFactory) PutDelegate(state exec.RunState) exec.PutDelegate {
	return NewPutDelegate(delegate.build, delegate.plan.ID, state, clock.NewClock(), delegate.policyChecker, delegate.artifactWirer)
}

func (delegate DelegateFactory) TaskDelegate(state exec.RunState) exec.TaskDelegate {
	return NewTaskDelegate(delegate.build, delegate.plan.ID, state, clock.NewClock(), delegate.policyChecker, delegate.artifactWirer)
}

func (delegate DelegateFactory) CheckDelegate(state exec.RunState) exec.CheckDelegate {
	return NewCheckDelegate(delegate.build, delegate.plan, state, clock.NewClock(), delegate.rateLimiter, delegate.policyChecker, delegate.artifactWirer)
}

func (delegate DelegateFactory) BuildStepDelegate(state exec.RunState) exec.BuildStepDelegate {
	return NewBuildStepDelegate(delegate.build, delegate.plan.ID, state, clock.NewClock(), delegate.policyChecker, delegate.artifactWirer)
}

func (delegate DelegateFactory) SetPipelineStepDelegate(state exec.RunState) exec.SetPipelineStepDelegate {
	return NewSetPipelineStepDelegate(delegate.build, delegate.plan.ID, state, clock.NewClock())
}
