# Capítulo 6: Desarrollo de Contenido a Escala

## Importación de playbooks

### include_tasks (dinámico — runtime)
```yaml
# tasks/install.yml
- name: Instalar paquetes comunes
  dnf:
    name:
      - vim
      - git
    state: present

- name: Configurar sysctl
  sysctl:
    name: net.ipv4.ip_forward
    value: '1'
```

```yaml
# playbook-principal.yml
- name: Configurar servidor
  hosts: all
  become: yes
  tasks:
    - name: Cargar tareas de instalación
      include_tasks: tasks/install.yml
      when: ansible_os_family == "RedHat"

    - name: Cargar tareas específicas
      include_tasks: "tasks/{{ role }}.yml"
      when: role is defined
```

### import_tasks (estático — parse time)
```yaml
- name: Play con importación estática
  hosts: all
  become: yes
  tasks:
    - name: Importar tareas de seguridad
      import_tasks: tasks/security.yml

    - name: Importar tareas de monitorización
      import_tasks: tasks/monitoring.yml
      tags: monitoring
```

### Diferencia clave

| Característica | include_tasks | import_tasks |
|---------------|---------------|--------------|
| Momento de carga | En ejecución (runtime) | En parseo (compile time) |
| Bucles | Sí (`loop` + `include_tasks`) | No |
| Condicionales | Se evalúa en cada host | Se evalúa una vez |
| Tags | Se heredan en tiempo real | Se aplican en estático |
| Rendimiento | Ligero | Puede ralentizar el parseo |

## Include y loops dinámicos

```yaml
- name: Incluir tareas por cada usuario
  include_tasks: tasks/create_user.yml
  loop: "{{ users }}"
  loop_control:
    loop_var: current_user
  vars:
    users:
      - alice
      - bob
      - charlie
```

```yaml
# tasks/create_user.yml
- name: Crear usuario {{ current_user }}
  user:
    name: "{{ current_user }}"
    state: present
```

## Patrones avanzados de hosts

```yaml
- hosts: "{{ target_hosts | default('all') }}"

- hosts: webservers:&production:!datacenter_a

- hosts: ~^(web|db).*\.example\.com$

- hosts: "*.{{ region }}.example.com"
  vars:
    region: europe
```

```bash
# Límite en línea de comandos
ansible-playbook playbook.yml --limit webservers
ansible-playbook playbook.yml --limit rhel-node1
ansible-playbook playbook.yml --limit "*.example.com"
ansible-playbook playbook.yml --limit @retry_hosts.txt
```

## Estrategias (strategies)

| Estrategia | Descripción |
|------------|-------------|
| `linear` | Por defecto. Espera a que todos los hosts terminen cada tarea |
| `free` | Cada host avanza a su ritmo sin esperar a los demás |
| `batch` | Ejecuta por lotes (rolling update) |

```yaml
- name: Rolling update con batch
  hosts: webservers
  strategy: linear
  serial:
    - 1       # 1 host primero
    - 2       # luego 2 hosts
    - "50%"   # luego 50% restante
  tasks:
    - name: Actualizar servicio
      systemd:
        name: app
        state: restarted

    - name: Verificar salud
      uri:
        url: http://localhost/health
        status_code: 200
```

## Include_vars

```yaml
- name: Cargar variables dinámicamente
  hosts: all
  tasks:
    - name: Incluir variables por entorno
      include_vars:
        dir: vars/{{ env }}
        extensions:
          - yml
          - json
      when: env is defined

    - name: Incluir archivo específico
      include_vars:
        file: "secrets/{{ inventory_hostname }}.yml"
      when: inventory_hostname in groups.webservers
```

## Delegación y paralelismo

```yaml
- name: Ejecución paralela
  hosts: all
  tasks:
    - name: Actualizar repositorio en paralelo
      dnf:
        update_cache: yes

- name: Ejecución secuencial (1 a 1)
  hosts: webservers
  serial: 1
  tasks:
    - name: Reinicio gradual
      systemd:
        name: app
        state: restarted

- name: Delegación condicional
  hosts: all
  tasks:
    - name: Hacer backup
      command: /usr/bin/backup.sh
      delegate_to: backup-server
      run_once: yes
```

## Gestión de proyectos grandes

```yaml
proyecto/
├── ansible.cfg
├── inventory/
│   ├── production/
│   │   ├── hosts
│   │   ├── group_vars/
│   │   └── host_vars/
│   └── staging/
│       ├── hosts
│       ├── group_vars/
│       └── host_vars/
├── playbooks/
│   ├── site.yml
│   ├── webservers.yml
│   └── databases.yml
├── roles/
│   ├── common/
│   ├── nginx/
│   └── postgresql/
├── tasks/
│   ├── security.yml
│   └── monitoring.yml
├── templates/
├── files/
└── vars/
    ├── common.yml
    └── secrets.yml
```
