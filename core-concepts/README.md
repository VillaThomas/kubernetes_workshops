# Core Concepts

## Prérequis

- Avoir un cluster opérationnel ainsi que kubectl configuré pour intéragir ave ce cluster

## Lab

### Pods

Créer un pod à partir du fichier [pod.yaml](pod.yaml). 

```
kubectl create -f ./pod.yaml
```

```
pod "party-clippy" created
```

Vérifier les pods
```
kubectl get pods
```

```
NAME            READY     STATUS    RESTARTS   AGE
party-clippy   1/1       Running   0          1m
```

Regarder le pod en détail

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

Le pod est supprimé définitivement.  La même chose se serait produit si le pod se serait terminé pour n'importe quelles raisons.


### Service

Pour accéder à Party-clippy depuis l'exterrieur du cluster, nous allons devoir créer un service. Le service définit par [service.yaml](service.yaml) 
va rediriger le traffic sur chaque pod avec le label `app: party-clippy`. Le service est sur le port 80 et 
redirige sur le port 8080,  labelisé `web` dans la définition du conteneur.
La `type: NodePort` va permettre d'accéder au service à partir d'un port qui sera accessible depuis n'importe quel noeud.

Create the service and pod:

```
kubectl create -f ./service.yaml,./pod.yaml
```

```
service "party-clippy" created
pod "party-clippy" created
```

Vérifier le node port du service :

```
kubectl get svc party-clippy -o yaml | grep nodePort
```

```
  - nodePort: 31418
```


Vérifier en essayant un curl avec le port récupéré :

```
  curl http://localhost:31418
```


Supprimer les pods et les Services où le label `app` est égal à `party-clippy`. 

```
kubectl delete pod,svc -l app=party-clippy
```

```
pod "party-clippy" deleted
service "party-clippy" deleted
```

### Replication Controller

Lorsque qu'un pod est supprimé, cela est irréversibe. Le pod peut aussi disparaitre
si le le noeud du cluster fail ou si l'application crashe. L'application ne redémarrera pas.
La solution est d'utiliser le Replication Controller,ou RC fournit par kubernetes.
Le RC va s'assurer que le nombre de pods souhaité tourne toujours dans les différents
noeuds du cluster.

Voici la définitions du RC : [rc.yaml]()

Démarrer Party-clippy en utilisant un RC. On utilisera le même service que précèdemment :

```
kubectl create -f ./rc.yaml,./service.yaml
```

```
replicationcontroller "party-clippy" created
service "party-clippy" created
```

Vérifier le node port du service :

```
kubectl get svc party-clippy -o yaml | grep nodePort
```

```
  - nodePort: 31388
```


Vérifier en essayant un curl avec le port récupéré :

```
  curl http://localhost:31388
```


Vérifier le pod

```
kubectl get pods -o wide
```

```
NAME                 READY     STATUS    RESTARTS   AGE       NODE
party-clippy-jf0xs   1/1       Running   0          2m        Node1
```

Le pod a été créé par le replication controller. Maintenant, essayer
de supprimer le pod, en utilisant le nom exacte du pod :

```
kubectl delete pod party-clippy-jf0xs
```

```
pod "party-clippy-jf0xs" deleted
```

Re-vérifier le pod :

```
kubectl get pods -o wide
```

```
NAME               READY     STATUS    RESTARTS   AGE       NODE
party-clippy-t1vwk   1/1       Running   0          6s      Node1
```

Un nouveau pod a été créé. Il peut être schéduler dans un n'importe quel noeud.

Pour scaler l'application, il suffit de préciser le nombre de réplicat souhaité :

```
kubectl scale --replicas=5 rc party-clippy
```

```
replicationcontroller "party-clippy" scaled
```

Vérifier les pods

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
au sélector app=party-clippy.


Supprime les Replication Controllers et les Services, où le label `app` est égal à `party-clippy`.

```
kubectl delete rc,svc -l app=party-clippy
```
```
replicationcontroller "party-clippy" deleted
service "party-clippy" deleted
```
Pas besoin de supprimer les pods, cela sera fait en supprimant le RC.

### Deployments

Les Deployments sont très simmilaires aux RC.
Ils managent le déploiement de Replica Sets, permettant de les mettre à jour rapidement.
On a un historique des rollout et il est possible de faire un rollback.


Démarrer party-clippy en utilisant le fichier de déploiement suivant : [dep.yaml](dep.yaml).

```
kubectl create -f ./dep.yaml,./service.yaml
```

```
deployment "party-clippy" created
service "party-clippy" created
```

Les Deployments contrôlet et créent des Replica Sets (comme des RCs).
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

Supprimer tous ce qui a été créés dans ce lab où le label `app` est égal à `party-clippy`. 

```
kubectl delete pod,rc,svc,deployment -l app=party-clippy
```
