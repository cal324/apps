while true
do
  result=$(kubectl wait app -n argocd fluent-aggregator-fluentbit --for=jsonpath='{status.health.status}'=Healthy)
  if [ $? -eq 0 ]; then
    break
  fi
  sleep 5
  kubectl get apps -A
done

for i in fluent-aggregator fluent-aggregator-dummy fluent-aggregator-namespace fluent-aggregator-fluentd
do
  kubectl wait app -n argocd $i --for=jsonpath='{status.health.status}'=Healthy 
done

echo "kubectl get po -A"
kubectl get po -A
echo "kubectl get app -A"
kubectl get app -A
echo "kubectl get svc -A"
kubectl get svc -A
echo "kubectl get ep -A"
kubectl get ep -A
echo "kubectl get pv -A"
kubectl get pv -A
