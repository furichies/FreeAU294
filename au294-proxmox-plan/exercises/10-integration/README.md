# Ejercicio 10.1: Contenedores con Podman

## Objetivo
Desplegar aplicaciones contenerizadas usando Ansible y Podman.

## Conceptos Cubiertos
- Instalación de Podman
- Descarga de imágenes
- Creación y gestión de contenedores
- Mapeo de puertos
- Volumes

## Comandos de Podman
```bash
# Descargar imagen
podman pull nginx:alpine

# Listar imágenes
podman images

# Iniciar contenedor
podman run -d --name webapp -p 8080:80 nginx:alpine

# Ver contenedores
podman ps -a

# Detener contenedor
podman stop webapp

# Eliminar contenedor
podman rm webapp
```

## Ejecución
```bash
ansible-playbook exercises/10-integration/exercise-10.1-container.yml
```

## Verificación
```bash
curl http://10.10.10.11:8080
podman ps
```
