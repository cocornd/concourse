// Code generated by counterfeiter. DO NOT EDIT.
package pipelinesfakes

import (
	"sync"

	"github.com/concourse/concourse/atc/creds"
	"github.com/concourse/concourse/atc/db"
	"github.com/concourse/concourse/atc/pipelines"
	"github.com/concourse/concourse/atc/radar"
	"github.com/concourse/concourse/atc/scheduler"
)

type FakeRadarSchedulerFactory struct {
	BuildScanRunnerFactoryStub        func(db.Pipeline, string, creds.Variables, radar.Notifications) radar.ScanRunnerFactory
	buildScanRunnerFactoryMutex       sync.RWMutex
	buildScanRunnerFactoryArgsForCall []struct {
		arg1 db.Pipeline
		arg2 string
		arg3 creds.Variables
		arg4 radar.Notifications
	}
	buildScanRunnerFactoryReturns struct {
		result1 radar.ScanRunnerFactory
	}
	buildScanRunnerFactoryReturnsOnCall map[int]struct {
		result1 radar.ScanRunnerFactory
	}
	BuildSchedulerStub        func(db.Pipeline) scheduler.BuildScheduler
	buildSchedulerMutex       sync.RWMutex
	buildSchedulerArgsForCall []struct {
		arg1 db.Pipeline
	}
	buildSchedulerReturns struct {
		result1 scheduler.BuildScheduler
	}
	buildSchedulerReturnsOnCall map[int]struct {
		result1 scheduler.BuildScheduler
	}
	invocations      map[string][][]interface{}
	invocationsMutex sync.RWMutex
}

func (fake *FakeRadarSchedulerFactory) BuildScanRunnerFactory(arg1 db.Pipeline, arg2 string, arg3 creds.Variables, arg4 radar.Notifications) radar.ScanRunnerFactory {
	fake.buildScanRunnerFactoryMutex.Lock()
	ret, specificReturn := fake.buildScanRunnerFactoryReturnsOnCall[len(fake.buildScanRunnerFactoryArgsForCall)]
	fake.buildScanRunnerFactoryArgsForCall = append(fake.buildScanRunnerFactoryArgsForCall, struct {
		arg1 db.Pipeline
		arg2 string
		arg3 creds.Variables
		arg4 radar.Notifications
	}{arg1, arg2, arg3, arg4})
	fake.recordInvocation("BuildScanRunnerFactory", []interface{}{arg1, arg2, arg3, arg4})
	fake.buildScanRunnerFactoryMutex.Unlock()
	if fake.BuildScanRunnerFactoryStub != nil {
		return fake.BuildScanRunnerFactoryStub(arg1, arg2, arg3, arg4)
	}
	if specificReturn {
		return ret.result1
	}
	fakeReturns := fake.buildScanRunnerFactoryReturns
	return fakeReturns.result1
}

func (fake *FakeRadarSchedulerFactory) BuildScanRunnerFactoryCallCount() int {
	fake.buildScanRunnerFactoryMutex.RLock()
	defer fake.buildScanRunnerFactoryMutex.RUnlock()
	return len(fake.buildScanRunnerFactoryArgsForCall)
}

func (fake *FakeRadarSchedulerFactory) BuildScanRunnerFactoryCalls(stub func(db.Pipeline, string, creds.Variables, radar.Notifications) radar.ScanRunnerFactory) {
	fake.buildScanRunnerFactoryMutex.Lock()
	defer fake.buildScanRunnerFactoryMutex.Unlock()
	fake.BuildScanRunnerFactoryStub = stub
}

func (fake *FakeRadarSchedulerFactory) BuildScanRunnerFactoryArgsForCall(i int) (db.Pipeline, string, creds.Variables, radar.Notifications) {
	fake.buildScanRunnerFactoryMutex.RLock()
	defer fake.buildScanRunnerFactoryMutex.RUnlock()
	argsForCall := fake.buildScanRunnerFactoryArgsForCall[i]
	return argsForCall.arg1, argsForCall.arg2, argsForCall.arg3, argsForCall.arg4
}

func (fake *FakeRadarSchedulerFactory) BuildScanRunnerFactoryReturns(result1 radar.ScanRunnerFactory) {
	fake.buildScanRunnerFactoryMutex.Lock()
	defer fake.buildScanRunnerFactoryMutex.Unlock()
	fake.BuildScanRunnerFactoryStub = nil
	fake.buildScanRunnerFactoryReturns = struct {
		result1 radar.ScanRunnerFactory
	}{result1}
}

func (fake *FakeRadarSchedulerFactory) BuildScanRunnerFactoryReturnsOnCall(i int, result1 radar.ScanRunnerFactory) {
	fake.buildScanRunnerFactoryMutex.Lock()
	defer fake.buildScanRunnerFactoryMutex.Unlock()
	fake.BuildScanRunnerFactoryStub = nil
	if fake.buildScanRunnerFactoryReturnsOnCall == nil {
		fake.buildScanRunnerFactoryReturnsOnCall = make(map[int]struct {
			result1 radar.ScanRunnerFactory
		})
	}
	fake.buildScanRunnerFactoryReturnsOnCall[i] = struct {
		result1 radar.ScanRunnerFactory
	}{result1}
}

func (fake *FakeRadarSchedulerFactory) BuildScheduler(arg1 db.Pipeline) scheduler.BuildScheduler {
	fake.buildSchedulerMutex.Lock()
	ret, specificReturn := fake.buildSchedulerReturnsOnCall[len(fake.buildSchedulerArgsForCall)]
	fake.buildSchedulerArgsForCall = append(fake.buildSchedulerArgsForCall, struct {
		arg1 db.Pipeline
	}{arg1})
	fake.recordInvocation("BuildScheduler", []interface{}{arg1})
	fake.buildSchedulerMutex.Unlock()
	if fake.BuildSchedulerStub != nil {
		return fake.BuildSchedulerStub(arg1)
	}
	if specificReturn {
		return ret.result1
	}
	fakeReturns := fake.buildSchedulerReturns
	return fakeReturns.result1
}

func (fake *FakeRadarSchedulerFactory) BuildSchedulerCallCount() int {
	fake.buildSchedulerMutex.RLock()
	defer fake.buildSchedulerMutex.RUnlock()
	return len(fake.buildSchedulerArgsForCall)
}

func (fake *FakeRadarSchedulerFactory) BuildSchedulerCalls(stub func(db.Pipeline) scheduler.BuildScheduler) {
	fake.buildSchedulerMutex.Lock()
	defer fake.buildSchedulerMutex.Unlock()
	fake.BuildSchedulerStub = stub
}

func (fake *FakeRadarSchedulerFactory) BuildSchedulerArgsForCall(i int) db.Pipeline {
	fake.buildSchedulerMutex.RLock()
	defer fake.buildSchedulerMutex.RUnlock()
	argsForCall := fake.buildSchedulerArgsForCall[i]
	return argsForCall.arg1
}

func (fake *FakeRadarSchedulerFactory) BuildSchedulerReturns(result1 scheduler.BuildScheduler) {
	fake.buildSchedulerMutex.Lock()
	defer fake.buildSchedulerMutex.Unlock()
	fake.BuildSchedulerStub = nil
	fake.buildSchedulerReturns = struct {
		result1 scheduler.BuildScheduler
	}{result1}
}

func (fake *FakeRadarSchedulerFactory) BuildSchedulerReturnsOnCall(i int, result1 scheduler.BuildScheduler) {
	fake.buildSchedulerMutex.Lock()
	defer fake.buildSchedulerMutex.Unlock()
	fake.BuildSchedulerStub = nil
	if fake.buildSchedulerReturnsOnCall == nil {
		fake.buildSchedulerReturnsOnCall = make(map[int]struct {
			result1 scheduler.BuildScheduler
		})
	}
	fake.buildSchedulerReturnsOnCall[i] = struct {
		result1 scheduler.BuildScheduler
	}{result1}
}

func (fake *FakeRadarSchedulerFactory) Invocations() map[string][][]interface{} {
	fake.invocationsMutex.RLock()
	defer fake.invocationsMutex.RUnlock()
	fake.buildScanRunnerFactoryMutex.RLock()
	defer fake.buildScanRunnerFactoryMutex.RUnlock()
	fake.buildSchedulerMutex.RLock()
	defer fake.buildSchedulerMutex.RUnlock()
	copiedInvocations := map[string][][]interface{}{}
	for key, value := range fake.invocations {
		copiedInvocations[key] = value
	}
	return copiedInvocations
}

func (fake *FakeRadarSchedulerFactory) recordInvocation(key string, args []interface{}) {
	fake.invocationsMutex.Lock()
	defer fake.invocationsMutex.Unlock()
	if fake.invocations == nil {
		fake.invocations = map[string][][]interface{}{}
	}
	if fake.invocations[key] == nil {
		fake.invocations[key] = [][]interface{}{}
	}
	fake.invocations[key] = append(fake.invocations[key], args)
}

var _ pipelines.RadarSchedulerFactory = new(FakeRadarSchedulerFactory)
