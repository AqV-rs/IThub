Развернуть инфраструктуру при помощи main.tf / variables.tf / vkcs_provider.tf
```
terraform apply  
```

![img_1.png](img_1.png)

Далее на control-node прокидываем ключ, который используем, для ssh доступа

После клонируем git репозиторий и прокатываем роль

```
 ansible-playbook playbook.yaml -i full.ini
```

![img.png](img.png)