
$descs['development'] = "Create a development environment"
$configs['development'] = {
  name: 'development',
  deployment: 'development',
  targetrevision: 'develop',
  repourl: 'https://github.com/cal324/apps.git',
  values_targetrevision: 'develop',
  values_repourl: 'https://github.com/cal324/apps.git',
}

namespace :development do
  task :deploy => [:"kind:create", :"argocd:create", :"istio:apply", :wave1, :wave2, :wave3, :"argowf:create", :"k6:create"]
  multitask :wave1 => [:"tracing:apply", :"monitoring:apply", :"log-analytics:apply"]
  multitask :wave2 => [:"logging:apply", :"kafka:apply"]
  multitask :wave3 => [:"dummy-nginx:apply", :"kafka-discard:apply"]
  task :delete => [:"kind:delete"]
end

Rake.application["development:wave1"].comment = "create wave1"
Rake.application["development:wave2"].comment = "create wave2"
Rake.application["development:wave3"].comment = "create wave3"
Rake.application["development:deploy"].comment = "Create a development environment"
Rake.application["development:delete"].comment = "Delete a development environment"

