$descs["gitea"] = "Argo Workflows"

verbose(false)

namespace :gitea do
  task :create, ["name"] do
    sh <<-SHELL

    cd base/gitea/
    helmfile apply
    cd ../..
    kubectl wait po -n gitea -l app.kubernetes.io/name=gitea --for condition=Ready --timeout=300s
    kubectl apply -f base/gitea/create_gitea_repos.yaml

    SHELL
  end

  task :delete do
    sh <<-SHELL

    cd base/gitea/
    helmfile delete
    cd ../..

    SHELL
  end
end
Rake.application["gitea:create"].comment = "Creates a Argo Workflows"
Rake.application["gitea:delete"].comment = "Deletes a Argo Workflows"
