# Test CRD Register openshift-api


This folder the openshift-api Kustomize CRD Register

## Setup the workspace

First, define a place to work:

<!-- @makeWorkplace @test -->
```bash
DEMO_HOME=$(mktemp -d)
```

## Preparation

<!-- @makeDirectories @test -->
```bash
mkdir -p ${DEMO_HOME}/
mkdir -p ${DEMO_HOME}/base
mkdir -p ${DEMO_HOME}/base/crd
mkdir -p ${DEMO_HOME}/overlay
```

### Preparation Step KustomizationFile0

<!-- @createKustomizationFile0 @test -->
```bash
cat <<'EOF' >${DEMO_HOME}/base/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- ./001-image-stream.yaml

# transformers:
# - ./transformer.yaml

crds:
- ./crd/imagestream.json
EOF
```


### Preparation Step KustomizationFile1

<!-- @createKustomizationFile1 @test -->
```bash
cat <<'EOF' >${DEMO_HOME}/overlay/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: test-namespace-name
namePrefix: test-

resources:
- ../base

patchesStrategicMerge:
- ./001-image-stream.yaml
EOF
```


### Preparation Step Resource0

<!-- @createResource0 @test -->
```bash
cat <<'EOF' >${DEMO_HOME}/base/001-image-stream.yaml
apiVersion: image.openshift.io/v1
kind: ImageStream
metadata:
  labels:
    app: app
  name: image-name
spec:
  lookupPolicy:
    local: false
  tags:
    - from:
        kind: DockerImage
        name: $(TO_BE_REPLACE) 
      name: image-name
      referencePolicy:
        type: Source

EOF
```


### Preparation Step Resource1

<!-- @createResource1 @test -->
```bash
cat <<'EOF' >${DEMO_HOME}/base/transformer.yaml
apiVersion: api.openshift.io/v1
kind: OpenShiftCRDRegister
metadata:
  name: openshiftcrdregister
EOF
```


### Preparation Step Resource2

<!-- @createResource2 @test -->
```bash
cat <<'EOF' >${DEMO_HOME}/overlay/001-image-stream.yaml
apiVersion: image.openshift.io/v1
kind: ImageStream
metadata:
  name: image-name
spec:
  tags:
    - name: image-name
      from:
        name: docker.io/hello-world
EOF
```


### Preparation Step Other0

<!-- @createOther0 @test -->
```bash
cat <<'EOF' >${DEMO_HOME}/base/crd/imagestream.json
{
  "github.com/openshift/api/image/v1.ImageStream": {
    "Schema": {
      "description": "ImageStream stores a mapping of tags to images, metadata overrides that are applied when images are tagged in a stream, and an optional reference to a container image repository on a registry.",
      "properties": {
        "apiVersion": {
          "description": "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/api-conventions.md#resources",
          "type": "string"
        },
        "kind": {
          "description": "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/api-conventions.md#types-kinds",
          "type": "string"
        },
        "metadata": {
          "description": "Standard object's metadata.",
          "$ref": "k8s.io/apimachinery/pkg/apis/meta/v1.ObjectMeta"
        },
        "spec": {
          "description": "Spec describes the desired state of this stream",
          "$ref": "github.com/openshift/api/image/v1.ImageStreamSpec"
        },
        "status": {
          "description": "Status describes the current state of this stream",
          "$ref": "github.com/openshift/api/image/v1.ImageStreamStatus"
        }
      }
    },
    "x-kubernetes-group-version-kind": [
      {
        "group": "",
        "kind": "ImageStream",
        "version": "v1"
      },
      {
        "group": "image.openshift.io",
        "kind": "ImageStream",
        "version": "v1"
      }
    ]
  },
  "github.com/openshift/api/image/v1.ImageStreamSpec": {
    "Schema": {
      "description": "ImageStreamSpec represents options for ImageStreams.",
      "properties": {
        "dockerImageRepository": {
          "description": "dockerImageRepository is optional, if specified this stream is backed by a container repository on this server Deprecated: This field is deprecated as of v3.7 and will be removed in a future release. Specify the source for the tags to be imported in each tag via the spec.tags.from reference instead.",
          "type": "string"
        },
        "lookupPolicy": {
          "description": "lookupPolicy controls how other resources reference images within this namespace.",
          "$ref": "github.com/openshift/api/image/v1.ImageLookupPolicy"
        },
        "tags": {
          "description": "tags map arbitrary string values to specific image locators",
          "type": "array",
          "items": {
            "$ref": "github.com/openshift/api/image/v1.TagReference"
          },
          "x-kubernetes-patch-merge-key": "name",
          "x-kubernetes-patch-strategy": "merge"
        }
      }
    }
  },
  "github.com/openshift/api/image/v1.ImageStreamStatus": {
    "Schema": {
      "description": "ImageStreamStatus contains information about the state of this image stream.",
      "required": [
        "dockerImageRepository"
      ],
      "properties": {
        "dockerImageRepository": {
          "description": "DockerImageRepository represents the effective location this stream may be accessed at. May be empty until the server determines where the repository is located",
          "type": "string"
        },
        "publicDockerImageRepository": {
          "description": "PublicDockerImageRepository represents the public location from where the image can be pulled outside the cluster. This field may be empty if the administrator has not exposed the integrated registry externally.",
          "type": "string"
        },
        "tags": {
          "description": "Tags are a historical record of images associated with each tag. The first entry in the TagEvent array is the currently tagged image.",
          "type": "array",
          "items": {
            "$ref": "github.com/openshift/api/image/v1.NamedTagEventList"
          },
          "x-kubernetes-patch-merge-key": "tag",
          "x-kubernetes-patch-strategy": "merge"
        }
      }
    }
  },
  "github.com/openshift/api/image/v1.ImageLookupPolicy": {
    "Schema": {
      "description": "ImageLookupPolicy describes how an image stream can be used to override the image references used by pods, builds, and other resources in a namespace.",
      "required": [
        "local"
      ],
      "properties": {
        "local": {
          "description": "local will change the docker short image references (like \"mysql\" or \"php:latest\") on objects in this namespace to the image ID whenever they match this image stream, instead of reaching out to a remote registry. The name will be fully qualified to an image ID if found. The tag's referencePolicy is taken into account on the replaced value. Only works within the current namespace.",
          "type": "boolean"
        }
      }
    }
  },
  "github.com/openshift/api/image/v1.TagReference": {
    "Schema": {
      "description": "TagReference specifies optional annotations for images using this tag and an optional reference to an ImageStreamTag, ImageStreamImage, or DockerImage this tag should track.",
      "required": [
        "name"
      ],
      "properties": {
        "annotations": {
          "description": "Optional; if specified, annotations that are applied to images retrieved via ImageStreamTags.",
          "type": "object",
          "additionalProperties": {
            "type": "string"
          }
        },
        "from": {
          "description": "Optional; if specified, a reference to another image that this tag should point to. Valid values are ImageStreamTag, ImageStreamImage, and DockerImage.  ImageStreamTag references can only reference a tag within this same ImageStream.",
          "$ref": "k8s.io/api/core/v1.ObjectReference"
        },
        "generation": {
          "description": "Generation is a counter that tracks mutations to the spec tag (user intent). When a tag reference is changed the generation is set to match the current stream generation (which is incremented every time spec is changed). Other processes in the system like the image importer observe that the generation of spec tag is newer than the generation recorded in the status and use that as a trigger to import the newest remote tag. To trigger a new import, clients may set this value to zero which will reset the generation to the latest stream generation. Legacy clients will send this value as nil which will be merged with the current tag generation.",
          "type": "integer",
          "format": "int64"
        },
        "importPolicy": {
          "description": "ImportPolicy is information that controls how images may be imported by the server.",
          "$ref": "github.com/openshift/api/image/v1.TagImportPolicy"
        },
        "name": {
          "description": "Name of the tag",
          "type": "string"
        },
        "reference": {
          "description": "Reference states if the tag will be imported. Default value is false, which means the tag will be imported.",
          "type": "boolean"
        },
        "referencePolicy": {
          "description": "ReferencePolicy defines how other components should consume the image.",
          "$ref": "github.com/openshift/api/image/v1.TagReferencePolicy"
        }
      }
    }
  },
  "github.com/openshift/api/image/v1.NamedTagEventList": {
    "Schema": {
      "description": "NamedTagEventList relates a tag to its image history.",
      "required": [
        "tag",
        "items"
      ],
      "properties": {
        "conditions": {
          "description": "Conditions is an array of conditions that apply to the tag event list.",
          "type": "array",
          "items": {
            "$ref": "github.com/openshift/api/image/v1.TagEventCondition"
          }
        },
        "items": {
          "description": "Standard object's metadata.",
          "type": "array",
          "items": {
            "$ref": "github.com/openshift/api/image/v1.TagEvent"
          }
        },
        "tag": {
          "description": "Tag is the tag for which the history is recorded",
          "type": "string"
        }
      }
    }
  },
  "github.com/openshift/api/image/v1.TagImportPolicy": {
    "Schema": {
      "description": "TagImportPolicy controls how images related to this tag will be imported.",
      "properties": {
        "insecure": {
          "description": "Insecure is true if the server may bypass certificate verification or connect directly over HTTP during image import.",
          "type": "boolean"
        },
        "scheduled": {
          "description": "Scheduled indicates to the server that this tag should be periodically checked to ensure it is up to date, and imported",
          "type": "boolean"
        }
      }
    }
  },
  "github.com/openshift/api/image/v1.TagReferencePolicy": {
    "Schema": {
      "description": "TagReferencePolicy describes how pull-specs for images in this image stream tag are generated when image change triggers in deployment configs or builds are resolved. This allows the image stream author to control how images are accessed.",
      "required": [
        "type"
      ],
      "properties": {
        "type": {
          "description": "Type determines how the image pull spec should be transformed when the image stream tag is used in deployment config triggers or new builds. The default value is `Source`, indicating the original location of the image should be used (if imported). The user may also specify `Local`, indicating that the pull spec should point to the integrated container image registry and leverage the registry's ability to proxy the pull to an upstream registry. `Local` allows the credentials used to pull this image to be managed from the image stream's namespace, so others on the platform can access a remote image but have no access to the remote secret. It also allows the image layers to be mirrored into the local registry which the images can still be pulled even if the upstream registry is unavailable.",
          "type": "string"
        }
      }
    }
  },
  "github.com/openshift/api/image/v1.TagEventCondition": {
    "Schema": {
      "description": "TagEventCondition contains condition information for a tag event.",
      "required": [
        "type",
        "status",
        "generation"
      ],
      "properties": {
        "generation": {
          "description": "Generation is the spec tag generation that this status corresponds to",
          "type": "integer",
          "format": "int64"
        },
        "lastTransitionTime": {
          "description": "LastTransitionTIme is the time the condition transitioned from one status to another.",
          "$ref": "k8s.io/apimachinery/pkg/apis/meta/v1.Time"
        },
        "message": {
          "description": "Message is a human readable description of the details about last transition, complementing reason.",
          "type": "string"
        },
        "reason": {
          "description": "Reason is a brief machine readable explanation for the condition's last transition.",
          "type": "string"
        },
        "status": {
          "description": "Status of the condition, one of True, False, Unknown.",
          "type": "string"
        },
        "type": {
          "description": "Type of tag event condition, currently only ImportSuccess",
          "type": "string"
        }
      }
    }
  },
  "github.com/openshift/api/image/v1.TagEvent": {
    "Schema": {
      "description": "TagEvent is used by ImageStreamStatus to keep a historical record of images associated with a tag.",
      "required": [
        "created",
        "dockerImageReference",
        "image",
        "generation"
      ],
      "properties": {
        "created": {
          "description": "Created holds the time the TagEvent was created",
          "$ref": "k8s.io/apimachinery/pkg/apis/meta/v1.Time"
        },
        "dockerImageReference": {
          "description": "DockerImageReference is the string that can be used to pull this image",
          "type": "string"
        },
        "generation": {
          "description": "Generation is the spec tag generation that resulted in this tag being updated",
          "type": "integer",
          "format": "int64"
        },
        "image": {
          "description": "Image is the image",
          "type": "string"
        }
      }
    }
  }
}
EOF
```

## Execution

<!-- @build @test -->
```bash
mkdir ${DEMO_HOME}/actual
airshipctl document build ${DEMO_HOME}/overlay -o ${DEMO_HOME}/actual
```

## Verification

<!-- @createExpectedDir @test -->
```bash
mkdir ${DEMO_HOME}/expected
```


### Verification Step Expected0

<!-- @createExpected0 @test -->
```bash
cat <<'EOF' >${DEMO_HOME}/expected/image.openshift.io_v1_imagestream_test-image-name.yaml
apiVersion: image.openshift.io/v1
kind: ImageStream
metadata:
  labels:
    app: app
  name: test-image-name
  namespace: test-namespace-name
spec:
  lookupPolicy:
    local: false
  tags:
  - from:
      kind: DockerImage
      name: docker.io/hello-world
    name: image-name
    referencePolicy:
      type: Source
EOF
```


<!-- @compareActualToExpected @test -->
```bash
test 0 == \
$(diff -r $DEMO_HOME/actual $DEMO_HOME/expected | wc -l); \
echo $?
```

