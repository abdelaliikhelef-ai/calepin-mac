# Calepin — téléchargement pour Mac

Calepin est une application Mac de chiffrage et de planning de chantier pour architectes d'intérieur : devis, planning (Gantt), calendrier et export PDF/Excel.

## Télécharger

👉 **[Page de téléchargement de la dernière version](../../releases/latest)**

Choisissez le fichier qui correspond à votre Mac ( › À propos de ce Mac, ligne « Puce » ou « Processeur ») :

| Votre Mac | Fichier |
| --- | --- |
| Puce **Apple M1, M2, M3, M4…** | `Calepin-…-AppleSilicon.dmg` |
| Processeur **Intel** | `Calepin-…-Intel.dmg` |

macOS 13 (Ventura) ou plus récent.

## Installer

### Le plus simple : une commande (aucun avertissement de macOS)

Ouvrez l'app **Terminal** (dans Applications › Utilitaires), collez cette ligne puis appuyez sur Entrée :

```bash
curl -fsSL https://raw.githubusercontent.com/abdelaliikhelef-ai/calepin-mac/main/install-mac.sh | bash
```

Elle télécharge la bonne version pour votre Mac, l'installe dans Applications et l'ouvre.

### Ou avec le fichier .dmg

1. Ouvrez le fichier `.dmg` téléchargé.
2. Glissez l'icône **Calepin** sur le dossier **Applications**.
3. Ouvrez Calepin depuis le dossier Applications.

### Au premier lancement : « Calepin ne peut pas être ouvert »

L'application n'est pas encore signée par Apple, donc macOS la bloque la première fois. C'est normal, et ça ne se fait qu'une fois :

1. Cliquez sur **OK** (ou **Terminé**) dans le message d'alerte.
2. Ouvrez **Réglages Système › Confidentialité et sécurité**.
3. Descendez jusqu'au message sur Calepin et cliquez sur **Ouvrir quand même**.
4. Confirmez (avec votre mot de passe ou Touch ID si on vous le demande).

Calepin s'ouvre ensuite normalement, sans avertissement.

## Mettre à jour

Depuis la version 0.1.8, Calepin se met à jour tout seul : **Calepin › Rechercher les mises à jour…**, puis **Installer et redémarrer**. Il vérifie aussi au lancement (une fois par jour) et affiche un petit bandeau quand une nouvelle version est prête. Vos chantiers (fichiers `.calepin`) et vos réglages sont conservés.

> Vous avez la version 0.1.7 ? Installez une fois la dernière version ci-dessus : les suivantes arriveront dans l'app.
