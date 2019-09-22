# First Interaction with a cluster

## Prérequis

- SSH accès à la machine d'un noeud
- L'url et les crédentials de Rancher.

## Se connecter à la machine

La clé sera fournit sur demande pour les machines.

```
ssh <USER>:<IP_MACHINE> -i <PEM_KEY>
```
Sur la machine, un cluster Kubernetes d'un seul noeud est déjà installé.

Pour vérifier que des conteneurs tournent déjà : 

```
docker ps
```

## Installer Kubectl

La documentation officiel du Kubernetes : [Installer et configurer kubectl](https://kubernetes.io/fr/docs/tasks/tools/install-kubectl/)

Télécharger la dernière Release, rendre le binaire exécutable, déplacer le binaire dans le PATH.

```
curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
kubectl version
```

Récupérer le fichier Kubeconfig 

```
kubectl --kubeconfig <NOM DU FICHIER> --all-namespaces
```

## Ajouter les configurations du Cluster

Pour éviter de devoir préciser à chaque fois le fichier de configuration pour interagir avec le cluster, mettre «~/.kube/ » le fichier kube_config_cluster.yml avec comme nouveau nom « config ».

```
kubectl version
```

```
Client Version: version.Info{Major:"1", Minor:"16", GitVersion:"v1.16.0", GitCommit:"2bd9643cee5b3b3a5ecbd3af49d09018f0773c77", GitTreeState:"clean", BuildDate:"2019-09-18T14:36:53Z", GoVersion:"go1.12.9", Compiler:"gc", Platform:"linux/amd64"}
Server Version: version.Info{Major:"1", Minor:"14", GitVersion:"v1.14.6", GitCommit:"96fac5cd13a5dc064f7d9f4f23030a6aeface6cc", GitTreeState:"clean", BuildDate:"2019-08-19T11:05:16Z", GoVersion:"go1.12.9", Compiler:"gc", Platform:"linux/amd64"}
```

Vérifier en récupérant les noeuds du cluster.

```
kubectl get nodes
```

## Rancher

Se connecter à l'IHM de Rancher et naviguer.
