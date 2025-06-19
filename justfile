
namespace := 'argo'


setup:
    #!/bin/bash
    
    # Detect OS
    ARGO_OS="darwin"
    if [[ "$(uname -s)" != "Darwin" ]]; then
    ARGO_OS="linux"
    fi

    # Download the binary
    curl -sLO "https://github.com/argoproj/argo-workflows/releases/download/v3.5.15/argo-$ARGO_OS-amd64.gz"

    # Unzip
    gunzip "argo-$ARGO_OS-amd64.gz"

    # Make binary executable
    chmod +x "argo-$ARGO_OS-amd64"

    # Move binary to path
    sudo mv "./argo-$ARGO_OS-amd64" /usr/local/bin/argo

    # Test installation
    argo version

start: setup
    # k3d cluster create laurent --port 8080:2746@loadbalancer
    minikube start
    # minikube addons enable ingress
    kubectl config set-context --current --namespace={{ namespace }}

deploy:
    #!/bin/bash
    ARGO_WORKFLOWS_VERSION="v3.6.10"

    kubectl create namespace {{ namespace }}
    kubectl apply -n {{ namespace }} -f "https://github.com/argoproj/argo-workflows/releases/download/${ARGO_WORKFLOWS_VERSION}/quick-start-minimal.yaml"
    just patch

port-forward:
    kubectl -n {{ namespace }} port-forward service/argo-server 2746:2746

run +workflow_name='hello-world.yaml':
    argo submit -n argo --watch workflows/{{workflow_name}}

# Path the argo-server to use a nodeport instead of a cluster IP
patch:
    kubectl patch -n {{ namespace }} service argo-server -p '{"spec": {"type": "LoadBalancer"}}'
