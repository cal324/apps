$descs["k6"] = "k6 is a modern load-testing tool"

verbose(false)

namespace :k6 do
  task :create, ["name"] do
    sh <<-SHELL

    kustomize build base/k6/ | kubectl apply -f -

    SHELL
  end

  task :delete do
    sh <<-SHELL

    kustomize build base/k6/ | kubectl delete -f -

    SHELL
  end
end
Rake.application["k6:create"].comment = "Creates a k6"
Rake.application["k6:delete"].comment = "Deletes a k6"
