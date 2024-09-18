$descs["argocd"] = "Argo CD server"

verbose(false)

namespace :argocd do
  task :create, ["name"] do
    sh <<-SHELL

    kustomize build base/argocd/ | kubectl apply -n argocd -f -
    kubectl wait po -n argocd -l app.kubernetes.io/name=argocd-server --for condition=Ready --timeout=300s
    kubectl wait po -n argocd -l app.kubernetes.io/name=argocd-dex-server --for condition=Ready --timeout=300s
    kubectl wait po -n argocd -l app.kubernetes.io/name=argocd-repo-server --for condition=Ready --timeout=300s

    export ARGO_SECRET=`kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d ; echo`
    export REPO=https://`git config -l | grep remote.origin.url | awk -F@ '{print $2}'`
    export USER=`git config -l | grep user.name | awk -F= '{print $2}'`
    export PASS=`git config -l | grep remote.origin.url | awk -F: '{print $3}' | awk -F@ '{print $1}'`
    export PROJECT=fleet

    if [ -e /.dockerenv ]; then
      argocd login host.docker.internal:30000 --username admin --password $ARGO_SECRET --insecure
    else
      argocd login 127.0.0.1:30000 --username admin --password $ARGO_SECRET --insecure
    fi

    argocd account update-password --account admin --new-password adminadmin --current-password $ARGO_SECRET

    argocd repo add $REPO --username $USER --password $PASS
    argocd proj create $PROJECT -s '*' -d '*,*'
    argocd proj allow-cluster-resource $PROJECT '*' '*'
    
    SHELL
  end

  task :delete do
    sh <<-SHELL

    kustomize build base/argocd/ | kubectl delete -n argocd -f -

    SHELL
  end
end
Rake.application["argocd:create"].comment = "Creates a Argo CD server"
Rake.application["argocd:delete"].comment = "Deletes a Argo CD server"
