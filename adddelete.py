import os

def list_containers():
    os.system("docker ps")

def add_container(container_name, image_name):
    os.system(f"docker run -d --name {container_name} {image_name}")
    
def access_container():
    os.system(f"docker exec -it dind-container /bin/sh")

def stop_container(container_name):
    os.system(f"docker stop {container_name}")
    os.system(f"docker rm {container_name}")

while True:
    print("\n1. List containers")
    print("2. Add a container")
    print("3. Remove a container")
    print("4. Access container")
    print("5. Exit")
    
    choice = input("Enter your choice: ")

    if choice == '1':
        list_containers()
    elif choice == '2':
        container_name = input("Enter container name: ")
        image_name = input("Enter image name: ")
        add_container(container_name, image_name)
    elif choice == '3':
        container_name = input("Enter container name to stop and remove: ")
        stop_container(container_name)
    elif choice == '4':
        access_container()
    elif choice == '5':
        break
    else:
        print("Invalid choice, please try again.")
