# Copyright 2017 AT&T Intellectual Property.  All other rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

.PHONY: all
all: docs

.PHONY: clean
clean:
	rm -rf doc/build

.PHONY: docs
docs: clean build_docs

.PHONY: build_docs
build_docs:
	tox -e docs

# Directories.
GOPATH              := ${GOPATH}
BINDIR              := bin
TOOLS_DIR           := tools
TOOLS_BINDIR        := $(TOOLS_DIR)/bin

# Binaries.
KIND                := $(TOOLS_BINDIR)/kind
KUBEVAL             := $(TOOLS_BINDIR)/kubeval
KUBEBUILDER         := $(TOOLS_BINDIR)/kubebuilder
AIRSHIPCTL          := $(TOOLS_BINDIR)/airshipctl

## --------------------------------------
## Tooling Binaries
## --------------------------------------

$(KIND): $(TOOLS_DIR)/go.mod # Build kind from tools folder.
	cd $(TOOLS_DIR); go build -tags=tools -o $(BINDIR)/kind sigs.k8s.io/kind

$(KUBEVAL): $(TOOLS_DIR)/go.mod # Build kubeval from tools folder.
	cd $(TOOLS_DIR); go build -tags=tools -o $(BINDIR)/kubeval github.com/instrumenta/kubeval

$(AIRSHIPCTL): $(TOOLS_DIR)/go.mod # Build kubeval from tools folder.
	cd $(TOOLS_DIR); go build -tags=tools -o $(BINDIR)/airshipctl opendev.org/airship/airshipctl

$(KUBEBUILDER): $(TOOLS_DIR)/go.mod
	cd $(TOOLS_DIR); ./install_kubebuilder.sh

.PHONY: install-tools
install-tools: $(KIND) $(KUBEVAL) $(KUBEBUILDER) $(AIRSHIPCTL)

## --------------------------------------
## Testing
## --------------------------------------

clusterexist=$(shell kind get clusters | grep airshipyaml  | wc -l)
ifeq ($(clusterexist), 1)
  testcluster=$(shell kind get kubeconfig-path --name="airshipyaml")
  SETKUBECONFIG=KUBECONFIG=$(testcluster)
else
  SETKUBECONFIG=
endif

KUSTOMIZEBUILD=$(AIRSHIPCTL) document build

.PHONY: which-cluster
which-cluster:
	echo $(SETKUBECONFIG)

.PHONY: create-testcluster
create-testcluster:
	$(KIND) create cluster --name airshipyaml

.PHONY: delete-testcluster
delete-testcluster:
	$(KIND) delete cluster --name airshipyaml

# Merged from POC
install:
	$(SETKUBECONFIG) kubectl label nodes --all openstack-control-plane=enabled --overwrite
	$(SETKUBECONFIG) kubectl label nodes --all ucp-control-plane=enabled --overwrite
	$(SETKUBECONFIG) kubectl label nodes --all ceph-mds=enabled --overwrite
	$(SETKUBECONFIG) kubectl label nodes --all ceph-mgr=enabled --overwrite
	$(SETKUBECONFIG) kubectl label nodes --all ceph-mon=enabled --overwrite
	$(SETKUBECONFIG) kubectl label nodes --all ceph-rgw=enabled --overwrite
	$(SETKUBECONFIG) kubectl apply -f ./deploy/namespaces
	$(SETKUBECONFIG) $(KUSTOMIZEBUILD) ./components/cabpk/crds | kubectl apply -f -
	$(SETKUBECONFIG) $(KUSTOMIZEBUILD) ./components/capi/crds | kubectl apply -f -
	$(SETKUBECONFIG) $(KUSTOMIZEBUILD) ./components/pegleg/crds | kubectl apply -f -
	$(SETKUBECONFIG) $(KUSTOMIZEBUILD) ./components/armada/crds | kubectl apply -f -
	$(SETKUBECONFIG) $(KUSTOMIZEBUILD) ./components/shipyard/crds | kubectl apply -f -
	$(SETKUBECONFIG) $(KUSTOMIZEBUILD) ./components/deckhand/crds | kubectl apply -f -
	$(SETKUBECONFIG) $(KUSTOMIZEBUILD) ./components/promenade/crds | kubectl apply -f -
	$(SETKUBECONFIG) $(KUSTOMIZEBUILD) ./components/drydock/crds | kubectl apply -f -
	$(SETKUBECONFIG) $(KUSTOMIZEBUILD) ./components/airshipctl/crds | kubectl apply -f -
	$(SETKUBECONFIG) kubectl apply -f ./deploy/cluster/cluster_role.yaml
	$(SETKUBECONFIG) kubectl apply -f ./deploy/cluster/cluster_role_binding.yaml

install-operators: install
	$(SETKUBECONFIG) $(KUSTOMIZEBUILD) ./components/armada/overlays/ceph/ | kubectl apply -f -
	$(SETKUBECONFIG) $(KUSTOMIZEBUILD) ./components/armada/overlays/nfs/ | kubectl apply -f -
	$(SETKUBECONFIG) $(KUSTOMIZEBUILD) ./components/armada/overlays/openstack/ | kubectl apply -f -
	$(SETKUBECONFIG) $(KUSTOMIZEBUILD) ./components/armada/overlays/osh-infra/ | kubectl apply -f -
	$(SETKUBECONFIG) $(KUSTOMIZEBUILD) ./components/armada/overlays/tenant-ceph/ | kubectl apply -f -
	$(SETKUBECONFIG) $(KUSTOMIZEBUILD) ./components/armada/overlays/ucp/ | kubectl apply -f -

purge-operators:
	$(SETKUBECONFIG) $(KUSTOMIZEBUILD) ./components/armada/overlays/ceph/ | kubectl delete --ignore-not-found=true -f -
	$(SETKUBECONFIG) $(KUSTOMIZEBUILD) ./components/armada/overlays/nfs/ | kubectl delete --ignore-not-found=true -f -
	$(SETKUBECONFIG) $(KUSTOMIZEBUILD) ./components/armada/overlays/openstack/ | kubectl delete --ignore-not-found=true -f -
	$(SETKUBECONFIG) $(KUSTOMIZEBUILD) ./components/armada/overlays/osh-infra/ | kubectl delete --ignore-not-found=true -f -
	$(SETKUBECONFIG) $(KUSTOMIZEBUILD) ./components/armada/overlays/tenant-ceph/ | kubectl delete --ignore-not-found=true -f -
	$(SETKUBECONFIG) $(KUSTOMIZEBUILD) ./components/armada/overlays/ucp/ | kubectl delete --ignore-not-found=true -f -

purge: purge-operators
	$(SETKUBECONFIG) kubectl delete -f ./deploy/cluster/cluster_role_binding.yaml --ignore-not-found=true
	$(SETKUBECONFIG) kubectl delete -f ./deploy/cluster/cluster_role.yaml --ignore-not-found=true
	$(SETKUBECONFIG) $(KUSTOMIZEBUILD) ./components/cabpk/crds | kubectl delete -f -
	$(SETKUBECONFIG) $(KUSTOMIZEBUILD) ./components/capi/crds | kubectl delete -f -
	$(SETKUBECONFIG) $(KUSTOMIZEBUILD) ./components/pegleg/crds | kubectl delete -f -
	$(SETKUBECONFIG) $(KUSTOMIZEBUILD) ./components/armada/crds | kubectl delete -f -
	$(SETKUBECONFIG) $(KUSTOMIZEBUILD) ./components/shipyard/crds | kubectl delete -f -
	$(SETKUBECONFIG) $(KUSTOMIZEBUILD) ./components/deckhand/crds | kubectl delete -f -
	$(SETKUBECONFIG) $(KUSTOMIZEBUILD) ./components/promenade/crds | kubectl delete -f -
	$(SETKUBECONFIG) $(KUSTOMIZEBUILD) ./components/drydock/crds | kubectl delete -f -
	$(SETKUBECONFIG) $(KUSTOMIZEBUILD) ./components/airshipctl/crds | kubectl delete -f -
	$(SETKUBECONFIG) kubectl delete -f ./deploy/namespaces --ignore-not-found=true

rendering-test-simple:
	rm -fr actual/simple
	mkdir -p actual/simple
	$(KUSTOMIZEBUILD) site/simple -o actual/simple
	# cp actual/simple/* ./unittests/rendering/simple
	diff -r actual/simple ./unittests/rendering/simple

deploy-simple: install
	rm -fr actual/simple
	mkdir -p actual/simple
	$(KUSTOMIZEBUILD) site/simple -o actual/simple
	$(SETKUBECONFIG) kubectl apply -f actual/simple

purge-simple: 
	$(SETKUBECONFIG) kubectl delete -f actual/simple

rendering-test-complex:
	rm -fr actual/complex
	mkdir -p actual/complex
	$(KUSTOMIZEBUILD) site/complex -o actual/complex
	# cp actual/complex/* ./unittests/rendering/complex
	diff -r actual/complex ./unittests/rendering/complex

deploy-complex: install
	rm -fr actual/complex
	mkdir -p actual/complex
	$(KUSTOMIZEBUILD) site/complex -o actual/complex
	$(SETKUBECONFIG) kubectl apply -f actual/complex

purge-complex: 
	$(SETKUBECONFIG) kubectl delete -f actual/complex

rendering-test-custom:
	rm -fr actual/custom
	mkdir -p actual/custom
	$(KUSTOMIZEBUILD) site/custom -o actual/custom
	# cp actual/custom/* ./unittests/rendering/custom
	diff -r actual/custom ./unittests/rendering/custom

deploy-custom: install
	rm -fr actual/custom
	mkdir -p actual/custom
	$(KUSTOMIZEBUILD) site/custom -o actual/custom
	$(SETKUBECONFIG) kubectl apply -f actual/custom

purge-custom: 
	$(SETKUBECONFIG) kubectl delete -f actual/custom

rendering-test-metal3:
	rm -fr actual/metal3
	mkdir -p actual/metal3
	# $(KUSTOMIZEBUILD) site/metal3 -o actual/metal3
	site/metal3/generate.sh
	# cp actual/metal3/* ./unittests/rendering/metal3
	diff -r actual/metal3 ./unittests/rendering/metal3

smp-merge-tests:
	cd unittests/smp-merge/ && ./crdRegisterTests.sh

rendering-tests: install-tools rendering-test-simple rendering-test-complex rendering-test-custom rendering-test-metal3 smp-merge-tests

.PHONY: kubeval-strict
kubeval-strict:
	$(KUBEVAL) actual/simple/ucp_armada.airshipit.org_v1alpha1_armadachart_ucp-shipyard.yaml --openshift --schema-location file:///$(HOME)/src/github.com/keleustes/armada-crd/kubeval --strict

.PHONY: kubeval-remote
kubeval-remote:
	$(KUBEVAL) actual/simple/ucp_armada.airshipit.org_v1alpha1_armadachart_ucp-shipyard.yaml --openshift --schema-location https://raw.githubusercontent.com/keleustes/armada-crd/master/kubeval 

.PHONY: kubeval-simple
kubeval-simple: rendering-test-simple
	@for f in $(shell ls ./actual/simple/*armadachart*); do \
		$(KUBEVAL) $${f} --schema-location file://$${GOPATH}/src/github.com/keleustes/armada-crd/kubeval --strict; \
	done || true

.PHONY: kubeval-custom
kubeval-custom: rendering-test-custom
	@for f in $(shell ls ./actual/custom/*armadachart*); do \
		$(KUBEVAL) $${f} --schema-location file://$${GOPATH}/src/github.com/keleustes/armada-crd/kubeval --strict; \
	done || true

.PHONY: kubeval-complex
kubeval-complex: rendering-test-complex
	@for f in $(shell ls ./actual/complex/*armadachart*); do \
		$(KUBEVAL) $${f} --schema-location file://$${GOPATH}/src/github.com/keleustes/armada-crd/kubeval --strict; \
	done || true

.PHONY: kubeval-checks
kubeval-checks: kubeval-simple kubeval-custom kubeval-complex


