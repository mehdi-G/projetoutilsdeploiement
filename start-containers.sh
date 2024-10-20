#!/bin/bash

# Stopper et supprimer tous les conteneurs existants
echo "Arrêt et suppression de tous les conteneurs existants..."
docker ps -aq | xargs -r docker stop
docker ps -aq | xargs -r docker rm

# Demander à l'utilisateur combien de conteneurs il souhaite créer
echo "Combien de conteneurs souhaitez-vous créer ?"
read -p "Entrez le nombre de conteneurs : " num_containers

# Créer un réseau Docker si ce n'est pas déjà fait
echo "Création du réseau Docker..."
docker network create my_network || true

# Lancer les conteneurs avec des noms dynamiques (web1, web2, ...)
echo "Lancement des conteneurs..."
for i in $(seq 1 $num_containers); do
    container_name="web$i"
    echo "Lancement du conteneur $container_name..."
    docker run -d --name "$container_name" --network my_network alpine /bin/sh -c "while true; do sleep 30; done"
done

# Demander à l'utilisateur sur quel conteneur installer Ansible
echo "Choisissez un conteneur pour installer Ansible :"
read -p "Entrez le nom du conteneur (par ex: web1, web2, etc.) : " chosen_container

# Vérifier si le conteneur existe
if [ "$(docker ps -q -f name=$chosen_container)" ]; then
    echo "Installation d'Ansible dans le conteneur $chosen_container..."
    docker exec $chosen_container sh -c "apk add --no-cache ansible openssh sshpass python3"

    # Vérifier si Ansible est installé
    ansible_installed=$(docker exec $chosen_container ansible --version 2>&1)
    
    if [ "$(echo $ansible_installed | grep 'ansible')" ]; then
        echo "Ansible a été installé avec succès dans le conteneur $chosen_container !"
    else
        echo "Erreur lors de l'installation d'Ansible dans le conteneur $chosen_container."
        echo "Détails : $ansible_installed"
        exit 1
    fi

    # Copier le playbook.yml dans le conteneur choisi
    echo "Copie de send_requests.yml dans le conteneur $chosen_container..."
    docker cp send_requests.yml $chosen_container:/send_requests.yml

    # Installer la clé SSH dans le conteneur choisi
    echo "Génération de la clé SSH dans le conteneur $chosen_container..."
    docker exec $chosen_container sh -c "mkdir -p /root/.ssh && ssh-keygen -t rsa -N '' -f /root/.ssh/id_rsa"

    # Créer le fichier inventory.ini
    echo "Création du fichier inventory.ini dans le conteneur..."
    docker exec $chosen_container sh -c "echo '[webservers]' > /root/inventory.ini"

    # Obtenir les adresses IP des autres conteneurs et les ajouter à inventory.ini
    for i in $(seq 1 $num_containers); do
        container_name="web$i"
        if [ "$container_name" != "$chosen_container" ]; then
            ip_address=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $container_name)
            echo "Ajout de $container_name avec IP: $ip_address dans inventory.ini..."
            docker exec $chosen_container sh -c "echo '$container_name ansible_host=$ip_address ansible_python_interpreter=/usr/bin/python3' >> /root/inventory.ini"
        fi
    done

    echo "Fichier inventory.ini créé dans le conteneur $chosen_container."

    # Installer et démarrer SSH sur tous les conteneurs
    for i in $(seq 1 $num_containers); do
        container_name="web$i"
        echo "Installation de SSH et Python sur $container_name..."
        docker exec $container_name sh -c "apk add --no-cache openssh python3 && ssh-keygen -A && /usr/sbin/sshd"
        
        # Vérifier si SSH est en cours d'exécution
        ssh_running=$(docker exec $container_name ps aux | grep sshd)
        if [ -n "$ssh_running" ]; then
            echo "Le service SSH est en cours d'exécution sur $container_name."
        else
            echo "Erreur : le service SSH n'a pas démarré sur $container_name."
        fi
    done

    # Copier la clé SSH publique dans les autres conteneurs
    for i in $(seq 1 $num_containers); do
        container_name="web$i"
        if [ "$container_name" != "$chosen_container" ]; then
            echo "Copie de la clé SSH publique dans $container_name..."
            docker exec $chosen_container sh -c "cat /root/.ssh/id_rsa.pub" | docker exec -i $container_name sh -c "mkdir -p /root/.ssh && cat >> /root/.ssh/authorized_keys"
            echo "Clé SSH copiée dans $container_name."
        fi
    done

    # Ajouter les adresses IP des conteneurs dans /etc/hosts
    for i in $(seq 1 $num_containers); do
        container_name="web$i"
        ip_address=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $container_name)
        echo "Ajout de $container_name avec IP: $ip_address dans /etc/hosts..."
        docker exec $chosen_container sh -c "echo '$ip_address $container_name' >> /etc/hosts"
    done

    echo "Clé SSH copiée sur les autres conteneurs."

    # --- Partie pour envoyer des requêtes depuis Ansible ---
    # Demander l'adresse IP du conteneur cible-container
    echo "Veuillez entrer l'adresse IP du conteneur cible-container :"
    read -p "Entrez l'IP de cible-container : " cible_ip

    # Demander le nombre de requêtes à envoyer
    echo "Combien de requêtes chaque conteneur doit-il envoyer à cible-container ?"
    read -p "Entrez le nombre de requêtes à envoyer : " nb_requetes

    # Exécuter le playbook Ansible pour envoyer les requêtes
    if docker exec $chosen_container [ -f /send_requests.yml ]; then
        echo "Exécution du playbook Ansible..."
        docker exec $chosen_container sh -c "ansible-playbook -i /root/inventory.ini /send_requests.yml -e 'cible_ip=$cible_ip nb_requetes=$nb_requetes' -e 'ansible_ssh_common_args=\"-o StrictHostKeyChecking=no\"'"
    else
        echo "ERROR! Le playbook: /send_requests.yml est introuvable."
    fi

else
    echo "Le conteneur choisi n'existe pas. Veuillez vérifier le nom et réessayer."
fi
