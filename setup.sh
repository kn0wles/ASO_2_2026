---

### Bloque 3: Script de Verificación e Instalación (`setup.sh`)

Crea el archivo `setup.sh` en la raíz de tu repositorio con este código:

```bash
#!/usr/bin/env bash

set -e

echo "=========================================="
echo "    INSTALADOR Y VERIFICADOR ASO 2026    "
echo "=========================================="
echo ""
echo "Selecciona el rol de esta máquina:"
echo "1) Servidor (server)"
echo "2) Cliente (client)"
read -p "Opción [1 o 2]: " OPCION

case $OPCION in
  1)
    echo ""
    echo "[+] Configurando rol: SERVIDOR"
    echo "[+] Actualizando repositorios e instalando Ansible..."
    sudo zypper ref
    sudo zypper install -y ansible python3

    echo ""
    echo "[+] Verificando instalación de Ansible..."
    ansible --version
    
    echo ""
    echo "=========================================="
    echo " ¡Servidor preparado con éxito para Ansible!"
    echo "=========================================="
    ;;

  2)
    echo ""
    echo "[+] Configurando rol: CLIENTE"
    echo "[+] Verificando estado del servicio SSH..."
    
    if systemctl is-active --quiet sshd; then
      echo "    -> Servicio SSH: ACTIVO [OK]"
    else
      echo "    -> Servicio SSH: INACTIVO. Activando..."
      sudo systemctl enable --now sshd
    fi

    echo "[+] Verificando permisos sudo sin contraseña..."
    if sudo -n true 2>/dev/null; then
      echo "    -> Permisos sudo sin contraseña: CONFIGURADOS [OK]"
    else
      echo "    -> ADVERTENCIA: sudo requiere contraseña. Revisa /etc/sudoers"
    fi

    echo ""
    echo "=========================================="
    echo " ¡Cliente verificado y listo para recibir conexiones!"
    echo "=========================================="
    ;;

  *)
    echo "Opción no válida. Cancelando ejecución."
    exit 1
    ;;
esac