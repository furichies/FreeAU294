# Ejercicio 1.1: Verificar Instalación de Ansible

## Objetivo
Verificar que Ansible esté correctamente instalado en el nodo de control y conocer su versión.

## Conceptos Cubiertos
- Instalación de Ansible
- Comandos de verificación básicos
- Gestión de versiones de Python

## Requisitos
- Acceso SSH al nodo de control (`ansible-control`)
- Ansible instalado (ansible-core 2.14+)

## Ejecución
```bash
cd ~/ansible-au294
ansible-playbook exercises/01-intro/exercise-1.1-verify-ansible.yml
```

## Verificación
Al finalizar,，你应该 ver:
- Versión de Ansible instalada
- Versión de Python compatible
- Lista de módulos disponibles

## Comandos Alternativos
```bash
ansible --version
ansible-doc -l | head -20
python3 --version
```
