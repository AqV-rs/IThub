Заполнить vkcs_provider.tf.example и выполнить 
```
cp vkcs_provider.tf.example vkcs_provider.tf
```

Выполнить init

```
terraform init
```

Развернуть инфраструктуру при помощи main.tf / variables.tf / vkcs_provider.tf
```
terraform apply  
```
<img width="944" height="165" alt="img_1" src="https://github.com/user-attachments/assets/36bd1e82-ede1-4bc7-838e-7e7041d223ce" />

Далее на control-node прокидываем ключ, который используем, для ssh доступа

После клонируем git репозиторий и прокатываем роль

```
 ansible-playbook playbook.yaml -i full.ini

```

<img width="1018" height="691" alt="img" src="https://github.com/user-attachments/assets/a7683df2-17cb-4081-be7a-9b944a59e45c" />
