# Course project on subject "Databases". 
## Theme of the work is "Developing of the data base for automatisation of storage accounting"
## Description:
```Приложение предназначено для ввода и обработки информации, о приходе и выбытии товара, а также о фактических остатках товара на складе. 
На основе полученных данных должен производиться расчет реализации товара за определенный период. 
Автоматизированная информационная система должна контролировать корректность вводимой информации и осуществлять формирование выходных документов (инвентаризационная ведомость остатков, отчет о реализации товара за период, отчет по приходу товара на склад). 
В связи с инфляцией и уменьшением срока годности товара иногда возникает необходимость произвести переоценку товара, которая оформляется документально (акт списания товара). 
Также, в системе осуществляется формирование карточки с изображением товара и его описанием. 
При входе в систему требуется авторизация пользователей.
```

## Scripts using
- ```debug.sh``` - script for development, rebuild every time
- ```start.sh``` - script to start information system
- ```stop.sh``` - script to stop the whole information system
- ```make_dump.sh``` - script to make reserve database dump
- ```backup.sh``` - script to transfer the entire system to another machine, include database dump and images on server. After using this script you will have got archive with whole info, just transfer it onto another server -> unzip it -> start ```./restore.sh```

## Links
- [Visual interface](http://localhost:8080/)
- [API homepage](http://localhost:8080/api/)
- [pgAdmin4](http://localhost:5050)