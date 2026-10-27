# Guía paso a paso: preparación, configuración y despliegue

Esta guía describe la preparación del servidor y del cliente, la configuración del proyecto Ansible y la verificación del despliegue de los servicios.

## FASE 1: Pasos previos en el servidor y el cliente

Antes de ejecutar Ansible, es necesario preparar la conectividad y la infraestructura básica entre el servidor y el cliente.

### 1.1. Configuración de Hostnames

1. **Establecer los nombres de host:**
   - **En VM Server:** `sudo hostnamectl set-hostname server`
   - **En VM Client:** `sudo hostnamectl set-hostname client`

2. **Verificar o crear los usuarios (`server` y `client`):**
   - **En VM Server** (crea el usuario `server` solo si no existe):

    ```bash
    id -u server &>/dev/null || (sudo useradd -m server && echo "Usuario server creado. Asigna una contraseña:" && sudo passwd server)
    ```

   - **En VM Client** (crea el usuario `client` solo si no existe):

    ```bash
    id -u client &>/dev/null || (sudo useradd -m client && echo "Usuario client creado. Asigna una contraseña:" && sudo passwd client)
    ```

3. **Verificar conectividad e IPs** en ambas máquinas con `ip a`.

### 1.2. Instalacion de Servcicios

- Instalar servicios en ambas VMs:

```bash
sudo zypper install -y openssh git
sudo systemctl enable --now sshd
sudo firewall-cmd --add-service=ssh --permanent && sudo firewall-cmd --reload
```

### 1.3. Configuración de acceso SSH

1. Generar par de claves en ambas VMs:

```bash
ssh-keygen -t rsa -b 4096
```

2. Intercambiar las claves públicas entre server y client:

```bash
ssh-copy-id client@<IP_CLIENT>   # Ejecutar desde server
ssh-copy-id server@<IP_SERVER>   # Ejecutar desde client
```

3. Verifica que puedes conectarte sin introducir la contraseña:

```bash
ssh client@<IP_DEL_CLIENTE> "hostname"
```

> cambiar `<IP_DEL_CLIENTE>` por la dirección IP del cliente, por ejemplo `192.168.100.63`. Si la conexión funciona correctamente, puedes realizar la configuracion similar para el servidor, si es necesario.

### 1.4. Configuración de sudo sin contraseña en el cliente

1. Crea el archivo `/etc/sudoers.d/client` con el siguiente contenido:

```bash
echo "client ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/client
```

2. A continuación, establece los permisos adecuados:

```bash
chmod 0440 /etc/sudoers.d/client
```

> **Importante:** Comprueba la sintaxis del archivo sudoers antes de cerrar la sesión de `root`:
>
> ```bash
> visudo -c -f /etc/sudoers.d/client
> ```

### 1.5. Clonación del Repositorio y Bootstrap (Ruta ~/ASO)

1. Clonar el repositorio e ingresar a la carpeta:

  ```bash
  git clone https://github.com/kn0wles/ASO_2_2026.git
  cd ASO_2_2026
  ```

2. Ejecutar el script de inicialización (instala Ansible, descarga Mitogen dentro del proyecto, bloquea PackageKit en cliente y crea el enlace simbólico ~/ASO):

  ```bash
  chmod +x setup.sh
  ./setup.sh
  ```

### 1.6. Configuración de Ansible Vault y Despliegue

1. Ingresar al directorio de Ansible respetando la ruta estándar:

```bash
cd ~/ASO/ansible
```

2. Crear o configurar el archivo de credenciales cifradas (vault.yml):

```bash
ansible-vault edit group_vars/all/vault.yml
```

3.  Crear el archivo de contraseña automática para Vault (reemplaza TU_CONTRASEÑA por la clave utilizada en el paso anterior):

```bash
echo "TU_CONTRASEÑA" > .vault_pass
chmod 600 .vault_pass
```

> **Importante:** No subas .vault_pass al repositorio. Asegúrate de que esté incluido en tu archivo .gitignore.

---

## FASE 2: Configuración de los archivos del proyecto

### 2.1. Configuración de `ansible.cfg`

Verifica o edita el archivo `ansible.cfg` en `~/ASO/ansible` para activar Mitogen, la contraseña de Vault y la escalada de privilegios:

```ini,TOML
[defaults]
inventory = hosts
vault_password_file = .vault_pass
interpreter_python = auto_silent
host_key_checking = False
retry_files_enabled = False
forks = 10
timeout = 30

# Optimización de recolección de datos y Mitogen
gathering = smart
fact_caching = memory
pipelining = True
strategy_plugins = ./plugins/mitogen-0.3.54/ansible_mitogen/plugins/strategy
strategy = mitogen_linear

[mitogen]
reuse_connections = True
compress = True
connection_pool_size = 20

[privilege_escalation]
become = True
become_method = sudo
become_user = root
become_ask_pass = False

[ssh_connection]
pipelining = True
scp_if_ssh = smart
ssh_args = -o ControlMaster=auto -o ControlPersist=60s -o ControlPath=/tmp/ansible-ssh-%%h-%%p-%%r
```

### 2.2. Configuración del inventario `hosts`

Edita el archivo `hosts` para definir el grupo de clientes y el usuario SSH de conexión.


```ini
[clientes]
192.168.100.63 ansible_user=client
```

### 2.3. Estructura de variables

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
192.168.100.63 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

### 3.2. Ejecución del despliegue principal

Para instalar y configurar todos los servicios —FTP, Samba, LAMP y phpMyAdmin— ejecuta:

```bash
ansible-playbook site.yml
```

> si quieres medir tiempo que tarda el comando es `time ansible-playbook site.yml`

### 3.3. Comprobación de idempotencia

Ejecuta el playbook por segunda vez para verificar que no se realizan cambios innecesarios en el sistema objetivo:

```bash
ansible-playbook site.yml
```

En una ejecución idempotente, el `RECAP` final debería mostrar `changed=0`:

```text
PLAY RECAP *********************************************************************
192.168.100.63 : ok=21  changed=0  unreachable=0  failed=0  skipped=0  rescued=0  ignored=0
```

## FASE 4: Verificación manual de los servicios

Una vez finalizado el despliegue, verifica el funcionamiento de los servicios desde un navegador o desde un cliente de red utilizando la dirección `192.168.100.63`.

| Servicio | Método de verificación |
|---|---|
| FTP | Conéctate mediante un cliente FTP a `192.168.100.63`. |
| Samba | Accede al recurso compartido utilizando `\\192.168.100.63\compartida`. |
| Apache/LAMP | Abre `http://192.168.100.63` en un navegador. |
| phpMyAdmin | Abre `http://192.168.100.63/phpmyadmin`. |
| SSH | Ejecuta `ssh client@192.168.100.63`. |

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
