# Storing States

## Pr�requis

- Avoir un cluster op�rationnel ainsi que kubectl configur� pour int�ragir ave ce cluster

## Lab

Nous utiliserons l'application Java cr�e pr�cedement nomm� Customer-Backend.  

Cr�er un service pour 'application. Il sera utilis� tout au long du Lab.

```
kubectl create -f ./service.yaml
```
```
service "customer-backend" created
```

Utiliser les commandes des labs pr�c�dent pour retrouver l'ip et le node port de la machine.


### Database et backend dans le m�me Pod

Lors de la cr�ation d'un pod, si la base de donn�e et le backend se trouvent dans la 
m�me image docker ou dans le m�me d�ploiement, on va �tre confront� � diff�rentes probl�matique.

Si l'on scale le nombres de pods, chacun aura sa propre database. Lorsqu'une donn�e sera persist�e 
elle ne le sera pas dans les autres databases.


- Exemple de mise � l'�chelle et de pertes des donn�es ? (un pods avec BDD + backend) -> Expliquer des variables d'env

```
kubectl create -f ./java-backend_bdd.yaml
```
```
deployment "java-backend_bdd" created
```

Supprimmer juste le d�ploiement:

```
kubectl delete -f ./java-backend_bdd.yaml
```
```
deployment "java-backend_bdd" deleted
```

???

### External Database in Kubernetes

Le moyen le plus simple de laisser la database � l'ext�rieur du pods 
contenant l'application, voir dans certain cas � l'ext�rieur du cluster 

Non allons donc d�ployer notre backend Java pour qu'il int�ragissent 
directement avec une base de donn�e PostgresQL d�ploy� dans un autre pods.

Nous avons deux conteneurs :

- Customer-Backend : Il va �tre utilis� pour requeter ou ins�rer des informations en base.
> On a 3 variables d'environment : 
> - POSTGRES_URL: qui contient l'url de la BDD -> posgres-service:5432/customer
> - POSTGRES_USER: qui contient le user de la BDD -> root
> - POSTGRES_PASSWORD: qui contient le password de la BDD

- Customer-db : Il s'agit de la base de donn�e PostgresQL
> On a 2 variables d'environment : 
> - POSTGRES_DB: qui contient le nom de la BSS -> posgres-service:5432/customer
> - POSTGRES_PASSWORD: qui contient le password de la BDD

Cr�er un secret en utilisant la commande ci dessous. Remplacer `mypassword`
par le password souhait� pour la base de donn�e postgres.

```
kubectl create secret generic db-pass --from-literal=password=mypassword
```
```
secret "db-pass" created
```

Dans le fichier [customer-db.yaml](customer-db.yaml). Le fichier de 
configuration va cr�er un service et un d�ployment de l'image de postgres 
cr�er au lab pr�c�dent. On pr�cise dans notre d�ploiement les diff�rentes 
variables d'environnement. La variable du password est pris directement dans 
le secret. Le service cr�� `customer-db` est resolvable comme une entr�e DNS 
pour tous les Pod du cluster utilisant Kube DNS.

D�ployer la bdd :  

```
kubectl create -f ./customer-db.yaml
```

```
service "customer-db" created
deployment "customer-db" created
```

Nous avons le fichier de d�ploiement [customer-backend.yaml](customer-backend.yaml) cr�� pour 
se connecter � la base de donn�e `customer-db`.
Le mot de passe �tant r�cup�r� via un secret ils seront toujours identiques.

```
kubectl create -f ./customer-backend.yaml
```
```
deployment "customer-backend" created
```

Maintenant on peut tester d'acc�der � notre application Customer-Backend pour v�rifier 
si nous avons bien les donn�es dans la base et si nous pouvons en ins�rer.

- Inserer
- R�cup�rer
- Job pour lancer une init ???

Le porbl�mes est maintenant que ma base de donn�e est dans mon 
cluster Kubernetes, mais qu'aucune persitance des donn�es n'est 
configur�e. Les donn�es sont stock� � l'int�rieur du conteneur.
Cela fonctionne tant que le noeud et le conteneur continue de 
fonctionner. Kubernetes consid�re que les pods sont �ph�m�re et 
stateles. Si le noeud plante ou que le pod est supprim�, Kubernetes
va rescheduler a un nouveau pods pour customer-db, mais les donn�es
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

Pour faire tourner une bdd dans Kubernetes, en gardant les donn�es
persistantes, il faut utiliser des Persitent Volume (PV). Il s'agit 
d'un object Kubernetes qui correspond � un stockage externe. Il peut 
s'agir d'un disque, d'un NFS, d'iSCSI, on-premise ou dans le cloud. 
Il existe de nombreux plugins 

To run the database inside Kubernetes, but keep the data persistent,
we will use a Persistent Volume (PV), which is a Kubernetes object
that usually refers to an external storage device. This is typically a
resilient cloud disk in clouds, or an NFS or iSCSI disk in on-premise
clusters.

Ici nous allons cr�er un Persistent Volume, directement sur le noeud
(`hostPath` type). Cela ne fonctionne que dans un contexte single Node.
Utiliser le fichier [local-pv.yaml](local-pv.yaml) pour cr�er un PV qui 
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
avons rajouter un object Persitent Volume Claim (PVC). Un PVC va r�clamer
� ce qu'on lui associe un PV dans le cluster correspondant � ses �xigences.
Cela permet de ne pas avoir ses configurations � l'inter�ieur d'un d�ploiemet.

Le PVC s'appelle `pg-pv-claim` et il est sp�cifi� dans le Deployment.
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


V�rifier si tout fonctionne correctement. Red�marrer des pods, scaler etc..

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