$descs["kind"] = "kind creates and manages local Kubernetes clusters using Docker container 'nodes'"

verbose(false)

namespace :kind do
  task :create, ["name"] do
    sh <<-SHELL
    
      unset KUBECONFIG
      kind create cluster --config=base/kind/kind_config.yaml
    
      if [ -e /.dockerenv ]; then
        sed -i 's@server: .*:@server: https://host.docker.internal:@' ~/.kube/config
        sed -i 's/certificate-authority-data: .*/insecure-skip-tls-verify: true/' ~/.kube/config
      fi

      kubectl cluster-info --context kind-kind

    SHELL
  end

  task :delete do
    sh <<-SHELL
      kind delete cluster
    SHELL
  end
end
Rake.application["kind:create"].comment = "Creates a local Kubernetes cluster"
Rake.application["kind:delete"].comment = "Deletes a cluster"
