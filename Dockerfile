# Utiliser l'image officielle Docker in Docker (DinD)
FROM docker:dind

# Installer des dépendances supplémentaires si nécessaire (optionnel)
RUN apk add --no-cache bash

# Copier un script pour démarrer des conteneurs dans le conteneur DinD
COPY start-containers.sh /start-containers.sh
RUN chmod +x /start-containers.sh && ls -l /

COPY send_requests.yml /send_requests.yml
RUN chmod +x /send_requests.yml 

COPY a.py /a.py
RUN chmod +x /a.py 


# Exposer le port Docker (optionnel)
EXPOSE 2375

# Démarrer Docker Daemon et exécuter le script qui lance les 3 conteneurs
CMD ["sh", "-c", "dockerd & sleep 5 && /start-containers.sh && tail -f /dev/null"]
