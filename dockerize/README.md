# Dockerize and Registry

## Prérequis

- Avoir un Docker installé sur l'environnement de travail utilisé
- Avoir récupérer le dossiers customer

## Dockerize Spring-boot app

Nous allons ici Dockerize une application Spring-Boot appeler pour pouvoir l'utiliser
dans le lab suivant.

On se rend dans le dossier [customer](customer) là où se situe notre [Dockerfile](customer/Dockerfile)

```
docker build -t customer-backend:1.0 .
```

```
...
...

Successfully built 8160f94f231e
Successfully tagged customer-backend:1.0
```

Ensuite on s'authentifie sur une registry (ici la Docker Registry public de Docker, le Dockerhub

```
docker login
```

```
Login Succeeded
```

Ensuite pour créer un répository sur son compte : 

```
docker tag local-image:tagname new-repo:tagname
docker push new-repo:tagname
```

Dans notre exemple :

```
docker tag customer-backend:1.0 thomasvillaldea/customer-backend:lastest
docker push thomasvillaldea/customer-backend:lastest
```

```
The push refers to repository [docker.io/thomasvillaldea/customer-backend]
22229a10ab48: Pushed
ac3ff680f7ef: Pushed
12c374f8270a: Pushed
0c3170905795: Pushed
df64d3292fd6: Pushed
lastest: digest: sha256:dd8e9eae9028aef39f76750db47b779b1a6472fd97548c0769fd1f30b09f0b7e size: 1366
```

Notre image est maintenant accessible de l'extérieur.
Ici il s'agit d'un répository public accessible par tout le monde
Mais il est possible d'utilisé des repo privée. Ils en existent plusieurs comme
la Docker Trust Registry (DTR), Harbor, Nexus, Artifactory...


## Demo Harbor

## Registries and Rancher

## Helm
