# ЗАДАНИЕ 4
dnf update -y
dnf install -y curl wget vim git

dnf remove -y podman-docker
dnf install -y dnf-plugins-core
dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
dnf install -y docker-ce docker-ce-cli containerd.io
systemctl enable --now docker

curl -LO "https://storage.googleapis.com/kubernetes-release/release/v1.31.0/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client

curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-latest.x86_64.rpm
rpm -ivh minikube-latest.x86_64.rpm
minikube version

minikube start --driver=docker --force

#Нужно создать файл и внести правки (правильное расположение ресурсов(как у меня в файле), containers - должен быть списком через '-')
kubectl create -f pod.yaml

kubectl run redis --image=redis:5.0
kubectl get pod redis -n default -o jsonpath=”{..image}” #вывод в логе

#Меняем  - image: redis:5.0 на 6.0
kubectl edit pod redis
kubectl get pod redis -n default -o jsonpath=”{..image}” #вывод в логе

kubectl logs redis #вывод в логе

# ЗАДАНИЕ 5
# cоздаем app-deployment.yaml
kubectl create -f app-deployment.yaml

kubectl get deployments #вывод в логе
kubectl get pods -l app=web #вывод в логе

#создаем web-service.yaml
kubectl apply -f web-service.yaml
kubectl get services #вывод в логе

kubectl port-forward svc/web-service 8080:80 #вывод в логе

curl http://localhost:8080 #вывод в логе

kubectl scale deployment web-app --replicas=5

kubectl get pods -l app=web

#Меняем в app-deployment.yaml тег образа
kubectl apply -f app-deployment.yaml
kubectl rollout status deployment/web-app

kubectl get pod web-app-685b6b67d-s7wgz -o jsonpath=”{..image}” #вывод в логе