
$descs['test'] = "Create a test environment"
$configs['test'] = {
  name: 'test',
  deployment: 'test',
  targetrevision: 'develop',
  repourl: 'https://github.com/cal324/apps.git',
  values_targetrevision: 'develop',
  values_repourl: 'https://github.com/cal324/apps.git',
}

namespace :test do
  task :deploy => [:"kind:create", :"argocd:create", :"istio:apply", :wave1, :wave2]
  multitask :wave1 => [:"tracing:apply", :"monitoring:apply", :"log-analytics:apply"]
  multitask :wave2 => [:"logging:apply"]
  task :delete => [:"kind:delete"]
end

Rake.application["test:wave1"].comment = "create wave1"
Rake.application["test:wave2"].comment = "create wave2"
Rake.application["test:deploy"].comment = "Create a test environment"
Rake.application["test:delete"].comment = "Delete a test environment"

