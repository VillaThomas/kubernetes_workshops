# First Interaction with a cluster

## Pr�requis

- SSH acc�s � la machine d'un noeud
- le Fichier Kubeconfig du cluster
- L'url et les cr�dentials de Rancher.

## Se connecter � la machine

La cl� sera fournit sur demande pour les machines.

```
ssh <USER>:<IP_MACHINE> -i <PEM_KEY>
```
Sur la machine, un cluster Kubernetes d'un seul noeud est d�j� install�.

Pour v�rifier que des conteneurs tournent d�j� : 

```
docker ps
```

##Installer Kubectl

La documentation officiel du Kubernetes : [Installer et configurer kubectl](https://kubernetes.io/fr/docs/tasks/tools/install-kubectl/)

T�l�charger la derni�re Release, rendre le binaire ex�cutable, d�placer le binaire dans le PATH.

```
curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
kubectl version
```
Il est ensuite possible d'int�rragir directement avec le cluster en passant le fichier de configuration en param�tre.

```
kubectl --kubeconfig kube_config_cluster.yml get all --all-namespaces
```

##Ajouter les configurations du Cluster

Pour �viter de devoir pr�ciser � chaque fois le fichier de configuration pour interagir avec le cluster, mettre dans le dossier �~/.kube/ � le fichier kube_config_cluster.yml avec comme nouveau nom � kube-workshop �.

Exporter la variable suivante :

```
export KUBECONFIG=~/.kube/kube-workshop
```

Choisir le contexte avec kubectl pour pr�ciser quel cluster � administrer :

```
kubectl config use-context local
```

V�rifier en r�cup�rant les noeuds du cluster.

```
kubectl get nodes
```

##Rancher

Se connecter � l'IHM de Rancher et naviguer.



