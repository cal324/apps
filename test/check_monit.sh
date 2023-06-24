while true
do
  result=$(kubectl get po -n monitoring monitoring-loki-0)
  if [ $? -eq 0 ]; then
    kubectl wait po -n monitoring monitoring-loki-0 --for condition=Ready --timeout=300s
    break
  fi
  sleep 5
done

