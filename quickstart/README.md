# Quickstart

## Prérequis

- Avoir un cluster opérationnel ainsi que kubectl configuré pour intéragir ave ce cluster

## Lab

Le conteneur utilisé pour ce lab est hello-node. Il s'agit d'un petit serveur web qui écoute sur le port 8080.

Lancer l'application hello-node dans un conteneur.

```
kubectl create deployment hello-node --image=gcr.io/hello-minikube-zero-install/hello-node
```

```
deployment "hello-node" created
```

Afficher les déploiements

```
kubectl get deployments
```

```
NAME         READY   UP-TO-DATE   AVAILABLE   AGE
hello-node   1/1     1            1           3m23s
```

Afficher les pods
```
kubectl get pods
```

```
NAME                          READY   STATUS    RESTARTS   AGE
hello-node-6ff4d56d4c-c24mf   1/1     Running   0          3m58s
```

Afficher les evenement du cluster :

```
kubectl get events
```

```
LAST SEEN   TYPE      REASON                    OBJECT                             MESSAGE
5m35s       Normal    Scheduled                 pod/hello-node-6ff4d56d4c-c24mf    Successfully assigned default/hello-node-6ff4d56d4c-c24mf to test1
5m34s       Normal    Pulling                   pod/hello-node-6ff4d56d4c-c24mf    Pulling image "gcr.io/hello-minikube-zero-install/hello-node"
4m12s       Normal    Pulled                    pod/hello-node-6ff4d56d4c-c24mf    Successfully pulled image "gcr.io/hello-minikube-zero-install/hello-node"
4m11s       Normal    Created                   pod/hello-node-6ff4d56d4c-c24mf    Created container hello-node
4m11s       Normal    Started                   pod/hello-node-6ff4d56d4c-c24mf    Started container hello-node
5m35s       Normal    SuccessfulCreate          replicaset/hello-node-6ff4d56d4c   Created pod: hello-node-6ff4d56d4c-c24mf
5m35s       Normal    ScalingReplicaSet         deployment/hello-node              Scaled up replica set hello-node-6ff4d56d4c to 1

...
```

Maintenant nous allons ouvrir hello-node sur Internet

```
kubectl expose deployment hello-node --port=8080 --type=NodePort
```

```
service/hello-node exposed
```

```
kubectl get svc hello-node
```

```
NAME         TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)          AGE
hello-node   NodePort   10.43.75.191   <none>        8080:32017/TCP   15s
```

```
kubectl get svc hello-node -o yaml | grep nodePort
```

```
  - nodePort: 32017
```

Cela donne un accès à hello-node via n'importe quel IP des noeuds du cluster, sur le port  
affiché sur la toirsième commande (32017).

hello-node est maintenant accessible sans redirection de port.

```
curl http://127.0.0.1:32017
#or
curl http://<IP_DU_NOEUD>:32017
```

```
Hello World!
```

## Cleanup

Supprimer les ressources

```
kubectl delete deployment,service hello-node
