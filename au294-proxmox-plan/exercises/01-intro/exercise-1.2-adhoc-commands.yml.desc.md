# Ejercicio 1.2: Comandos Ad-Hoc

## Objetivo
Ejecutar comandos Ansible directamente desde la línea de comandos sin necesidad de playbooks.

## Conceptos Cubiertos
- Comandos `ansible` directos
- Módulo `ping`
- Recopilación de hechos (facts)
- Comandos shell

## Requisitos
- Inventario configurado con nodos gestionados
- Conectividad SSH a los nodos

## Ejecución
```bash
# Ping a todos los nodos
ansible all -m ping

# Ver hostname
ansible managed -m command -a "hostname"

# Ver facts de un nodo
ansible managed-node-01 -m setup

# Comando ad-hoc con shell
ansible managed -m shell -a "df -h | grep '/$'"
```

## Con el Playbook
```bash
ansible-playbook exercises/01-intro/exercise-1.2-adhoc-commands.yml
```

## Verificación
- Todos los nodos deben responder al ping
- Los facts deben mostrar información del sistema

## Desafío Adicional
Ejecutar un comando para instalar un paquete:
```bash
ansible managed -m yum -a "name=htop state=present" -b
```
