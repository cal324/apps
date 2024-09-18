$descs["argowf"] = "Argo Workflows"

verbose(false)

namespace :argowf do
  task :create, ["name"] do
    sh <<-SHELL

    kustomize build base/argoworkflow/ | kubectl apply -f -
    sleep 5
    kubectl apply -f base/argoworkflow/template.yaml
    kubectl apply -f base/argoworkflow/dash-mini.yaml

    SHELL
  end

  task :delete do
    sh <<-SHELL

    kustomize build base/argoworkflow/ | kubectl delete -f -

    SHELL
  end
end
Rake.application["argowf:create"].comment = "Creates a Argo Workflows"
Rake.application["argowf:delete"].comment = "Deletes a Argo Workflows"
