# Plan de Ejercicios con Proxmox para el Curso AU294: Red Hat Enterprise Linux Automation with Ansible

## Objetivo
Crear una infraestructura de laboratorio basada en Proxmox VE que permita realizar los ejercicios prácticos del curso AU294, cubriendo todos los temas del temario oficial de Red Hat Enterprise Linux Automation with Ansible.

## Requisitos Previos
- Servidor con virtualización habilitada (VT-x/AMD-V) y al menos 8 GB RAM, 50 GB disco.
- Proxmox VE 8.x instalado y accesible vía web UI.
- Conexión a internet para descargar plantillas y paquetes.
- Conocimientos básicos de Linux y redes.

## Visión General de la Infraestructura
- **Control Node**: VM que servirá como estación de trabajo Ansible (Ansible Engine instalado).
- **Managed Nodos**: VMs que representan sistemas RHEL/CentOS gestionados por Ansible.
- **Red de Laboratorio**: Bridge privado (vmbr1) para aislar el laboratorio y permitir comunicación entre nodos.
- **Plantillas**: Plantilla de RHEL 9 (o CentOS Stream 9) para clonar rápidamente los nodos.

## Paso a Paso para Generar la Infraestructura

### 1. Preparación de Proxmox
1.1 Acceder a la interfaz web de Proxmox (https://<IP_PROXMOX>:8006).
1.2 Crear un bridge privado (vmbr1) sin IP asociada para el laboratorio:
   - Datacenter > <nodo> > System > Network > Create > Linux Bridge
   - ID: vmbr1
   - Dejar campos de IP vacíos.
   - Habilitar "VLAN aware" si se necesita segmentación.

1.3 Descargar o crear una plantilla de VM con RHEL 9 / CentOS Stream 9:
   - Opción A: Importar una imagen cloud (QCOW2) de CentOS Stream 9.
   - Opción B: Crear una VM desde cero, instalar el SO, actualizar y convertir a plantilla.
   - Nombre de la plantilla: `template-rhel9`
   - Asegurar que tenga agente QEMU instalado para mejor integración.

### 2. Creación de Máquinas Virtuales
Crearemos las siguientes VMs:
- **ansible-control** (2 vCPU, 2 GB RAM, 20 GB disco)
- **managed-node-01** (2 vCPU, 2 GB RAM, 20 GB disco)
- **managed-node-02** (2 vCPU, 2 GB RAM, 20 GB disco)
- (Opcional) **managed-node-03** para ejercicios de escalado.

Para cada VM:
2.1 Clone de la plantilla:
   - En la vista de plantillas, right-click > Clone.
   - Asignar nombre, seleccionar modo "Linked Clone" (ahorra espacio) o "Full Clone".
   - Almacenar en el mismo storage que la plantilla.

2.2 Configurar hardware:
   - Procesador: 2 vCPU
   - Memoria: 2048 MB
   - Disco duro: 20 GB (virtIO, cache=writeback)
   - Red: 
     - NIC1: vmbr0 (para acceso externo/internet si se necesita)
     - NIC2: vmbr1 (red de laboratorio)
   - Asegurar que el agente QEMU esté activo.

2.3 Iniciar cada VM y realizar configuración inicial:
   - Asignar direcciones IP estáticas en la red vmbr1 (ej. 10.10.10.10/24 para control, .11/.12 para nodos).
   - Configurar nombre de host adecuado (ansible-control, managed-node-01, etc.)
   - Habilitar SSH y asegurar acceso con clave SSH desde el control node.
   - Actualizar paquetes: `dnf update -y`
   - Instalar paquetes básicos: `dnf install -y python3 python3-pip vim`

### 3. Configuración del Nodo de Control Ansible
3.1 Desde el nodo de control (ansible-control):
   - Instalar Ansible: `dnf install -y ansible-core` o mediante pip: `pip3 install ansible`
   - Verificar instalación: `ansible --version`
   - Crear directorio de trabajo: `mkdir -p ~/ansible-au294 && cd ~/ansible-au294`
   - Configurar inventario inicial:
     ```
     [managed]
     managed-node-01 ansible_host=10.10.10.11
     managed-node-02 ansible_host=10.10.10.12
     ```
   - Probar conectividad: `ansible managed -m ping`

### 4. Estructura de Ejercicios por Tema del Curso AU294
A continuación se detalla cómo mapear cada capítulo del curso a ejercicios prácticos usando la infraestructura anterior.

#### Capítulo 1: Introducción a Ansible
- **Ejercicio 1.1**: Instalar Ansible y verificar versión.
- **Ejercicio 1.2**: Ejecutar comandos ad-hoc simples: `ansible managed -a "hostname"`.
- **Ejercicio 1.3**: Crear inventario estático y dinámico (script que lea de Proxmox API opcional).

#### Capítulo 2: Implementación de Playbooks
- **Ejercicio 2.1**: Crear primer playbook `hello.yml` que imprima un mensaje.
- **Ejercicio 2.2**: Usar módulos básicos (`copy`, `yum`, `service`, `user`).
- **Ejercicio 2.3**: Ejecutar playbook en nodos gestionados y verificar cambios.

#### Capítulo 3: Gestión de Variables e Inclusiones
- **Ejercicio 3.1**: Definir variables a nivel de playbook e inventory.
- **Ejercicio 3.2**: Usar `vars_files` y `include_vars`.
- **Ejercicio 3.3**: Ejercicio de plantillas Jinja2 con `template` module para crear `/etc/motd` personalizado.

#### Capítulo 4: Control de Tareas con Loops y Conditionals
- **Ejercicio 4.1**: Instalar múltiples paquetes usando `loop`.
- **Ejercicio 4.2**: Crear usuarios condicionalmente basado en variable de grupo.
- **Ejercicio 4.3**: Usar `when` con hechos de Ansible (`ansible_facts.distribution`).

#### Capítulo 5: Plantillas Jinja2 Avanzadas
- **Ejercicio 5.1**: Generar archivo de configuración de httpd usando plantilla.
- **Ejercicio 5.2**: Usar filtros Jinja2 (`to_json`, `from_yaml`, `ipaddr`).
- **Ejercicio 5.3**: Plantilla anidada (include dentro de template).

#### Capítulo 6: Roles y Ansible Galaxy
- **Ejercicio 6.1**: Crear rol llamado `webserver` con estructura estándar (tasks, handlers, templates, vars).
- **Ejercicio 6.2**: Descargar un rol de Galaxy (ej. `geerlingguy.apache`) y usarlo en un playbook.
- **Ejercicio 6.3**: Crear rol reusable para configurar NTP y aplicarlo a todos los nodos.

#### Capítulo 7: Gestión de la Ejecución de Playbooks
- **Ejercicio 7.1**: Usar etiquetas (`tags`) para ejecutar partes específicas.
- **Ejercicio 7.2**: Control de salto de ejecución con `--start-at-task`.
- **Ejercicio 7.3**: Ejecutar en modo check (`--check`) y modo diff (`--diff`).

#### Capítulo 8: Ansible para la Seguridad y Optimización
- **Ejercicio 8.1**: Configurar firewall con módulo `firewalld` (puertos HTTP/HTTPS).
- **Ejercicio 8.2**: Implementar manejo de contraseñas con `ansible-vault`.
- **Ejercicio 8.3**: Optimizar ejecución con estrategias (`free`, `linear`) y plugins de mitigación de fugas.

#### Capítulo 9: Automatización de Tareas de Administración de Linux RHCSA/RHCE
- **Ejercicio 9.1**: Gestionar usuarios y grupos (crear, modificar, borrar).
- **Ejercicio 9.2**: Configurar almacenamiento (crear particiones, LVM, montajes en `/etc/fstab`).
- **Ejercicio 9.3**: Configuración de red estática y dinámica con `nmstate` o `network` RHEL roles.

#### Capítulo 10: Integración con Otras Tecnologías (Opcional)
- **Ejercicio 10.1**: Desplegar una aplicación web contenedorizada (podman/docker) usando Ansible.
- **Ejercicio 10.2**: Interactuar con APIs (ej. crear VM en Proxmox vía módulo community.general.proxmox).
- **Ejercicio 10.3**: Registrar resultados en un servidor de logs centralizado (ELK o Loki opcional).

### 5. Scripts de Apoyo (Opcional)
Crear scripts para automatizar la puesta en marcha del laboratorio:

- `setup-proxmox-lab.sh`: Crea bridge, descarga plantilla, clona VMs, asigna IPs.
- `reset-lab.sh`: Revierte VMs a snapshots previos o elimina y vuelve a crear.
- `inventory-gen.py`: Genera archivo inventory.ini consultando Proxmox API para IPs dinámicas.

### 6. Consideraciones de Seguridad y Buenas Prácticas
- Utilizar usuarios no root con sudo en nodos gestionados.
- Gestionar claves SSH mediante Ansible (`authorized_key` módulo).
- Cifrar datos sensibles con Ansible Vault.
- Mantener snapshots de cada VM antes de ejercicios críticos para permitir rollback.

### 7. Evaluación y Cierre
Al finalizar cada bloque de ejercicios, se recomienda:
- Revisar los cambios realizados en los nodos (archivos de configuración, servicios activos).
- Documentar lecciones aprendidas y posibles variaciones.
- Preparar un pequeño "capstone" que integre múltiples conceptos (ej. desplegar una pila LAMP completa).

## Conclusión
Con este plan, el instructor o estudiante podrá montar un laboratorio totalmente funcional basado en Proxmox VE para impartir o seguir el curso AU294 de manera práctica, cubriendo todos los objetivos de aprendizaje mediante ejercicios progresivos y realistas.

---
*Documento generado el $(date). Ajustar versiones de software según disponibilidad en el momento de la implementación.*