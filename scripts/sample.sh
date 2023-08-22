
for name in database fluent-aggregator istio monitoring rook tracing kafka
do
  erb name=$name revesion=develop kubernetes=kind sample_template.yaml > ~/apps/sample/$name.yaml
done
