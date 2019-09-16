# First Interaction with a cluster

## Prérequis

- SSH accès à la machine d'un noeud
- le Fichier Kubeconfig du cluster
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

##Installer Kubectl

La documentation officiel du Kubernetes : [Installer et configurer kubectl](https://kubernetes.io/fr/docs/tasks/tools/install-kubectl/)

Télécharger la dernière Release, rendre le binaire exécutable, déplacer le binaire dans le PATH.

```
curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
kubectl version
```
Il est ensuite possible d'intérragir directement avec le cluster en passant le fichier de configuration en paramètre.

```
kubectl --kubeconfig kube_config_cluster.yml get all --all-namespaces
```

##Ajouter les configurations du Cluster

Pour éviter de devoir préciser à chaque fois le fichier de configuration pour interagir avec le cluster, mettre dans le dossier «~/.kube/ » le fichier kube_config_cluster.yml avec comme nouveau nom « kube-workshop ».

Exporter la variable suivante :

```
export KUBECONFIG=~/.kube/kube-workshop
```

Choisir le contexte avec kubectl pour préciser quel cluster à administrer :

```
kubectl config use-context local
```

Vérifier en récupérant les noeuds du cluster.

```
kubectl get nodes
```

##Rancher

Se connecter à l'IHM de Rancher et naviguer.



