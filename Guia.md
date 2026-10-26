# Guía paso a paso: preparación, configuración y despliegue

Esta guía describe la preparación del servidor y del cliente, la configuración del proyecto Ansible y la verificación del despliegue de los servicios.

## FASE 1: Pasos previos en el servidor y el cliente

Antes de ejecutar Ansible, es necesario preparar la conectividad y la infraestructura básica entre el servidor y el cliente.

### 1.1. Configuración de acceso SSH

En el servidor, genera una clave SSH si todavía no dispones de una:

```bash
ssh-keygen -t rsa -b 4096
```

Copia la clave pública al usuario `client` del cliente:

```bash
ssh-copy-id client@192.168.11.156
```

Verifica que puedes conectarte sin introducir la contraseña:

```bash
ssh client@192.168.11.156 "hostname"
```

### 1.2. Configuración de sudo sin contraseña en el cliente

En la máquina cliente (`192.168.11.156`), accede como `root` y permite que el usuario `client` ejecute comandos administrativos mediante `sudo` sin requerir contraseña.

Crea el archivo `/etc/sudoers.d/client` con el siguiente contenido:

```text
client ALL=(ALL) NOPASSWD: ALL
```

A continuación, establece los permisos adecuados:

```bash
chmod 0440 /etc/sudoers.d/client
```

> **Importante:** Comprueba la sintaxis del archivo sudoers antes de cerrar la sesión de `root`:
>
> ```bash
> visudo -c -f /etc/sudoers.d/client
> ```

### 1.3. Creación de la clave secreta para Ansible Vault

En el servidor, dentro del directorio del proyecto `/home/server/ASO/ansible/`, crea el archivo oculto que almacenará la contraseña maestra de Ansible Vault:

```bash
cd /home/server/ASO/ansible/

# Reemplaza TU_CONTRASEÑA por la contraseña con la que creaste vault.yml
echo "TU_CONTRASEÑA" > .vault_pass
chmod 600 .vault_pass
```

> **Importante:** No subas `.vault_pass` al repositorio. Añádelo al archivo `.gitignore` si es necesario.

## FASE 2: Configuración de los archivos del proyecto

### 2.1. Configuración de `ansible.cfg`

Edita o crea el archivo `ansible.cfg` en la raíz del proyecto para configurar la contraseña de Vault, optimizar el tiempo de ejecución y definir la escalada de privilegios:

```ini
[defaults]
inventory = hosts
vault_password_file = .vault_pass
host_key_checking = False
interpreter_python = auto_silent
forks = 10

[privilege_escalation]
become = True
become_method = sudo
become_user = root
become_ask_pass = False

[ssh_connection]
pipelining = True
```

### 2.2. Configuración del inventario `hosts`

Edita el archivo `hosts` para definir el grupo de clientes y el usuario SSH de conexión.

No coloques contraseñas en texto plano en este archivo.

```ini
[clientes]
192.168.11.156 ansible_user=client
```

### 2.3. Estructura de variables

La estructura recomendada para las variables es la siguiente:

```text
group_vars/
└── all/
    ├── vars.yml
    └── vault.yml
```

#### Variables públicas: `group_vars/all/vars.yml`

```yaml
---
system_user: "knowles"
samba_share_path: "/srv/samba/compartida"
samba_create_mask: "0775"
samba_directory_mask: "0775"
```

#### Variables cifradas: `group_vars/all/vault.yml`

Edita este archivo utilizando Ansible Vault:

```bash
ansible-vault edit group_vars/all/vault.yml
```

Contenido esperado:

```yaml
vault_db_user: "knowles"
vault_db_password: "Hola123"
vault_samba_password: "Hola123"
```

> **Recomendación:** En un entorno real, utiliza contraseñas robustas y diferentes para cada servicio. No guardes contraseñas reales sin cifrar en el repositorio.

## FASE 3: Ejecución y verificación

### 3.1. Prueba de conectividad inicial

Ejecuta el módulo `ping` para confirmar que el servidor puede conectarse por SSH y elevar privilegios correctamente:

```bash
ansible clientes -m ping
```

Respuesta esperada:

```json
192.168.11.156 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

### 3.2. Ejecución del despliegue principal

Para instalar y configurar todos los servicios —FTP, Samba, LAMP y phpMyAdmin— ejecuta:

```bash
ansible-playbook site.yml
```

### 3.3. Comprobación de idempotencia

Ejecuta el playbook por segunda vez para verificar que no se realizan cambios innecesarios en el sistema objetivo:

```bash
ansible-playbook site.yml
```

En una ejecución idempotente, el `RECAP` final debería mostrar `changed=0`:

```text
PLAY RECAP *********************************************************************
192.168.11.156 : ok=21  changed=0  unreachable=0  failed=0  skipped=0  rescued=0  ignored=0
```

## FASE 4: Verificación manual de los servicios

Una vez finalizado el despliegue, verifica el funcionamiento de los servicios desde un navegador o desde un cliente de red utilizando la dirección `192.168.11.156`.

| Servicio | Método de verificación |
|---|---|
| FTP | Conéctate mediante un cliente FTP a `192.168.11.156`. |
| Samba | Accede al recurso compartido utilizando `\\192.168.11.156\compartida`. |
| Apache/LAMP | Abre `http://192.168.11.156` en un navegador. |
| phpMyAdmin | Abre `http://192.168.11.156/phpmyadmin`. |
| SSH | Ejecuta `ssh client@192.168.11.156`. |

## Solución rápida de problemas

### No se puede establecer la conexión SSH

Comprueba que:

- La dirección IP del cliente es correcta.
- El servicio SSH está activo en el cliente.
- La clave pública se copió al usuario `client`.
- El usuario `client` tiene permisos sobre su directorio `.ssh`.
- No existe un bloqueo de firewall entre el servidor y el cliente.

### Ansible solicita una contraseña de sudo

Verifica que el archivo `/etc/sudoers.d/client` contiene la regla `NOPASSWD` y que tiene permisos `0440`.

### Ansible no puede descifrar `vault.yml`

Comprueba que:

- El archivo `.vault_pass existe en la raíz del proyecto.
- `vault_password_file = .vault_pass` está definido en `ansible.cfg`.
- El archivo `.vault_pass` contiene la contraseña correcta.
- El archivo `.vault_pass` tiene permisos restringidos.

### El playbook informa de cambios en cada ejecución

Revisa las tareas del playbook para asegurarte de que son idempotentes. Evita comandos que siempre devuelvan un estado de cambio y utiliza módulos Ansible específicos siempre que sea posible.
