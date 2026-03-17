# Завдання

Завдання передбачає наступне:

1. Перевірити готовність всіх компонентів на основі створеної інфраструктури.
2. Зібрати всі модулі Terraform та перевірити коректність їх налаштування.
3. Запустити розгортання за допомогою команди `terraform apply`.
4. Переконатися в доступності основних сервісів через порт-форвардинг.
5. Продемонструвати роботу CI/CD за допомогою Jenkins та Argo CD.
6. Перевірити моніторинг за допомогою Grafana та Prometheus.

# Структура проєкту

Інфраструктура складається з наступних Terraform-модулів:

- **s3-backend** — S3-бакет та DynamoDB для зберігання Terraform state.
- **vpc** — VPC з 3 публічними та 3 приватними підмережами в регіоні `eu-central-1`.
- **ecr** — Elastic Container Registry для зберігання Docker-образів застосунку.
- **eks** — EKS-кластер (`eks-cluster-demo`) з EBS CSI Driver.
- **jenkins** — Jenkins, розгорнутий на EKS через Helm.
- **argo_cd** — Argo CD для GitOps-деплойменту застосунку.
- **rds** — PostgreSQL (RDS) база даних з підтримкою Multi-AZ та можливістю переключення на Aurora.

Також є Helm-чарт `charts/django-app/` для деплою Django-застосунку на кластер. Образ застосунку береться з ECR.

Код самого застосунку (з Dockerfile та Jenkinsfile) винесено в окремий репозиторій: https://github.com/illarionovam/example-app.

# Підготовка та розгортання

## Крок 1: Розгортання S3 backend

Спочатку розгорнемо бакет для стейту. Для цього коментимо `backend.tf` та зайві модулі в `main.tf`. Запускаємо:

```
terraform init
terraform apply
```

## Крок 2: Розгортання основної інфраструктури

Тепер розкоменчуємо усе інше та запускаємо:

```
terraform init -reconfigure
terraform apply
```

Розгортання може виконуватися у 2 підходи через можливі проблеми з EBS CSI Driver. Спочатку створюємо усі модулі, окрім `jenkins` та `argo_cd` та без EBS CSI Driver, а в другий підхід додаємо їх.

## Крок 3: Ініціалізація kubectl

```
aws eks --region eu-central-1 update-kubeconfig --name eks-cluster-demo
```

## Крок 4: Запуск CI/CD пайплайну

Після того, як все створилося, заходимо в Jenkins та запускаємо джобу `seed-job`, після чого застосунок завантажиться в ECR, а Argo CD підхопить зміни й задеплоїть його на кластер.

## Крок 5: Встановлення моніторингу

Prometheus:

```
helm install prometheus prometheus-community/prometheus --namespace monitoring --create-namespace
```

Grafana:

```
helm install grafana grafana/grafana --namespace monitoring
```

# Переконатися в доступності основних сервісів через порт-форвардинг

```
kubectl port-forward svc/jenkins 8080:8080 -n jenkins
```

```
kubectl port-forward svc/argocd-server 8081:443 -n argocd
```

```
kubectl port-forward svc/prometheus-server 9090:80 -n monitoring
```

```
kubectl port-forward svc/grafana 3000:80 -n monitoring
```
