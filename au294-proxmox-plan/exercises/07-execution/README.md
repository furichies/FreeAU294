# Ejercicio 7.1: Etiquetas (Tags)

## Objetivo
Usar etiquetas para controlar qué tareas se ejecutan en un playbook.

## Conceptos Cubiertos
- Etiquetas en tareas
- Etiquetas en plays
- Ejecución selectiva con `--tags`
- Exclusión de etiquetas con `--skip-tags`

## Sintaxis
```yaml
tasks:
  - name: Instalar paquetes
    yum:
      name: "{{ item }}"
    loop:
      - nginx
    tags:
      - install
      - packages

  - name: Configurar firewall
    firewalld:
      service: http
    tags:
      - configure
      - security
```

## Ejecución
```bash
# Solo ejecutar tareas con tag 'install'
ansible-playbook playbook.yml --tags install

# Omitir tareas con tag 'security'
ansible-playbook playbook.yml --skip-tags security

# Listar todas las etiquetas
ansible-playbook playbook.yml --list-tags
```

## Ejemplo de Uso
```bash
ansible-playbook exercises/07-execution/exercise-7.1-tags.yml --tags packages
```
