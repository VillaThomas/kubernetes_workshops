# Quickstart

## Prérequis

- Avoir un cluster opérationnel ainsi que kubectl configuré pour intéragir ave ce cluster

## Lab

Le conteneur utilisé pour ce lab est [Party-clippy](https://github.com/jessfraz/party-clippy). Il s'agit d'un petit serveur web qui écoute sur le port 8080.

Lancer l'application Party-clippy dans un conteneur.

```
kubectl run party-clippy --image=jessfraz/party-clippy:latest
```

```
deployment "party-clippy" created
```

Afficher les déploiements

```
kubectl get deployments
```

```
NAME           DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
party-clippy   1         1         1            1           1m
```

Afficher les pods
```
kubectl get pods
```

```
NAME                            READY     STATUS    RESTARTS   AGE
party-clippy-3295177660-xg5t2   1/1       Running   0          55s
```

Vérifier les logs du conteneur, on utilise directement le nom du pod ci dessus.

```
kubectl logs party-clippy-3295177660-xg5t2
```

```
TODO METTRE LES LOGS
```

Pour vérifier si party-clippy fonctionne bien, nous allons faire une redirection de port entre la machine et le conteneur.

```
kubectl port-forward party-clippy-3295177660-xg5t2 3000:8080
```

```
I0407 10:41:41.872146   15115 portforward.go:213] Forwarding from 127.0.0.1:3000 -> 8080
I0407 10:41:41.872238   15115 portforward.go:213] Forwarding from [::1]:3000 -> 8080
I0407 10:41:50.548148   15115 portforward.go:247] Handling connection for 3000
I0407 10:41:50.553497   15115 portforward.go:247] Handling connection for 3000
I0407 10:41:51.068845   15115 portforward.go:247] Handling connection for 3000
...
```
Dans un navigateur, visiter `http://localhost:8080/` ou via un  curl.

```
curl http://localhost:8080/
```

Faire Ctrl-c pour annuler la redirection.

Maintenant nous allons ouvrir Party-clippy sur Internet

```
kubectl expose deployment party-clippy --port=8080 --type=NodePort
kubectl get svc party-clippy -o yaml | grep nodePort
```

Cela donne un accès à Party-clippy via n'importe quel IP des noeuds du cluster, sur le port  
affiché sur la deuxième commande.

Party-clippy est maintenant accessible sans redirection de port.

## Cleanup

Supprimer les ressources

```
kubectl delete deployment,service party-clippy
