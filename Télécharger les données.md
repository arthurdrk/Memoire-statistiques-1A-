# Comment Récupérer les Données

Ce guide fournit les étapes pour accéder et transformer le jeu de données de l'**European Social Survey (ESS)** utilisé dans ce projet de sociologie. Suivez les instructions ci-dessous pour obtenir les données au format **.csv** et, si nécessaire, les convertir en **SAS**.

## Étape 1 : Télécharger les Données ESS au Format .csv

1. Accédez à la [page des données de l'European Social Survey](https://www.europeansocialsurvey.org/data/).
2. Dans la section **"Données"**, trouvez l'enquête pour l'année **2012 (ESS Round 6)**.
3. Allez dans la section **"Fichiers de Données"** et sélectionnez le fichier intitulé **"ESS6-integrated-Data file, edition 2.5"**.
4. Cliquez sur **"Se connecter pour télécharger les données"**.
5. Connectez-vous avec un compte **Google** ou une autre option pour accéder aux fichiers.
6. Sélectionnez le fichier au format **.csv** parmi les options de téléchargement disponibles (**sav, dta, csv**).

## Étape 2 : Convertir les Données en Format SAS

```sas
proc import datafile = 'YOUR_PATH/ESS6e02_5.csv'
    out = work.ess
    dbms = CSV replace;
    guessingrows=max;
run;
```
