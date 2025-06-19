#!/bin/bash

# Script d'automatisation pour la recréation périodique
# d'un TemplateVM et d'un AppVM FortiClient dans Qubes OS.
# À EXÉCUTER DANS DOM0 AVEC SUDO

# --- Vérification initiale des arguments ---
if [ -z "$1" ]; then
  echo "Erreur: Version de FortiClient non spécifiée."
  echo "Usage: sudo $0 <version>"
  echo "Exemples:"
  echo "  sudo $0 7.0"
  echo "  sudo $0 7.4"
  exit 1
fi

FORTICLIENT_VERSION_ARG=$1

# --- Configuration ---
# TemplateVM de base à partir duquel cloner
BASE_TEMPLATE_NAME="fedora-41-xfce" # Vérifiez et ajustez le nom exact de votre template Fedora 41 XFCE
# Étiquette de couleur pour la nouvelle AppVM (ex: red, orange, green, blue, black, gray)


# Variables qui seront définies en fonction de la version
FORTI_TEMPLATE_NAME=""
FORTI_APPVM_NAME=""
FORTINET_REPO_URL=""
APPVM_LABEL=""

# --- Configuration spécifique à la version ---
case "$FORTICLIENT_VERSION_ARG" in
  "7.0")
    FORTI_TEMPLATE_NAME="fedora-41-forti70"
    FORTI_APPVM_NAME="vpn-t0" # Corrigé
    # IMPORTANT: Vérifiez et ajustez cette URL pour FortiClient 7.0 si elle est différente
    FORTINET_REPO_URL="https://repo.fortinet.com/repo/7.0/centos/8/os/x86_64/fortinet.repo"
    APPVM_LABEL="red"
    echo "Configuration pour FortiClient version 7.0 sélectionnée."
    ;;
  "7.4")
    FORTI_TEMPLATE_NAME="fedora-41-forti74"
    FORTI_APPVM_NAME="vpn-t2" # Corrigé
    FORTINET_REPO_URL="https://repo.fortinet.com/repo/forticlient/7.4/centos/8/os/x86_64/fortinet.repo"
    APPVM_LABEL="blue"
    echo "Configuration pour FortiClient version 7.4 sélectionnée."
    ;;
  *)
    echo "Erreur: Version de FortiClient non supportée: '$FORTICLIENT_VERSION_ARG'."
    echo "Versions supportées: 7.0, 7.4"
    exit 1
    ;;
esac

# --- Vérification des privilèges ---
if [ "$EUID" -ne 0 ]; then
  echo "Ce script doit être exécuté avec sudo (ou en tant que root) dans dom0."
  exit 1
fi

echo "--- DÉBUT DE L'AUTOMATISATION DE LA CONFIGURATION FORTICLIENT VERSION $FORTICLIENT_VERSION_ARG ---"
echo "TemplateVM de base: $BASE_TEMPLATE_NAME"
echo "Nouveau TemplateVM: $FORTI_TEMPLATE_NAME"
echo "Nouvelle AppVM: $FORTI_APPVM_NAME"
echo "URL du dépôt: $FORTINET_REPO_URL"

# --- Fonction utilitaire pour afficher les erreurs et quitter ---
handle_error() {
    echo "ERREUR: $1"
    echo "Abandon du script."
    exit 1
}

# --- Étape 1: Supprimer l'AppVM existante (si elle existe) ---
if qvm-check "$FORTI_APPVM_NAME" &>/dev/null; then
    echo "L'AppVM '$FORTI_APPVM_NAME' existe."
    echo "Tentative d'arrêt de '$FORTI_APPVM_NAME'..."
    qvm-shutdown --wait "$FORTI_APPVM_NAME" || echo "L'AppVM '$FORTI_APPVM_NAME' n'était pas en cours d'exécution ou n'a pas pu être arrêtée proprement."
    
    echo "Suppression de l'AppVM '$FORTI_APPVM_NAME'..."
    qvm-remove "$FORTI_APPVM_NAME"
    if [ $? -ne 0 ]; then
        handle_error "Échec de la suppression de l'AppVM '$FORTI_APPVM_NAME'. Veuillez vérifier manuellement."
    fi
    echo "AppVM '$FORTI_APPVM_NAME' supprimée avec succès."
else
    echo "L'AppVM '$FORTI_APPVM_NAME' n'existe pas. Suppression ignorée."
fi

# --- Étape 2: Supprimer le TemplateVM existant (s'il existe) ---
if qvm-check "$FORTI_TEMPLATE_NAME" &>/dev/null; then
    echo "Le TemplateVM '$FORTI_TEMPLATE_NAME' existe."
    echo "Tentative d'arrêt de '$FORTI_TEMPLATE_NAME'..."
    qvm-shutdown --wait "$FORTI_TEMPLATE_NAME" || echo "Le TemplateVM '$FORTI_TEMPLATE_NAME' n'était pas en cours d'exécution ou n'a pas pu être arrêté proprement."

    echo "Suppression du TemplateVM '$FORTI_TEMPLATE_NAME'..."
    qvm-remove "$FORTI_TEMPLATE_NAME"
    if [ $? -ne 0 ]; then
        handle_error "Échec de la suppression du TemplateVM '$FORTI_TEMPLATE_NAME'. Assurez-vous qu aucune AppVM (autre que '$FORTI_APPVM_NAME') n'en dépend et réessayez."
    fi
    echo "TemplateVM '$FORTI_TEMPLATE_NAME' supprimé avec succès."
else
    echo "Le TemplateVM '$FORTI_TEMPLATE_NAME' n'existe pas. Suppression ignorée."
fi

# --- Étape 3: Créer un nouveau TemplateVM en clonant le template de base ---
echo "Clonage de '$BASE_TEMPLATE_NAME' vers '$FORTI_TEMPLATE_NAME'..."
qvm-clone "$BASE_TEMPLATE_NAME" "$FORTI_TEMPLATE_NAME"
if [ $? -ne 0 ]; then
    handle_error "Échec du clonage de '$BASE_TEMPLATE_NAME' vers '$FORTI_TEMPLATE_NAME'."
fi
echo "TemplateVM '$FORTI_TEMPLATE_NAME' créé avec succès."

# --- Étape 4: Installation de FortiClient dans le nouveau TemplateVM ---
echo "Installation de FortiClient (version $FORTICLIENT_VERSION_ARG) dans '$FORTI_TEMPLATE_NAME'..."
# Script d'installation à exécuter dans le TemplateVM
FORTICLIENT_INSTALL_SCRIPT=$(cat <<EOF
echo "--- Début de l'installation de FortiClient dans le TemplateVM ---"
echo "Ajout du dépôt Fortinet: ${FORTINET_REPO_URL}"
dnf config-manager addrepo --from-repofile=${FORTINET_REPO_URL}
if [ \$? -ne 0 ]; then
  echo "Erreur lors de l'ajout du dépôt Fortinet. Abandon."
  exit 1
fi
echo "Installation de FortiClient (cela peut prendre quelques minutes)..."
# Le nom du paquet est généralement 'forticlient', même si la version du dépôt change.
# Si le nom du paquet changeait avec la version (ex: forticlient70), il faudrait l'adapter ici.
yum install -y forticlient
if [ \$? -ne 0 ]; then
  echo "Erreur lors de l'installation de FortiClient. Abandon."
  exit 1
fi
echo "Nettoyage des métadonnées DNF..."
dnf clean all
echo "--- Installation de FortiClient terminée avec succès dans le TemplateVM ---"
EOF
)

qvm-run -u root "$FORTI_TEMPLATE_NAME" "$FORTICLIENT_INSTALL_SCRIPT"
if [ $? -ne 0 ]; then
    echo "Une erreur s'est produite pendant l'installation de FortiClient dans '$FORTI_TEMPLATE_NAME'."
    echo "Tentative de nettoyage: suppression de '$FORTI_TEMPLATE_NAME'..."
    qvm-shutdown --wait "$FORTI_TEMPLATE_NAME" || true
    qvm-remove "$FORTI_TEMPLATE_NAME"
    handle_error "Échec de l'installation de FortiClient."
fi
echo "FortiClient installé avec succès dans '$FORTI_TEMPLATE_NAME'."

# --- Étape 5: Configuration du transfert IP (ip_forwarding) de manière persistante dans le TemplateVM ---
echo "Configuration du transfert IP (net.ipv4.ip_forward=1) dans '$FORTI_TEMPLATE_NAME'..."
IP_FORWARD_CONFIG_SCRIPT=$(cat <<EOF
echo "--- Configuration de net.ipv4.ip_forward ---"
echo "net.ipv4.ip_forward = 1" > /etc/sysctl.d/99-ip_forward.conf
sysctl -p /etc/sysctl.d/99-ip_forward.conf
echo "--- Transfert IP configuré dans le TemplateVM ---"
EOF
)

qvm-run -u root "$FORTI_TEMPLATE_NAME" "$IP_FORWARD_CONFIG_SCRIPT"
if [ $? -ne 0 ]; then
    echo "Une erreur s'est produite pendant la configuration du transfert IP dans '$FORTI_TEMPLATE_NAME'."
    echo "Tentative de nettoyage: suppression de '$FORTI_TEMPLATE_NAME'..."
    qvm-shutdown --wait "$FORTI_TEMPLATE_NAME" || true
    qvm-remove "$FORTI_TEMPLATE_NAME"
    handle_error "Échec de la configuration du transfert IP."
fi
echo "Transfert IP configuré avec succès dans '$FORTI_TEMPLATE_NAME'."

# --- Étape 6: Arrêter le TemplateVM pour sauvegarder les modifications ---
echo "Arrêt de '$FORTI_TEMPLATE_NAME' pour sauvegarder les modifications..."
qvm-shutdown --wait "$FORTI_TEMPLATE_NAME"
if [ $? -ne 0 ]; then
    echo "AVERTISSEMENT: '$FORTI_TEMPLATE_NAME' ne s'est peut-être pas arrêté proprement."
fi
echo "TemplateVM '$FORTI_TEMPLATE_NAME' arrêté."

# --- Étape 7: Créer la nouvelle AppVM ---
echo "Création de l'AppVM '$FORTI_APPVM_NAME' basée sur '$FORTI_TEMPLATE_NAME' avec l'étiquette '$APPVM_LABEL'..."
qvm-create --template "$FORTI_TEMPLATE_NAME" --label "$APPVM_LABEL" "$FORTI_APPVM_NAME"
if [ $? -ne 0 ]; then
    handle_error "Échec de la création de l'AppVM '$FORTI_APPVM_NAME'."
fi
echo "AppVM '$FORTI_APPVM_NAME' créée avec succès."

# --- Étape 8: Activer "Provides network" pour l'AppVM ---
echo "Activation de 'Provides network' pour '$FORTI_APPVM_NAME'..."
qvm-prefs "$FORTI_APPVM_NAME" provides_network true
if [ $? -ne 0 ]; then
    handle_error "Échec de l'activation de 'Provides network' pour '$FORTI_APPVM_NAME'."
fi
echo "'Provides network' activé pour '$FORTI_APPVM_NAME'."

echo "--- AUTOMATISATION TERMINÉE AVEC SUCCÈS POUR LA VERSION $FORTICLIENT_VERSION_ARG ---"
echo "Le TemplateVM '$FORTI_TEMPLATE_NAME' a été créé et configuré."
echo "L'AppVM '$FORTI_APPVM_NAME' a été créée, basée sur '$FORTI_TEMPLATE_NAME', et configurée pour fournir un réseau."
echo ""
echo "PROCHAINES ÉTAPES MANUELLES:"
echo "1. Démarrez l'AppVM '$FORTI_APPVM_NAME'."
echo "2. Lancez FortiClient graphiquement pour la configuration initiale et l'activation de la licence d'évaluation."
echo "3. Configurez les autres Qubes pour utiliser '$FORTI_APPVM_NAME' comme leur NetVM."

exit 0
