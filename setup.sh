#!/usr/bin/env bash
set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================="
echo "     BOOTSTRAP Y OPTIMIZADOR ASO 2026     "
echo "=========================================="
echo "1) Servidor (server)"
echo "2) Cliente (client)"
read -p "Selecciona el rol de esta VM [1 o 2]: " OPCION

case $OPCION in
  1)
    echo ""
    echo "[+] Configurando rol: SERVIDOR"
    
    # 1. Instalar dependencias necesarias
    echo "[+] Instalando Ansible y herramientas base..."
    sudo zypper ref
    sudo zypper install -y ansible python3 curl tar

    # 1b. Instalar la coleccion community.postgresql (requerida por el rol postgresql)
    echo "[+] Instalando coleccion Ansible community.postgresql..."
    ansible-galaxy collection install community.postgresql

    # 2. Respetar la ruta ~/ASO mediante enlace simbólico
    if [ "$REPO_DIR" != "$HOME/ASO" ] && [ ! -e "$HOME/ASO" ]; then
      ln -s "$REPO_DIR" "$HOME/ASO"
      echo "[+] Enlace simbólico creado: $HOME/ASO -> $REPO_DIR"
    fi

    # 3. Descargar e instalar Mitogen dentro del repositorio
    MITOGEN_DIR="$HOME/ASO/ansible/plugins"
    if [ ! -d "$MITOGEN_DIR/mitogen-0.3.54" ]; then
      echo "[+] Descargando Mitogen para acelerar ejecución..."
      mkdir -p "$MITOGEN_DIR"
      curl -sL https://github.com/mitogen-hq/mitogen/archive/refs/tags/v0.3.54.tar.gz | tar -xz -C "$MITOGEN_DIR"
      echo "[+] Mitogen instalado en $MITOGEN_DIR/mitogen-0.3.54"
    else
      echo "[+] Mitogen ya se encuentra instalado. Saltando descarga..."
    fi

    # 4. Asegurar que ansible.cfg tenga activado Mitogen y pipelining
    ANSIBLE_CFG="$HOME/ASO/ansible/ansible.cfg"
    if [ -f "$ANSIBLE_CFG" ]; then
      if ! grep -q "mitogen_linear" "$ANSIBLE_CFG"; then
        echo "[+] Inyectando configuración de Mitogen en ansible.cfg..."
        sed -i '/^\[defaults\]/a strategy_plugins = ./plugins/mitogen-0.3.54/ansible_mitogen/plugins/strategy\nstrategy = mitogen_linear' "$ANSIBLE_CFG"
      fi
    fi

    # 5. Ignorar plugins descargados y contraseña de vault en Git
    GITIGNORE="$HOME/ASO/.gitignore"
    touch "$GITIGNORE"
    grep -qxF "ansible/plugins/" "$GITIGNORE" || echo "ansible/plugins/" >> "$GITIGNORE"
    grep -qxF "ansible/.vault_pass" "$GITIGNORE" || echo "ansible/.vault_pass" >> "$GITIGNORE"

    echo ""
    echo "=========================================="
    echo " ¡SERVIDOR LISTO CON MITOGEN Y RUTA ~/ASO!"
    echo "=========================================="
    ;;

  2)
    echo ""
    echo "[+] Configurando rol: CLIENTE"

    # 1. Asegurar SSH activo
    sudo systemctl enable --now sshd

    # 2. Detener y enmascarar PackageKit para evitar bloqueos de Zypper
    echo "[+] Bloqueando PackageKit para evitar fallos de Zypper..."
    sudo systemctl stop packagekit 2>/dev/null || true
    sudo systemctl mask packagekit 2>/dev/null || true

    # 3. Verificar permisos sudo sin contraseña
    if sudo -n true 2>/dev/null; then
      echo "[+] Permisos sudo sin contraseña: OK"
    else
      echo "[!] ADVERTENCIA: sudo sigue pidiendo contraseña. Revisa /etc/sudoers.d/client"
    fi

    echo ""
    echo "=========================================="
    echo " ¡CLIENTE VERIFICADO Y LISTO PARA ANSIBLE!"
    echo "=========================================="
    ;;

  *)
    echo "[!] Opción no válida. Ejecuta nuevamente y elige 1 o 2."
    exit 1
    ;;
esac