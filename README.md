# Airship Yaml Sigs

This documentation project outlines a reference architecture for automated

###  Building Kustomize

```bash
prompt$ git clone -b allinone https://github.com/keleustes/kustomize.git
Cloning into 'kustomize'...
remote: Enumerating objects: 66, done.
remote: Counting objects: 100% (66/66), done.
remote: Compressing objects: 100% (45/45), done.
remote: Total 22735 (delta 33), reused 41 (delta 20), pack-reused 22669
Receiving objects: 100% (22735/22735), 24.58 MiB | 1.82 MiB/s, done.
Resolving deltas: 100% (11314/11314), done.
Checking connectivity... done.

prompt$ cd kustomize/
prompt$ GO111MODULE=on go build -o $HOMEbin/kustomize cmd/kustomize/main.go
```

###  Testing Rendering

###  Simple Site Deployment

```bash
mkdir -p actual/simple
rm -f actual/simple/*
kustomize build site/simple -o actual/simple
```

or if kubectl is pointing at an active kubernetes cluster


```bash
make deploy-simple
make purge-simple
```

###  Custom Site Deployment

```bash
mkdir -p actual/custom
rm -f actual/custom/*
kustomize build site/custom -o actual/custom
```

or if kubectl is pointing at an active kubernetes cluster

```bash
make deploy-custom
make purge-custom
```

###  Complex Site Deployment

```bash
mkdir -p actual/complex
rm -f actual/complex/*
kustomize build site/complex -o actual/complex
```

or if kubectl is pointing at an active kubernetes cluster

```bash
make deploy-complex
make purge-complex
```

### Deployment tests

To install armada-operator (one per namespace):

```bash
make install-operators
```

To access the logs:

```bash
kubectl get pods --all-namespaces | grep operator | awk '{print "kubectl logs -n "$1" "$2"> "$1".log"}'  > doIt
chmod u+x doIt
./doIt
```

To purge armada-operator (one per namespace):

```bash
make purge-operators
```
