# Storing States

## Prérequis

- Avoir un cluster opérationnel ainsi que kubectl configuré pour intéragir ave ce cluster

## Lab

Nous utiliserons l'application Java crée précedement nommé Customer.  

Créer un service pour 'application. Il sera utilisé tout au long du Lab.

```
kubectl create -f ./service.yaml
```
```
service/customer-backend created
```

Utiliser les commandes des labs précèdent pour retrouver l'ip et le node port de la machine.


### Database et backend dans le même Pod

Lors de la création d'un pod, si la base de donnée et le backend se trouvent dans la  
même image docker ou dans le même pod, on va être confronté à différentes problématiques.

Si l'on scale le nombres de pods, chacun aura sa propre database. Lorsqu'une donnée est persistée 
elle ne le sera pas dans les autres databases.

### External Database in Kubernetes

Le moyen le plus simple est de laisser la database à l'extérieur du pods 
contenant l'application, voir dans certain cas à l'extérieur du cluster .

Non allons donc déployer notre backend Java pour qu'il intéragisse 
directement avec une base de donnée PostgresQL déployée dans un autre pod.

Nous avons deux conteneurs :

- Customer-Backend : Il va être utilisé pour requeter ou insérer des informations en base.
> On a 3 variables d'environment : 
> - POSTGRES_URL: qui contient l'url de la BDD -> customer-db:5432/customer
> - POSTGRES_USER: qui contient le user de la BDD -> backend
> - POSTGRES_PASSWORD: qui contient le password de la BDD

Expose le port 8080

- Customer-db : Il s'agit de la base de donnée PostgresQL
> On a 3 variables d'environment : 
> - POSTGRES_DB: qui contient le nom de la BSS -> customer
> - POSTGRES_USER: qui contient le user de la BDD -> backend
> - POSTGRES_PASSWORD: qui contient le password de la BDD

Créer un secret en utilisant la commande ci dessous. Remplacer `mypassword`
par le password souhaité pour la base de donnée postgres.

```
kubectl create secret generic db-pass --from-literal=password=mypassword
```
```
secret "db-pass" created
```

Dans le fichier [customer-db.yaml](customer-db.yaml). Le fichier de 
configuration va créer un service et un déployment de l'image de postgres 
créer au lab précédent. On précise dans notre déploiement les différentes 
variables d'environnement. La variable du password est pris directement dans 
le secret. Le service créé `customer-db` est resolvable comme une entrée DNS 
pour tous les Pod du cluster utilisant Kube DNS.

Déployer la bdd :  

```
kubectl create -f ./customer-db.yaml
```
```
service/customer-db created
deployment.extensions/customer-db created
```

Nous allons maintenant créer un schéma et insérer des données dans la bdd.
Pour cela nous allons rentrer directement dans le conteneur, soit grâce à l'IHM
de Rancher, soit grâce à Kubectl.

```
kubectl get pods
```
```
NAME                           READY   STATUS    RESTARTS   AGE
customer-db-8647b67b8f-h22d8   1/1     Running   0          7m48s
```

```
kubectl exec -it customer-db-8647b67b8f-h22d8 /bin/bash
```
```
root@customer-db-8647b67b8f-h22d8:/#
```

La commande pour se connecter à la base est :

```
psql DBNAME USERNAME
```

Par rapport aux variables d'environnements définies cela donne : 

```
psql customer backend
```
```
psql (11.5 (Debian 11.5-1.pgdg90+1))
Type "help" for help.

customer=#
```

On passe les commandes de création d'une table et de données : 

```
CREATE TABLE customer(
   id serial PRIMARY KEY,
   username VARCHAR (50) UNIQUE NOT NULL,
   name VARCHAR (355) UNIQUE NOT NULL
);
INSERT INTO customer(id, username, name) VALUES (1, 'john', 'DOE');
SELECT * FROM customer;
```

Nous avons le fichier de déploiement [customer-backend.yaml](customer-backend.yaml).

Les variables d'environnement vont permettre au backend de se connecter à la base de donnée `customer-db`.
Le mot de passe étant récupéré via un secret, ils seront toujours identiques entre la BDD et le Backend

```
kubectl create -f ./customer-backend.yaml
```
```
deployment "customer-backend" created
```

Maintenant on peut tester d'accéder à notre application Customer-Backend pour vérifier 
si nous avons bien les données dans la base et si nous pouvons en insérer.

- Inserer
- Récupérer
- Job pour lancer une init ???

Le porblèmes est maintenant que ma base de donnée est dans mon 
cluster Kubernetes, mais qu'aucune persitance des données n'est 
configurée. Les données sont stockées à l'intérieur du conteneur.
Cela fonctionne tant que le noeud et le conteneur continue de 
fonctionner. Kubernetes considère que les pods sont éphémère et 
stateles. Si le noeud plante ou que le pod est supprimé, Kubernetes
va rescheduler a un nouveau pods pour customer-db, mais les données
seront perdues.

Supprimer le Deployment et le Service de la bdd : 

```
kubectl delete deployment,svc customer-db
```
```
deployment "customer-db" deleted
service "customer-db" deleted
```

### Database avec un Persistent Volume

Pour faire tourner une bdd dans Kubernetes, en gardant les données
persistantes, il faut utiliser des Persitent Volume (PV). Il s'agit 
d'un object Kubernetes qui correspond à un stockage externe. Il peut 
s'agir d'un disque, d'un NFS, d'iSCSI, on-premise ou dans le cloud. 
Il existe de nombreux plugins. 

Ici nous allons créer un Persistent Volume, directement sur le noeud
(`hostPath` type). Cela ne fonctionne que dans un contexte single Node.
Utiliser le fichier [local-pv.yaml](local-pv.yaml) pour créer un PV qui 
pointe sur `/tmp/pg-disk` sur notre noeud

```
kubectl create -f ./local-pv.yaml
```
```
persistentvolume "local-pv-1" created
```
...
```
kubectl get pv
```
```
NAME         CAPACITY   ACCESSMODES   STATUS      CLAIM     REASON    AGE
local-pv-1   2Gi        RWO           Available                       17s
```
...
```
kubectl describe pv local-pv-1
```
```
Name:		local-pv-1
Labels:		type=local
Status:		Available
Claim:		
Reclaim Policy:	Retain
Access Modes:	RWO
Capacity:	2Gi
Message:	
Source:
    Type:	HostPath (bare host directory volume)
    Path:	/tmp/pg-disk
```

Dans le ficher [customer-db-pvc.yaml](customer-db-pvc.yaml],nous 
avons rajouter un object Persitent Volume Claim (PVC). Un PVC va réclamer
à ce qu'on lui associe un PV dans le cluster correspondant à ses éxigences.
Cela permet de ne pas avoir ses configurations à l'intérieur d'un déploiemet.

Le PVC s'appelle `pg-pv-claim` et il est spécifié dans le Deployment.
On monte ensuite ce volume dans `/var/lib/postgresql/data`.

```
kubectl create -f ./customer-db-pvc.yaml
```
```
service "customer-db" created
persistentvolumeclaim "pg-pv-claim" created
deployment "customer-db" created
```

On peut maintenant voir que le PVC est bound au PV : 

```
kubectl get pv
```
```
NAME         CAPACITY   ACCESSMODES   STATUS    CLAIM                    REASON    AGE
local-pv-1   2Gi        RWO           Bound     default/pg-pv-claim             3m
```
...
```
kubectl get pvc
```
```
NAME          STATUS    VOLUME       CAPACITY   ACCESSMODES   AGE
pg-pv-claim   Bound     local-pv-1   2Gi       RWO           7s
```


Vérifier si tout fonctionne correctement (Redémarrer des pods, scaler etc..)

## Cleanup

```
kubectl delete svc,deployment,job,pvc -l app=customer
```
```
service "customer-backend" deleted
service "customer-db" deleted
deployment "customer-backend" deleted
deployment "customer-db" deleted
persistentvolumeclaim "pg-pv-claim" deleted
```

```
kubectl get pv
```
```
NAME         CAPACITY   ACCESSMODES   STATUS     CLAIM                    REASON    AGE
local-pv-1   2Gi        RWO           Released   default/pg-pv-claim             4m
```

```
kubectl delete pv local-pv-1
```
```
persistentvolume "local-pv-1" deleted
```
...
```
kubectl delete secret db-pass
```
```
secret "db-pass" deleted
```
