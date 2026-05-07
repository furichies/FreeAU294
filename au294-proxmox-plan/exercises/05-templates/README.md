# Ejercicio 5.1: Plantillas Jinja2

## Objetivo
Crear archivos de configuración dinámicos usando plantillas Jinja2.

## Conceptos Cubiertos
- Plantillas Jinja2 (`.j2`)
- Módulo `template`
- Variables en plantillas
- Condicionales en plantillas
- Bucles en plantillas

## Estructura de Plantilla
```jinja2
# Comentario Jinja2
{{ variable }}
{% if condition %}
  contenido
{% endif %}
{% for item in list %}
  - {{ item }}
{% endfor %}
```

## Ejecución
```bash
ansible-playbook exercises/05-templates/exercise-5.1-apache-template.yml
```

## Archivos Generados
- `/etc/httpd/conf.d/au294.conf`

## Desafíos
1. Agregar más configuraciones al virtualhost
2. Incluir certificados SSL
3. Personalizar según variables
