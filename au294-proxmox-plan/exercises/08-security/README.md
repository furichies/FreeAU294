# Ejercicio 8.1: Ansible Vault

## Objetivo
Proteger información sensible usando Ansible Vault.

## Conceptos Cubiertos
- Cifrado de archivos con vault
- Variables sensibles
- Uso de `vars_files` cifrados
- Comandos de gestión de vault

## Comandos de Ansible Vault
```bash
# Crear archivo nuevo cifrado
ansible-vault create secrets.yml

# Editar archivo cifrado
ansible-vault edit secrets.yml

# Cifrar archivo existente
ansible-vault encrypt secrets.yml

# Ver contenido cifrado
ansible-vault view secrets.yml

# Descifrar archivo
ansible-vault decrypt secrets.yml

# Cambiar contraseña
ansible-vault rekey secrets.yml
```

## Ejecución
```bash
# Crear vault
ansible-vault create vars_files/secrets.yml

# Ejecutar con vault
ansible-playbook playbook.yml --ask-vault-pass

# O usar archivo de contraseña
ansible-playbook playbook.yml --vault-password-file ~/.vault_pass
```

## Buenas Prácticas
- Nunca guardar archivos vault en git sin cifrar
- Usar archivos de contraseña en lugar de `--ask-vault-pass`
- Rotar contraseñas periódicamente
