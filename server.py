from http.server import BaseHTTPRequestHandler, HTTPServer
import logging

# Liste pour stocker les messages
messages = []

class SimpleHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-type", "text/html")
        self.end_headers()

        # Afficher tous les messages reçus
        if messages:
            response = "<h1>Messages reçus :</h1>"
            for idx, message in enumerate(messages, 1):
                response += f"<p>{idx}. {message}</p>"
        else:
            response = "<h1>Aucun message reçu pour le moment.</h1>"

        self.wfile.write(response.encode('utf-8'))

    def do_POST(self):
        # Lire la longueur du contenu envoyé dans la requête
        content_length = int(self.headers['Content-Length'])
        # Lire le contenu
        post_data = self.rfile.read(content_length).decode('utf-8')

        # Ajouter le message à la liste
        messages.append(post_data)

        # Afficher le message reçu dans la console du serveur
        logging.info("Message reçu: %s", post_data)

        # Répondre avec un message de confirmation encodé en bytes
        self.send_response(200)
        self.send_header("Content-type", "text/html")
        self.end_headers()
        response = "Message reçu avec succès!"
        self.wfile.write(response.encode('utf-8'))

def run(server_class=HTTPServer, handler_class=SimpleHandler, port=8080):
    logging.basicConfig(level=logging.INFO)
    server_address = ('', port)
    httpd = server_class(server_address, handler_class)
    logging.info("Démarrage du serveur sur le port %d...", port)
    httpd.serve_forever()

if __name__ == "__main__":
    run()
