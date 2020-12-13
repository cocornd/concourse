package worker

import (
	"fmt"
	"time"

	"code.cloudfoundry.org/lager"
	"github.com/concourse/concourse/atc/compression"
	"github.com/concourse/concourse/atc/runtime"
)

//go:generate counterfeiter . ArtifactWirer

type ArtifactWirer interface {
	WireInputsAndCaches(logger lager.Logger, teamID int, inputMap map[string]runtime.Artifact) ([]InputSource, error)
	WireImage(logger lager.Logger, imageArtifact runtime.Artifact) (StreamableArtifactSource, error)
}

type artifactWirer struct {
	compression         compression.Compression
	volumeFinder        VolumeFinder
	enableP2PStreaming  bool
	p2pStreamingTimeout time.Duration
}

func NewArtifactWirer(
	compression compression.Compression,
	volumeFinder VolumeFinder,
	enableP2PStreaming bool,
	p2pStreamingTimeout time.Duration,
) ArtifactWirer {
	return artifactWirer{
		compression:         compression,
		volumeFinder:        volumeFinder,
		enableP2PStreaming:  enableP2PStreaming,
		p2pStreamingTimeout: p2pStreamingTimeout,
	}
}

func (w artifactWirer) WireInputsAndCaches(logger lager.Logger, teamID int, inputMap map[string]runtime.Artifact) ([]InputSource, error) {
	var inputs []InputSource
	for path, artifact := range inputMap {
		if cache, ok := artifact.(*runtime.CacheArtifact); ok {
			// task caches may not have a volume, it will be discovered on
			// the worker later. We do not stream task caches
			source := NewCacheArtifactSource(*cache)
			inputs = append(inputs, inputSource{source, path})
		} else {
			artifactVolume, found, err := w.volumeFinder.FindVolume(logger, teamID, artifact.ID())
			if err != nil {
				return nil, err
			}
			if !found {
				return nil, fmt.Errorf("volume not found for artifact id %v type %T", artifact.ID(), artifact)
			}

			source := NewStreamableArtifactSource(artifact, artifactVolume, w.compression, w.enableP2PStreaming, w.p2pStreamingTimeout)
			inputs = append(inputs, inputSource{source, path})
		}
	}

	return inputs, nil
}

func (w artifactWirer) WireImage(logger lager.Logger, imageArtifact runtime.Artifact) (StreamableArtifactSource, error) {
	artifactVolume, found, err := w.volumeFinder.FindVolume(logger, 0, imageArtifact.ID())
	if err != nil {
		return nil, err
	}
	if !found {
		return nil, fmt.Errorf("volume not found for artifact id %v type %T", imageArtifact.ID(), imageArtifact)
	}

	return NewStreamableArtifactSource(imageArtifact, artifactVolume, w.compression, w.enableP2PStreaming, w.p2pStreamingTimeout), nil
}
