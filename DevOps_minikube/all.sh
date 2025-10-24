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

#Нужно создать файл и внести правки (правильное расположение ресурсов(как у меня в файле), указать порт)
kubectl create -f pod.yaml

kubectl run redis --image=redis:5.0
kubectl get pod redis -n default -o jsonpath=”{..image}”

#Меняем  - image: redis:5.0 на 6.0
kubectl edit pod redis
kubectl get pod redis -n default -o jsonpath=”{..image}”

kubectl logs redis