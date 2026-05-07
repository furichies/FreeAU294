# Ejercicio 3.1: Variables en Ansible

## Objetivo
Aprender a definir y utilizar variables en playbooks de Ansible.

## Conceptos Cubiertos
- Variables de playbook
- Variables de inventario
- Variables dinámicas (set_fact)
- Variable `ansible_facts`

## Tipos de Variables
1. **Inventory variables**: Definidas en el inventario
2. **Play variables**: Definidas en la sección `vars`
3. **Task variables**: Generadas con `set_fact`
4. **Registered variables**: Almacenadas con `register`

## Ejecución
```bash
ansible-playbook exercises/03-variables/exercise-3.1-variables.yml
```

## Exploración
```bash
# Ver todas las variables disponibles
ansible managed-node-01 -m setup

# Filtrar facts específicos
ansible managed-node-01 -m setup -a "filter=*ipv4*"
```

## Ejemplos de Uso
```yaml
# Acceso a facts
{{ ansible_facts.hostname }}
{{ ansible_facts.default_ipv4.address }}

# Acceso a variables
{{ variable_name }}

# Filtros Jinja2
{{ value | default('fallback') }}
{{ list | join(', ') }}
```
