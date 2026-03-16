# Завдання

Завдання передбачає наступне:

1. Перевірити готовність всіх компонентів на основі створеної інфраструктури.
2. Зібрати всі модулі Terraform та перевірити коректність їх налаштування.
3. Запустити розгортання за допомогою команди `terraform apply`.
4. Переконатися в доступності основних сервісів через порт-форвардинг.
5. Продемонструвати роботу CI/CD за допомогою Jenkins та Argo CD.
6. Перевірити моніторинг за допомогою Grafana та Prometheus.

# Підготовка

Так як більшість завдання вже було виконано у попередніх дз, а саме створення усіх компонентів та зібрання їх в `main.tf`, перейдемо одразу до пункту 3.

Також варто відмітити, що я винесла застосунок в окремий репозиторій, бо зазвичай в реальних проєктах інфраструктура не змішується з реальним кодом проєкту. Репозиторій застосунку з Dockerfile та Jenkinsfile: https://github.com/illarionovam/example-app.

Отже, починаємо з пункту 3. Спочатку розгорнемо наш бакет, для цього коментимо `backend.tf` та зайві модулі в `main.tf`. Запускаємо `terraform init` та `terraform apply`.

Тепер розкоменчуємо усе інше та запускаємо. `terraform init -reconfigure` та `terraform apply`. Я робила у 2 підходи, бо в мене якісь постійні проблеми з EBS CSI Driver. Тому спочатку створю усі модулі, окрім `jenkins` та `argo_cd` та без EBS CSI Driver, а в другий підхід докину їх.

Не забуваємо ініціалізувати kubectl: `aws eks --region eu-central-1 update-kubeconfig --name eks-cluster-demo`.

Після того, як все створилося, можемо піти в Jenkins та запустити джобу `seed-job`, після чого наш застосунок завантажитсья в ECR, а argo cd підходпить зміни й задеплоїть його на кластер.

Також не забуваємо, що в цьому завданні нам треба ще додати прометеус з графаною.

Отже, прометеус:

```
helm install prometheus prometheus-community/prometheus --namespace monitoring

Get the Prometheus server URL by running these commands in the same shell:
  export POD_NAME=$(kubectl get pods --namespace monitoring -l "app.kubernetes.io/name=prometheus,app.kubernetes.io/instance=prometheus" -o jsonpath="{.items[0].metadata.name}")
  kubectl --namespace monitoring port-forward $POD_NAME 9090
```

Графана:

```
helm install grafana grafana/grafana --namespace monitoring --create-namespace --set adminPassword=admin123

Get the Grafana URL to visit by running these commands in the same shell:
  export POD_NAME=$(kubectl get pods --namespace monitoring -l "app.kubernetes.io/name=grafana,app.kubernetes.io/instance=grafana" -o jsonpath="{.items[0].metadata.name}")
  kubectl --namespace monitoring port-forward $POD_NAME 3000
```

# Переконатися в доступності основних сервісів через порт-форвардинг.

```
kubectl port-forward svc/jenkins 8080:8080 -n jenkins

Forwarding from 127.0.0.1:8080 -> 8080
Forwarding from [::1]:8080 -> 8080
```

```
kubectl port-forward svc/argocd-server 8081:443 -n argocd

Forwarding from 127.0.0.1:8081 -> 443
Forwarding from [::1]:8081 -> 443
```

```
kubectl port-forward svc/grafana 3000:80 -n monitoring

Forwarding from 127.0.0.1:3000 -> 80
Forwarding from [::1]:3000 -> 80
```
