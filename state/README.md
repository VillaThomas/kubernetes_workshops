# Storing States

## Prérequis

- Avoir un cluster opérationnel ainsi que kubectl configuré pour intéragir ave ce cluster

## Lab

Nous utiliserons l'application Java crée précedement nommé Customer-Backend.  

Créer un service pour 'application. Il sera utilisé tout au long du Lab.

```
kubectl create -f ./service.yaml
```
```
service "customer-backend" created
```

Utiliser les commandes des labs précèdent pour retrouver l'ip et le node port de la machine.


### Database et backend dans le même Pod

Lors de la création d'un pod, si la base de donnée et le backend se trouvent dans la 
même image docker ou dans le même déploiement, on va être confronté à différentes problématique.

Si l'on scale le nombres de pods, chacun aura sa propre database. Lorsqu'une donnée sera persistée 
elle ne le sera pas dans les autres databases.


- Exemple de mise à l'échelle et de pertes des données ? (un pods avec BDD + backend) -> Expliquer des variables d'env

```
kubectl create -f ./java-backend_bdd.yaml
```
```
deployment "java-backend_bdd" created
```

Supprimmer juste le déploiement:

```
kubectl delete -f ./java-backend_bdd.yaml
```
```
deployment "java-backend_bdd" deleted
```

???

### External Database in Kubernetes

Le moyen le plus simple de laisser la database à l'extérieur du pods 
contenant l'application, voir dans certain cas à l'extérieur du cluster 

Non allons donc déployer notre backend Java pour qu'il intéragissent 
directement avec une base de donnée PostgresQL déployé dans un autre pods.

Nous avons deux conteneurs :

- Customer-Backend : Il va être utilisé pour requeter ou insérer des informations en base.
> On a 3 variables d'environment : 
> - POSTGRES_URL: qui contient l'url de la BDD -> posgres-service:5432/customer
> - POSTGRES_USER: qui contient le user de la BDD -> root
> - POSTGRES_PASSWORD: qui contient le password de la BDD

- Customer-db : Il s'agit de la base de donnée PostgresQL
> On a 2 variables d'environment : 
> - POSTGRES_DB: qui contient le nom de la BSS -> posgres-service:5432/customer
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
service "customer-db" created
deployment "customer-db" created
```

Nous avons le fichier de déploiement [customer-backend.yaml](customer-backend.yaml) créé pour 
se connecter à la base de donnée `customer-db`.
Le mot de passe étant récupéré via un secret ils seront toujours identiques.

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
configurée. Les données sont stocké à l'intérieur du conteneur.
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
Il existe de nombreux plugins 

To run the database inside Kubernetes, but keep the data persistent,
we will use a Persistent Volume (PV), which is a Kubernetes object
that usually refers to an external storage device. This is typically a
resilient cloud disk in clouds, or an NFS or iSCSI disk in on-premise
clusters.

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
Cela permet de ne pas avoir ses configurations à l'interéieur d'un déploiemet.

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


Vérifier si tout fonctionne correctement. Redémarrer des pods, scaler etc..

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

You can see it is now released.

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