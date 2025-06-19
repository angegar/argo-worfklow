
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
    minikube start
    # minikube addons enable ingress
    kubectl config set-context --current --namespace={{ namespace }}

deploy: deploy-workflow deploy-events

deploy-workflow:
    #!/bin/bash
    ARGO_WORKFLOWS_VERSION="v3.6.10"

    kubectl create namespace {{ namespace }}
    kubectl apply -n {{ namespace }} -f "https://github.com/argoproj/argo-workflows/releases/download/${ARGO_WORKFLOWS_VERSION}/quick-start-minimal.yaml"
  
  
deploy-events:
    #!/bin/bash
    kubectl create namespace {{ namespace }}-events
    kubectl apply -n {{ namespace }}-events -f https://raw.githubusercontent.com/argoproj/argo-events/stable/manifests/install.yaml
    kubectl apply -n {{ namespace }}-events -f https://raw.githubusercontent.com/argoproj/argo-events/stable/manifests/install-validating-webhook.yaml

    # kubectl apply -n {{ namespace }}-events -f https://raw.githubusercontent.com/argoproj/argo-events/stable/examples/eventbus/native.yaml
    # kubectl apply -n {{ namespace }}-events -f https://raw.githubusercontent.com/argoproj/argo-events/stable/examples/event-sources/webhook.yaml
    # kubectl apply -n {{ namespace }}-events -f https://raw.githubusercontent.com/argoproj/argo-events/master/examples/rbac/sensor-rbac.yaml
    # kubectl apply -n {{ namespace }}-events -f https://raw.githubusercontent.com/argoproj/argo-events/master/examples/rbac/workflow-rbac.yaml
    # kubectl apply -n {{ namespace }}-events -f https://raw.githubusercontent.com/argoproj/argo-events/stable/examples/sensors/webhook.yaml

create-wf-tpl:
    kubectl apply -f workflows/workflow-tpl.yaml

port-forward-event: 
    kubectl -n {{ namespace }}-events port-forward service/webhook-eventsource-svc 12000:12000

port-forward:
    kubectl -n {{ namespace }} port-forward service/argo-server 2746:2746

run +workflow_name='hello-world.yaml':
    argo submit -n argo --watch workflows/{{workflow_name}}

send-query:
    curl -k https://127.0.0.1:2746/api/v1/events/argo/create-team -d '{"message": "superTeam"}'

# Path the argo-server to use a nodeport instead of a cluster IP
patch:
    kubectl patch -n {{ namespace }} service argo-server -p '{"spec": {"type": "LoadBalancer"}}'
