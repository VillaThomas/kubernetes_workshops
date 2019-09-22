# Core Concepts

## Prérequis

- Avoir un cluster opérationnel ainsi que kubectl configuré pour intéragir ave ce cluster

## Lab

### Projects and Namespaces

Via l'IHM de Rancher, nous allons créer un namespace `hello` dans le project `Default`.

### Pods

Créer un pod à partir du fichier [pod_ns.yaml](pod_ns.yaml). 

```
kubectl create -f ./pod_ns.yaml
```

```
pod/hello created
```

Vérifier les pods

```
kubectl get pods
```

```
No resources found in default namespace.
```

Cela est du que nous ne sommes pas dans le bon namespace.

```
kubectl get pods -n hello
```

```
NAME    READY   STATUS    RESTARTS   AGE
hello   1/1     Running   0          2m41s
```

Regarder le pod en détail

```
kubectl describe pod hello -n hello
```
```
Name:         hello
Namespace:    hello
Priority:     0
Node:         test1/192.168.1.44
Start Time:   Sun, 22 Sep 2019 18:30:37 +0200
Labels:       app=hello
Annotations:  cni.projectcalico.org/podIP: 10.42.0.13/32
Status:       Running
IP:           10.42.0.13
IPs:          <none>
Containers:
  hello:
    Container ID:   docker://cb6b57692e26688c0a99a569d5e740b2647090516d37659f0259c642f986d960
    Image:          nginxdemos/hello:plain-text
    Image ID:       docker-pullable://nginxdemos/hello@sha256:02a5bc13f8917b9631356fed56a98a4cf2e08e819d74bfe0c817f1179d4a0055
    Port:           80/TCP
    Host Port:      0/TCP
    State:          Running
      Started:      Sun, 22 Sep 2019 18:30:43 +0200
    Ready:          True
    Restart Count:  0
    Environment:    <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from default-token-qz8bt (ro)
Conditions:
  Type              Status
  Initialized       True
  Ready             True
  ContainersReady   True
  PodScheduled      True
Volumes:
  default-token-qz8bt:
    Type:        Secret (a volume populated by a Secret)
    SecretName:  default-token-qz8bt
    Optional:    false
QoS Class:       BestEffort
Node-Selectors:  <none>
Tolerations:     node.kubernetes.io/not-ready:NoExecute for 300s
                 node.kubernetes.io/unreachable:NoExecute for 300s
Events:
  Type    Reason     Age    From               Message
  ----    ------     ----   ----               -------
  Normal  Scheduled  5m30s  default-scheduler  Successfully assigned hello/hello to test1
  Normal  Pulling    5m29s  kubelet, test1     Pulling image "nginxdemos/hello:plain-text"
  Normal  Pulled     5m25s  kubelet, test1     Successfully pulled image "nginxdemos/hello:plain-text"
  Normal  Created    5m24s  kubelet, test1     Created container hello
  Normal  Started    5m24s  kubelet, test1     Started container hello

```

Supprimer le pod

```
kubectl delete pod hello -n hello
```
```
pod "hello" deleted
```

Le pod est supprimé définitivement. La même chose se serait produit si l'éxectution du pod s'était terminée pour une raison quelconque.


### Service

Pour accéder à Hello depuis l'exterrieur du cluster, nous allons devoir créer un service. Le service définit par [service.yaml](service.yaml) va rediriger le traffic sur chaque pod avec le label `app: hello`. Le service est sur le port 80 et 
redirige sur le port 80,  labelisé `web` dans la définition du conteneur.
La `type: NodePort` va permettre d'accéder au service à partir d'un port qui sera accessible depuis n'importe quel noeud.

Dans cette exemple nous utiliserons le namespace par défaut.

Créer le pod et le service:

```
kubectl create -f ./service.yaml,./pod.yaml
```

```
service/hello created
pod/hello created
```

Vérifier le node port du service :

```
kubectl get svc hello -o yaml | grep nodePort
```

```
  - nodePort: 30552
```


Vérifier en essayant un curl avec le port récupéré :

```
curl http://127.0.0.1:30552
```

```
Server address: 10.42.0.15:80
Server name: hello
Date: 22/Sep/2019:16:46:49 +0000
URI: /
Request ID: db4bb96f82dce5cc42d8c4dcd130ecce
```

Essayons de comprendre à quoi correspond l'adresse serveur.

Supprimer les pods et les Services où le label `app` est égal à `hello`. 

```
kubectl delete pod,svc -l app=hello
```

```
pod "hello" deleted
service "hello" deleted
```

### Replication Controller

Lorsque qu'un pod est supprimé, cela est irréversibe. Le pod peut aussi disparaitre
si le le noeud du cluster fail ou si l'application crashe. L'application ne redémarrera pas.
La solution est d'utiliser le Replication Controller,ou RC fournit par kubernetes.
Le RC va s'assurer que le nombre de pods souhaité tourne toujours dans les différents
noeuds du cluster.

Voici la définitions du RC : [rc.yaml](rc.yaml)

Démarrer Hello en utilisant un RC. On utilisera le même service que précèdemment :

```
kubectl create -f ./rc.yaml,./service.yaml
```

```
replicationcontroller/hello created
service/hello created
```

Vérifier le node port du service :

```
kubectl get svc hello -o yaml | grep nodePort
```

```
  - nodePort: 30572
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
NAME          READY   STATUS    RESTARTS   AGE   IP           NODE   
hello-jz8qr   1/1     Running   0          38s   10.42.0.16   test11
```

Le pod a été créé par le replication controller. Maintenant, essayer
de supprimer le pod, en utilisant le nom exacte du pod :

```
kubectl delete pod hello-jz8qr
```

```
pod "hello-jz8qr" deleted
```

Re-vérifier les pods :

```
kubectl get pods -o wide
```

```
NAME          READY   STATUS    RESTARTS   AGE   IP           NODE 
hello-vgkkp   1/1     Running   0          19s   10.42.0.17   test1
```

Un nouveau pod a été créé. Il peut être schéduler dans un n'importe quel noeud.

Pour scaler l'application, il suffit de préciser le nombre de réplicat souhaité :

```
kubectl scale --replicas=5 rc hello
```

```
replicationcontroller/hello scaled
```

Vérifier les pods

```
kubectl get pods -o wide
```

```
NAME          READY   STATUS    RESTARTS   AGE   IP           NODE 
hello-94szh   1/1     Running   0          34s   10.42.0.18   test1
hello-m4w7g   1/1     Running   0          34s   10.42.0.19   test1
hello-tsl56   1/1     Running   0          34s   10.42.0.20   test1
hello-vgkkp   1/1     Running   0          90s   10.42.0.17   test1
hello-zch4s   1/1     Running   0          34s   10.42.0.21   test1
```

ainsi que le RC

```
kubectl get rc hello -o wide
```

```
NAME    DESIRED   CURRENT   READY   AGE     CONTAINERS   IMAGES                        SELECTOR
hello   5         5         5       3m32s   hello        nginxdemos/hello:plain-text   app=hello
```

Le service hello va rediriger le traffic entre les 5 pods qui correspondent
au sélector app=hello


Supprimer les Replication Controllers et les Services, où le label `app` est égal à `party-clippy`.

```
kubectl delete rc,svc -l app=hello
```
```
replicationcontroller "hello" deleted
service "hello" deleted
```
Pas besoin de supprimer les pods, cela sera fait en supprimant le RC.

### Deployments

Les Deployments sont très simmilaires aux RC.
Ils managent le déploiement de Replica Sets, permettant de les mettre à jour rapidement.
On a un historique des rollout et il est possible de faire un rollback.


Démarrer hello en utilisant le fichier de déploiement suivant : [dep.yaml](dep.yaml).

```
kubectl create -f ./dep.yaml,./service.yaml
```

```
deployment.extensions/hello created
service/hello created
```

Les Deployments contrôlet et créent des Replica Sets (comme des RCs).
On regarge les RS :

```
kubectl get rs -o wide
```

```
NAME              DESIRED   CURRENT   READY   AGE   CONTAINERS   IMAGES                        SELECTOR
hello-59f79686d   5         5         5       16s   hello        nginxdemos/hello:plain-text   app=hello,pod-template-hash=59f79686d
```

```
kubectl rollout status deployment/hello
```

```
deployment "hello" successfully rolled out
```

```
kubectl rollout history deployment/hello
```
```
deployment.extensions/hello
REVISION  CHANGE-CAUSE
1         <none>
```

Editer le tag de l'image utilisé et la remplacer par  : 
```
kubectl edit deployment hello
```
```
deployment.extensions/hello edited
```

```
kubectl rollout history deployment/hello
```
```
deployment.extensions/hello
REVISION  CHANGE-CAUSE
1         <none>
2         <none>
```

```
kubectl rollout history deployment/hello --revision 1
```
```
deployment.extensions/hello with revision #1
Pod Template:
  Labels:       app=hello
        pod-template-hash=59f79686d
  Containers:
   hello:
    Image:      nginxdemos/hello:plain-text
    Port:       80/TCP
    Host Port:  0/TCP
    Environment:        <none>
    Mounts:     <none>
  Volumes:      <none>
```

```
kubectl rollout history deployment/hello --revision 2
```
```
deployment.extensions/hello with revision #2
Pod Template:
  Labels:       app=hello
        pod-template-hash=6f988c549f
  Containers:
   hello:
    Image:      nginxdemos/hello:0.2-plain-text
    Port:       80/TCP
    Host Port:  0/TCP
    Environment:        <none>
    Mounts:     <none>
  Volumes:      <none>
```


## Cleanup

Supprimer tous ce qui a été créés dans ce lab où le label `app` est égal à `hello`. 

```
kubectl delete pod,svc,deployment -l app=hello
```
```
pod "hello-6f988c549f-2qpdm" deleted
pod "hello-6f988c549f-dk9dk" deleted
pod "hello-6f988c549f-w67kk" deleted
service "hello" deleted
deployment.extensions "hello" deleted
```
