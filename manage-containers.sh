#!/bin/bash

# Fonction pour lister les conteneurs
list_containers() {
    echo "Listing all containers:"
    docker ps -a
}

# Fonction pour ajouter un conteneur
add_container() {
    read -p "Enter container name: " container_name
    read -p "Enter image name: " image_name
    read -p "Enter the port to map: " port
    docker run -d --name "$container_name" -p "$port:80" "$image_name"
    echo "Container $container_name added successfully!"
}

# Fonction pour arrêter et supprimer un conteneur
stop_container() {
    read -p "Enter container name to stop and remove: " container_name
    docker stop "$container_name"
    docker rm "$container_name"
    echo "Container $container_name removed successfully!"
}

# Boucle principale
while true; do
    echo -e "\n1. List containers"
    echo "2. Add a container"
    echo "3. Remove a container"
    echo "4. Exit"
    
    read -p "Enter your choice: " choice

    case "$choice" in
        1) list_containers ;;
        2) add_container ;;
        3) stop_container ;;
        4) echo "Exiting..."; break ;;
        *) echo "Invalid choice, please try again." ;;
    esac
done
