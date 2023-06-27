while true
do
  result=$(kubectl get po -n monitoring monitoring-loki-0)
  if [ $? -eq 0 ]; then
    kubectl wait po -n monitoring monitoring-loki-0 --for condition=Ready --timeout=300s
    break
  fi
  sleep 5
  kubectl get apps -A
done

for i in istio istio-namespace istio-base istio-istiod istio-ingress istio-gateway
do
  kubectl wait app -n argocd $i --for=jsonpath='{status.health.status}'=Healthy
done
for i in monitoring monitoring-namespace monitoring-crd monitoring-prometheus monitoring-loki monitoring-virtualservice
do
  kubectl wait app -n argocd $i --for=jsonpath='{status.health.status}'=Healthy
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
