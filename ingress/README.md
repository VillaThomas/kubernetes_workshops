# Ingress

## Prérequis

- Avoir un cluster opérationnel ainsi que kubectl configuré pour intéragir ave ce cluster

## Lab

Dans ce lab nous verrons quelques règles d'ingress.
Nous allons créer deux Deployment et deux Services : [tea et coffee](coffee-tea.yaml)

```
kubectl create -f ./coffee-tea.yaml
```
```
deployment.extensions/coffee created
service/coffee-svc created
deployment.extensions/tea created
service/tea-svc created
```

### Routing by Path

On utilise [ingress-path.yaml](ingress-path.yaml), On va pouvoir distinguer selon le path à quel service
accéder.

```
kubectl create -f ./ingress-path.yaml
```
```
ingress.extensions/coffee-tea-ingress created
```

```
kubectl get ingress
```
```
NAME                 HOSTS   ADDRESS        PORTS   AGE
coffee-tea-ingress   *       192.168.1.44   80      24m
```

On va tenter de requêter notre nos service.

```
curl http://127.0.0.1:80
```
```
default backend - 404
```

Cela signifie que notre URL ne correspond à aucune règle ingress on arrive donc sur la réponse par défaut 
des Ingress Controller.

```
curl http://127.0.0.1:80/tea
```
```
Server address: 10.42.0.52:80
Server name: tea-5857f7786b-z97b6
Date: 22/Sep/2019:23:14:15 +0000
URI: /tea
Request ID: d3f0b86bce858d8d14c3c5d950324fe7
```

