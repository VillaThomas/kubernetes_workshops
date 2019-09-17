# Core Concepts

## Pr�requis

- Avoir un cluster op�rationnel ainsi que kubectl configur� pour int�ragir ave ce cluster

## Lab

### Pods

Cr�er un pod � partir du fichier [pod.yaml](pod.yaml). 

```
kubectl create -f ./pod.yaml
```

```
pod "party-clippy" created
```

V�rifier les pods
```
kubectl get pods
```

```
NAME            READY     STATUS    RESTARTS   AGE
party-clippy   1/1       Running   0          1m
```

Regarder le pod en d�tail

```
kubectl describe pod party-clippy
```
```
Name:		party-clippy
Namespace:	default

```

Supprimer le pod

```
kubectl delete pod party-clippy
```
```
pod "party-clippy" deleted
```

Le pod est supprim� d�finitivement.  La m�me chose se serait produit si le pod se serait termin� pour n'importe quelles raisons.


### Service

Pour acc�der � Party-clippy depuis l'exterrieur du cluster, nous allons devoir cr�er un service. Le service d�finit par [service.yaml](service.yaml) 
va rediriger le traffic sur chaque pod avec le label `app: party-clippy`. Le service est sur le port 80 et 
redirige sur le port 8080,  labelis� `web` dans la d�finition du conteneur.
La `type: NodePort` va permettre d'acc�der au service � partir d'un port qui sera accessible depuis n'importe quel noeud.

Create the service and pod:

```
kubectl create -f ./service.yaml,./pod.yaml
```

```
service "party-clippy" created
pod "party-clippy" created
```

V�rifier le node port du service :

```
kubectl get svc party-clippy -o yaml | grep nodePort
```

```
  - nodePort: 31418
```


V�rifier en essayant un curl avec le port r�cup�r� :

```
  curl http://localhost:31418
```


Supprimer les pods et les Services o� le label `app` est �gal � `party-clippy`. 

```
kubectl delete pod,svc -l app=party-clippy
```

```
pod "party-clippy" deleted
service "party-clippy" deleted
```

### Replication Controller

Lorsque qu'un pod est supprim�, cela est irr�versibe. Le pod peut aussi disparaitre
si le le noeud du cluster fail ou si l'application crashe. L'application ne red�marrera pas.
La solution est d'utiliser le Replication Controller,ou RC fournit par kubernetes.
Le RC va s'assurer que le nombre de pods souhait� tourne toujours dans les diff�rents
noeuds du cluster.

Voici la d�finitions du RC : [rc.yaml]()

D�marrer Party-clippy en utilisant un RC. On utilisera le m�me service que pr�c�demment :

```
kubectl create -f ./rc.yaml,./service.yaml
```

```
replicationcontroller "party-clippy" created
service "party-clippy" created
```

V�rifier le node port du service :

```
kubectl get svc party-clippy -o yaml | grep nodePort
```

```
  - nodePort: 31388
```


V�rifier en essayant un curl avec le port r�cup�r� :

```
  curl http://localhost:31388
```


V�rifier le pod

```
kubectl get pods -o wide
```

```
NAME                 READY     STATUS    RESTARTS   AGE       NODE
party-clippy-jf0xs   1/1       Running   0          2m        Node1
```

Le pod a �t� cr�� par le replication controller. Maintenant, essayer
de supprimer le pod, en utilisant le nom exacte du pod :

```
kubectl delete pod party-clippy-jf0xs
```

```
pod "party-clippy-jf0xs" deleted
```

Re-v�rifier le pod :

```
kubectl get pods -o wide
```

```
NAME               READY     STATUS    RESTARTS   AGE       NODE
party-clippy-t1vwk   1/1       Running   0          6s      Node1
```

Un nouveau pod a �t� cr��. Il peut �tre sch�duler dans un n'importe quel noeud.

Pour scaler l'application, il suffit de pr�ciser le nombre de r�plicat souhait� :

```
kubectl scale --replicas=5 rc party-clippy
```

```
replicationcontroller "party-clippy" scaled
```

V�rifier les pods

```
kubectl get pods -o wide
```

```
NAME             READY     STATUS              RESTARTS   AGE       NODE
party-clippy-32ona   1/1       Running             0          26s       Node1
party-clippy-8twm0   1/1       Running             0          2m        Node1
party-clippy-hhves   0/1       ContainerCreating   0          26s       Node1
party-clippy-lv5km   0/1       ContainerCreating   0          26s       Node1
party-clippy-tlojp   0/1       ContainerCreating   0          26s       Node1
```

ainsi que le RC

```
kubectl get rc party-clippy -o wide
```

```
NAME       DESIRED   CURRENT   AGE       CONTAINER(S)   IMAGE(S)                             SELECTOR
party-clippy   5         5         3m        party-clippy       jessfraz/party-clippy:latest   app=party-clippy
```

Le service party-clippy va rediriger le traffic entre les 5 pods qui correspondent
au s�lector app=party-clippy.


Supprime les Replication Controllers et les Services, o� le label `app` est �gal � `party-clippy`.

```
kubectl delete rc,svc -l app=party-clippy
```
```
replicationcontroller "party-clippy" deleted
service "party-clippy" deleted
```
Pas besoin de supprimer les pods, cela sera fait en supprimant le RC.

### Deployments

Les Deployments sont tr�s simmilaires aux RC.
Ils managent le d�ploiement de Replica Sets, permettant de les mettre � jour rapidement.
On a un historique des rollout et il est possible de faire un rollback.


D�marrer party-clippy en utilisant le fichier de d�ploiement suivant : [dep.yaml](dep.yaml).

```
kubectl create -f ./dep.yaml,./service.yaml
```

```
deployment "party-clippy" created
service "party-clippy" created
```

Les Deployments contr�let et cr�ent des Replica Sets (comme des RCs).
On regarge les RS :

```
kubectl get rs -o wide
```

```
NAME                  DESIRED   CURRENT   AGE       CONTAINER(S)   IMAGE(S)                             SELECTOR
party-clippy-1901432027   5         5         47s       party-clippy       jessfraz/party-clippy:latest   app=party-clippy,pod-template-hash=1901432027
```

- Rollout ? (exemple kubectl rollout history deployment/nginx-deployment)
 (kubectl rollout history deployment/nginx-deployment --revision=2)
- Replicat Sets ?


## Cleanup

Supprimer tous ce qui a �t� cr��s dans ce lab o� le label `app` est �gal � `party-clippy`. 

```
kubectl delete pod,rc,svc,deployment -l app=party-clippy
```
