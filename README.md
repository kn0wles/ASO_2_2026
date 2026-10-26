# Despliegue Automatizado LAMP, Samba y FTP con Ansible

Este repositorio contiene la arquitectura de automatización con **Ansible** desarrollada para el despliegue idempotente y orquestado de un stack **LAMP (Apache, MariaDB, phpMyAdmin)** junto con servicios de red **Samba** y **FTP (vsftpd)** sobre nodos clientes **openSUSE Leap 16.0**.

---

## 📋 Requisitos del Proyecto (Task 3)

- **Despliegue Remoto:** Instalación y configuración de Apache, PHP y phpMyAdmin.
- **Base de Datos:** Configuración segura de MariaDB y creación de usuarios con privilegios.
- **Recursos Compartidos (Samba):** 
  - Creación de usuario del sistema y usuario Samba (`knowles`).
  - Creación de directorios dedicados con permisos adecuados.
  - Definición explícita de `create mask` y `directory mask` (`0775`).
- **Mejoras de Rendimiento y Seguridad:**
  - Inventario limpio (sin usuarios ni contraseñas visibles).
  - Uso de **Ansible Vault** para credenciales sensibles.
  - Optimización del tiempo de respuesta mediante *SSH Pipelining*.
  - Organización modular basada en **Roles**.

---

## 🏗️ Estructura del Repositorio

```text
.
├── ansible.cfg            # Configuración global de Ansible y SSH Pipelining
├── hosts                  # Inventario de hosts (sin datos sensibles)
├── site.yml               # Playbook orquestador principal
├── group_vars/
│   └── all/
│       ├── vars.yml       # Variables públicas (rutas, paquetes, permisos)
│       └── vault.yml      # Variables cifradas con Ansible Vault (contraseñas)
└── roles/
    ├── apache/            # Instalación de Apache2, PHP8 y módulos
    ├── mariadb/           # Configuración de MariaDB y credenciales de BD
    ├── phpmyadmin/        # Despliegue del gestor web y Handlers
    ├── samba/             # Gestión de usuarios, directorios y recursos smb
    └── ftp/               # Servidor VSFTPD y reglas de firewall
