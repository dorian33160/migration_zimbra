#!/bin/bash

echo "Ce script à pour but de réaliser un backup de l'entiereté des donnéees d'un zimbra excepté les partages."
echo "voulez-vous lancer le backup ? [OUI]"
read CHOICE1

#Prérequis pour le backup
function presetup {
    if ["$EUID" -ne 0]
        then echo "Vous devez être en root pour lancer ce script"
        exit
    fi
    mkdir /migration/zmigrate
    chown zimbra.zimbra /migration/zmigrate
    su - zimbra
}

#Fonction qui permet de récupérer le ou les domaines à backup
function find_domains {
    cd /backups/zmigrate

    echo "Voulez-vous faire un backup d'un domaine en particulier ? [OUI / NON]"
    read CHOICE2

    echo "Lequel ? (Ecrivez le nom de domaine exact)"
    read domaine_choice

    if CHOICE2 -e "NON"
        then
            zmprov gad > domains.txt
            cat domains.txt
        else
            zmprov gad | grep domaine_choice > domains.txt
            cat domains.txt
    fi
}

#Fonction qui permet de récupérer les comptes admins
function find_admin_accounts {
    if CHOICE2 -e "NON"
        then
            zmprov gaaa > admins.txt
            cat admins.txt
        else
            zmprov gaaa | grep domaine_choice > admins.txt
            cat admins.txt
    fi
}

#Fonction qui permet de récupérer les comptes utilisateurs
function find_user_accounts {
    if CHOICE2 -e "NON"
        then
            zmprov -l gaa > emails.txt
            cat emails.txt
        else
            zmprov -l gaa | grep domaine_choice > emails.txt
            cat emails.txt
    fi
}

#Fonction qui permet de récupérer les listes de distribution
function distribution_list {
    if CHOICE2 -e "NON"
        then
            zmprov gadl > distributinlist.txt
            cat distributinlist.txt
        else
            zmprov gadl | grep domaine_choice > distributinlist.txt
            cat distributinlist.txt
    fi
}

#Fonction qui permet de récupérer les membres des listes de distribution
function distribution_list_members {
    mkdir /migration/zmigrate/distributinlist_members
    for i in `cat /migration/zmigrate/distributinlist.txt`
        do
            zmprov gdlm $i > /migration/zmigrate/distributinlist_members/$i.txt
        done
}

#Fonction qui permet de récupérer les mots de passe des utilisateurs
function users_password {
    mkdir userpass
    for i in `cat emails.txt`
        do
            zmprov -l ga $i userPassword | grep userPassword: | awk '{ print $2}' > userpass/$i.shadow
        done
    find forwarding/ -type f -empty | xargs -n1 rm -v
}

#Fonction qui permet de récupérer les données des utilisateurs
function userdata {
    for i in `cat emails.txt`
        do
            zmprov ga $i  | grep -i Name: > userdata/$i.txt
        done
}

#Fonction qui permet de récupérer les alias des utilisateurs
function alias {
    for i in `cat emails.txt`
        do
            zmprov ga  $i | grep zimbraMailAlias |awk '{print $2}' > alias/$i.txt
            echo $i
        done
    find alias/ -type f -empty | xargs -n1 rm -v 
}

#Fonction qui permet de récupérer les signatures des utilisateurs
function emails_signature {
    mkdir signatures
    for i in `cat emails.txt`
        do
            zmprov ga $i zimbraPrefMailSignatureHTML > /tmp/signature
            sed -i -e "1d" /tmp/signature
            sed 's/zimbraPrefMailSignatureHTML: //g' /tmp/signature > signatures/$i.signature
            rm -rf /tmp/signature
            zmprov ga $i zimbraSignatureName > /tmp/name
            sed -i -e "1d" /tmp/name
            sed 's/zimbraSignatureName: //g' /tmp/name > signatures/$i.name
            rm -rf /tmp/name
        done
}

#Fonction qui permet de récupérer les partages des utilisateurs
function user_filters {
    mkdir filter/
        for i in `cat emails.txt`
            do
                zmprov ga $i zimbraMailSieveScript > /tmp/filter
                sed -i -e "1d" /tmp/filter
                sed 's/zimbraMailSieveScript: //g' /tmp/filter  > filter/$i.filter
                rm -f /tmp/filter
                echo "Filter  downloaded for .... $i"
            done
}

#Fonction qui permet de récupérer les mails des utilisateurs
function mail_backup {
    for email in `cat /backups/zmigrate/emails.txt`
        do
            echo "Backuping $email"
            zmmailbox -z -m $email getRestURL '/?fmt=tgz' > $email.tgz
            echo $email
        done
}

function main {
    if CHOICE1 -e "OUI"
        then
            presetup
            find_domains
            find_admin_accounts
            find_user_accounts
            distribution_list
            distribution_list_members
            users_password
            userdata
            alias
            emails_signature
            user_filters
            mail_backup
        else
            exit
    fi
    
}

main