Role Name
=========

Role para el despliegue y configuración de PostgreSQL en openSUSE.

Requirements
------------

- Colección `community.postgresql` instalada.
- Acceso con privilegios sudo en el host destino.
- Firewalld habilitado si se desea abrir el puerto 5432.

Role Variables
--------------

Las siguientes variables se deben definir (ejemplo en `group_vars/all/`):

- `pg_user`: Usuario de aplicación para PostgreSQL (por defecto: appuser)
- `pg_database`: Base de datos a crear (por defecto: appdb)
- `pg_subnet`: Subred permitida para conexiones SSL remotas (ej. 192.168.11.0/24)
- `vault_pg_password`: Contraseña del usuario de aplicación (desde vault)
- `vault_pg_root_password`: Contraseña del usuario postgres (desde vault)

Dependencies
------------

Ninguna.

Example Playbook
----------------

```yaml
- hosts: clientes
  roles:
    - postgresql
```

License
-------

BSD

Author Information
------------------

ASO - Práctica 3
