import requests
import sys

def send_get_requests(num_requests, server_url):
    try:
        for i in range(num_requests):
            response = requests.get(server_url)
            print(f"Requête {i+1}: Statut {response.status_code}")
    except requests.exceptions.RequestException as e:
        print(f"Erreur lors de l'envoi des requêtes - {e}")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python script.py <nombre_de_requetes> <url_du_serveur>")
        sys.exit(1)

    try:
        num_requests = int(sys.argv[1])
    except ValueError:
        print("Erreur: Le nombre de requêtes doit être un entier.")
        sys.exit(1)

    server_url = sys.argv[2]

    send_get_requests(num_requests, server_url)
