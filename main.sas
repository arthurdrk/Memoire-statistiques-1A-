FILENAME REFFILE '/home/u64091512/data/ESS6e02_6.csv';
ODS LISTING GPATH='/home/u64091512/graph/';
ODS GRAPHICS / RESET=all OUTPUTFMT=png IMAGENAME="fig" NOBORDER NOIMAGEMAP;
ODS LATEX FILE="~/tex/tables.tex";
ODS NOPROCTITLE;
/* couleurs utilisées pour les graphiques*/
%let couleur1 = CXAC012A;
%let couleur2 = CXF7E6EA;
PROC IMPORT DATAFILE=REFFILE
    DBMS=CSV
    OUT=WORK.ESS06;
    GETNAMES=YES;
RUN;

DATA donnees_ess;
    SET ESS06;
    WHERE cntry = 'FR'; /* Filtrage pour n'avoir que les données françaises */
RUN;

PROC FORMAT; /* Format pour la variable happy*/
    VALUE happy_fmt
        0 = '00 très malheureux'
        1 = '01'
        2 = '02'
        3 = '03'
        4 = '04'
        5 = '05'
        6 = '06'
        7 = '07'
        8 = '08'
        9 = '09'
        10 = '10 très heureux';
RUN;

 /* Format pour la variable hinctnta */
PROC FORMAT;
        VALUE deciles_fmt
        1 = "premier décile"
        10 = "dixième décile";
RUN;

/* Boîtes de Tukey pour hinctnta de bonheur en fonction du revenu net */
PROC SGPLOT DATA = donnees_ess;
	TITLE " Boîtes de TUKEY du sentiment de bonheur en fonction du revenu net";
	WHERE hinctnta<11;
	VBOX happy / CATEGORY = hinctnta CONNECT = MEAN WEIGHT = anweight
	FILLATTRS = (color = &couleur2)
	CONNECTATTRS = (color = &couleur1)
	LINEATTRS = (color = &couleur1)
	MEANATTRS = (color = &couleur1)
	MEDIANATTRS = (color = &couleur1)
	WHISKERATTRS = (color = &couleur1 PATTERN = MediumDash)
	OUTLIERATTRS = (color = &couleur1);
	YAXIS /* titre des ordonnées */
	LABEL = "Niveau de bonheur (happy).";
	XAXIS /* titre des abscises */
	LABEL = "Revenu net total du ménage (hinctnta)." ;
	FORMAT  hinctnta deciles_fmt.;
	FORMAT happy happy_fmt.;
	
DATA donnees_ess;
    SET donnees_ess;
    WHERE wkhtot < 160; /* Filtrage des valeurs manquantes et aberrantes pour wkhtot */
RUN;

/*Distrinution du temps de travail*/
PROC UNIVARIATE DATA=donnees_ess;
	VAR wkhtot;
RUN;
PROC MEANS DATA=donnees_ess Q1 MEDIAN Q3 NOPRINT;
    VAR wkhtot;
    OUTPUT OUT=quartiles Q1=Q1 MEDIAN=Median Q3=Q3;
RUN;

PROC PRINT DATA=quartiles;
RUN;

/* Tracé de l'histogramme de wkhtot */
PROC SGPLOT DATA=WORK.donnees_ess;
    HISTOGRAM wkhtot / WEIGHT = anweight /* pondération */
        FILLATTRS = (color = &couleur2); 
    DENSITY wkhtot / WEIGHT = anweight TYPE=KERNEL /* pondération */
        LINEATTRS = (color = &couleur1); 
    REFLINE 40 / AXIS=X LINEATTRS=(COLOR=&couleur1 PATTERN=ShortDash) 
        LABEL="Médiane : 40 heures" LABELPOS=MAX; 
    KEYLEGEND / LOCATION=INSIDE POSITION=TOPRIGHT; /* légende */
    XAXIS 
        LABEL = "Nombre total d'heures de travail par semaine (wkhtot).";
RUN;

/* Catégorisation des heures de travail */
DATA donnees_ess;
    SET donnees_ess;
    IF wkhtot<=35 THEN categorie_heures = 1;
    ELSE IF wkhtot > 35 AND wkhtot <= 40 THEN categorie_heures = 2;
    ELSE IF wkhtot > 40 AND wkhtot <= 45 THEN categorie_heures = 3;
    ELSE categorie_heures = 4;
RUN;

/* Création d'un format pour categorie_heures */
PROC FORMAT;
    VALUE categorie_fmt
         1 = 'moins de 35 heures'
         2 = 'entre 35 et 40 heures'
         3 = 'entre 40 et 45 heures'
         4 = 'plus de 45 heures';
RUN;

/* Le format précédent ne fonctionne pas bien avec les HEATMAP */
PROC FORMAT;
    VALUE categorie_fmt_heatmap
         1 = '0. moins de 35 heures'
         2 = '1. entre 35 et 40 heures'
         3 = '2. entre 40 et 45 heures'
         4 = '3. plus de 45 heures';
RUN;

/* Tri préalable des données */
PROC SORT DATA=donnees_ess;
    BY categorie_heures happy;
RUN;

/* Heatmap de la variable happy par rapport aux catégories de temps de travail (peu lisible) */
PROC SGPLOT DATA=donnees_ess;
    HEATMAP X=categorie_heures Y=happy / 
        FREQ=anweight  /* Poids d'analyse */
        COLORMODEL=(white &couleur1)  /* Palette de couleurs */
        DISCRETEX DISCRETEY;
        
    XAXIS 
        LABEL="Nombre total d'heures de travail par semaine."
        DISCRETEORDER=FORMATTED;  /* Catégorisation sur l'axe X */
    
    YAXIS 
        LABEL="Niveau de bonheur (happy)."
        DISCRETEORDER=FORMATTED;  /* Catégorisation sur l'axe Y */
    
    FORMAT categorie_heures categorie_fmt_heatmap.;
    FORMAT happy happy_fmt.;  /* Application des formats */
RUN;

/* Visualisation des caractéristiques de happy pour chaque catégorie */
PROC MEANS DATA=donnees_ess N MEAN STD VAR MIN MAX;
    CLASS categorie_heures;
    VAR happy;
RUN;

/*Boîtes de Tukey de happy en fonction des catégories de travail (plus lisible) */
PROC SGPLOT DATA=donnees_ess;
    VBOX happy / CATEGORY = categorie_heures CONNECT = MEAN WEIGHT = anweight /* pondération */
        FILLATTRS = (color = &couleur2)
        CONNECTATTRS = (color = &couleur1)
        LINEATTRS = (color = &couleur1)
        MEANATTRS = (color = &couleur1)
        MEDIANATTRS = (color = &couleur1)
        WHISKERATTRS = (color = &couleur1 PATTERN = MediumDash)
        OUTLIERATTRS = (color = &couleur1);
    YAXIS 
        LABEL = "Niveau de bonheur (happy).";
    XAXIS 
        LABEL = "Nombre total d'heures de travail par semaine.";
    FORMAT categorie_heures categorie_fmt.;
    FORMAT happy happy_fmt.;  /* Application des formats*/
RUN;

/* Format pour stfjbot, satisfaction vis-à-vis de l’équilibre temps de travail et temps personnel */
PROC FORMAT;
    VALUE stfjbot_fmt
        0 = '00 très insatisfait'
        1 = '01'
        2 = '02'
        3 = '03'
        4 = '04'
        5 = '05'
        6 = '06'
        7 = '07'
        8 = '08'
        9 = '09'
        10 = '10 très satisfait';
RUN;

/* Boîtes de Tukey de happy en fonction stfjbot */ 
PROC SGPLOT DATA=donnees_ess;
	WHERE stfjbot<11;
    VBOX happy / CATEGORY = stfjbot CONNECT = MEAN WEIGHT = anweight
        FILLATTRS = (color = &couleur2)
        CONNECTATTRS = (color = &couleur1)
        LINEATTRS = (color = &couleur1)
        MEANATTRS = (color = &couleur1)
        MEDIANATTRS = (color = &couleur1)
        WHISKERATTRS = (color = &couleur1 PATTERN = MediumDash)
        OUTLIERATTRS = (color = &couleur1);
    YAXIS 
        LABEL = "Niveau de bonheur (happy).";
    XAXIS 
        LABEL = "Satisfait de l'équilibre entre le temps consacré au travail et le temps dédié à d'autres aspects (stfjbot).";
    FORMAT stfjbot stfjbot_fmt.;
    FORMAT happy happy_fmt.;  /* Application des formats*/
RUN;

/* Création d’un format pour wkdcorga */
PROC FORMAT ;
    VALUE wkdcorga_fmt
        0 = '00 Aucune capacité'
        1 = '01'
        2 = '02'
        3 = '03'
        4 = '04'
        5 = '05'
        6 = '06'
        7 = '07'
        8 = '08'
        9 = '09'
        10 = '10 Totale capacité';
RUN;
/* Création d’un format pour iorgact */
PROC FORMAT ;
    VALUE iorgact_fmt
        0 = '00 Aucune capacité'
        1 = '01'
        2 = '02'
        3 = '03'
        4 = '04'
        5 = '05'
        6 = '06'
        7 = '07'
        8 = '08'
        9 = '09'
        10 = '10 Totale capacité';
RUN;

/* Tri préalable et suppression des valeurs manquantes*/
PROC SORT DATA=donnees_ess;
    WHERE wkdcorga < 11;
    BY wkdcorga;
RUN;


/* Heatmap du bonheur général (happy) par rapport à wkdcorga*/
PROC SGPLOT DATA = donnees_ess;
    HEATMAP X = wkdcorga Y = happy /
        FREQ = anweight  /* poids d'analyse, légende en % */
        /* réglages graphiques */
        COLORMODEL = (white &couleur1) DISCRETEX DISCRETEY;
    XAXIS /* titre de l'axe x */
        LABEL = "Capacité à organiser sa journée de travail (wkdcorga)."
        DISCRETEORDER = FORMATTED;
    YAXIS /* titre et ordre de l'axe y */
        LABEL = "Niveau de bonheur (happy)."
        DISCRETEORDER = FORMATTED;
    FORMAT wkdcorga wkdcorga_fmt.;
    FORMAT happy happy_fmt.; 
RUN;

/* Tri préalable et suppression des valeurs manquantes*/
PROC SORT DATA=donnees_ess;
    WHERE iorgact < 11;
    BY iorgact happy;
RUN;

/* Boîtes à moustache du bonheur général (happy) par rapport à (iorgact)*/
PROC SGPLOT DATA=donnees_ess;
    VBOX happy / CATEGORY = iorgact CONNECT = MEAN WEIGHT = anweight /* pondération */
        FILLATTRS = (color = &couleur2)
        CONNECTATTRS = (color = &couleur1)
        LINEATTRS = (color = &couleur1)
        MEANATTRS = (color = &couleur1)
        MEDIANATTRS = (color = &couleur1)
        WHISKERATTRS = (color = &couleur1 PATTERN = MediumDash)
        OUTLIERATTRS = (color = &couleur1);
    YAXIS 
        LABEL = "Niveau de bonheur (happy).";
    XAXIS 
        LABEL = "Capacité à prendre des décisions sur l'organisation de l'activité (iorgact).";
    FORMAT iorgact iorgact_fmt.;
    FORMAT happy happy_fmt.;  /* Application des formats*/
RUN;

/* 2 - Construction de l’indice synthétique de bonheur */



/* Création de la matrice des corrélations de Pearson des variables utilisées pour l’indice synthétique */

/* La variable cldgng n’est pas numérique */
DATA donnees_ess;
  SET donnees_ess;
  cldgng2 = 0;
  IF cldgng = "1" then cldgng2 = 1;
  else IF cldgng = "2" then cldgng2 = 2;
  else IF cldgng = "3" then cldgng2 = 3;
  else IF cldgng = "4" then cldgng2 = 4;
  else IF cldgng = "7" then cldgng2 = 7;
  else IF cldgng = "8" then cldgng2 = 8;
  else IF cldgng = "9" then cldgng2 = 9;
  else cldgng2 = 10;
RUN;
/* On garde uniquement les variables considérées pour construire l’indice synthétique */

DATA varbonheur;
	SET donnees_ess(keep=anweight sedirlf accdng tmendng tmimdng flrms tmdotwa fltdpr flteeff slprl enrglot cldgng2 stflIFe stfjb happy pstvms);
RUN;

%macro prepCorrData(in=, out=);
  /* RUN corr matrix for input data, all numeric vars */
  PROC corr data=&in. noprint
    pearson
    outp=work._tmpCorr
    vardef=df;
    weight anweight; /* Ajout de la pondération */
  RUN;
 
  /* Prepare data for heat map */
data &out.;
  keep x y r;
  SET work._tmpCorr(where=(_TYPE_="CORR"));
  array v{*} _numeric_;
  x = _NAME_;
  do i = dim(v) to 1 by -1;
    y = vname(v(i));
    r = abs(v(i)); /* Appliquer la valeur absolue au coefficient r */
    output;
  end;
RUN;
 
PROC dataSETs lib=work nolist nowarn;
  delete _tmpCorr;
quit;
%mend;

ods path work.mystore(update) sashelp.tmplmst(read);

PROC template;
  define statgraph corrHeatmap;
    dynamic _Title;
    begingraph;
      entrytitle _Title;
      
      /* Définir la palette de couleur (de blanc à rouge) */
      rangeattrmap name='map';
        range 0 -1 / rangecolormodel=(cxffffff CXAC012A); /* De blanc à rouge */
      endrangeattrmap;

      rangeattrvar var=r attrvar=r attrmap='map';

      layout overlay / 
        xaxisopts=(display=(line ticks tickvalues)) 
        yaxisopts=(display=(line ticks tickvalues));
		
        /* Graphique de la heatmap */
        heatmapparm x=x y=y colorresponse=r / /* Utiliser la valeur absolue de r */
      	xbinaxis=false ybinaxis=false
        name = "heatmap" display=all;
      continuouslegend "heatmap" / 
        orient=vertical location=outside title="Coefficient de corrélation de Pearson";
      endlayout;


    endgraph;
  end;
RUN;

/* Creation du canvas */
ods graphics /height=600 width=800 imagemap;
%prepCorrData(in=varbonheur,out=varbonheur_r);
PROC print data=varbonheur_r(obs=10);
RUN;

PROC sgrender data=varbonheur_r template=corrHeatmap;
RUN;


/*Sélection des données utilisables pour construire notre nouvelle variable de bonheur*/

DATA essbon;
	SET donnees_ess;
	IF (0 <= SEDIRLF <=10) AND  (1 <= ACCDNG <=5) and (0 <= TMENDNG  <=10) and (0 <= TMIMDNG  <=10)and ( 1<= FLRMS <=5) and ( 0<= TMDOTWA <=10) and ( 1<= FLTDPR <=4) AND ( 1<= FLTEEFF <=4) AND ( 1 <= SLPRL <=4)AND ( 1  <= ENRGLOT <=4) and ( 1  <= CLDGNG2 <=4) and ( 0 <= STFLIFE <=10) and ( 0 <= STFJB <=10) and ( 0 <= HAPPY <=10) and ( 1 <= PSTVMS <=5);
RUN;

/*Création d'une variable de bonheur sur le même principe que l'indice de développement humain*/


DATA essbonh;
	SET essbon;
	happy2 = ((((SEDIRLF/10)+ ((5-ACCDNG)/4)+ (TMENDNG/10)+(TMIMDNG/10))/4)*((((FLRMS-1)/4)+(TMDOTWA/10)+((4-FLTDPR)/3)+((4-FLTEEFF)/3))/4)*((((4-SLPRL)/3)+((ENRGLOT-1)/3)+((4-CLDGNG2)/3))/3)*(((STFLIFE/10)+(STFJB/10)+(HAPPY/10)+((5-PSTVMS)/4))/4))**(0.25);
RUN;


PROC UNIVARIATE DATA=essbonh;
	VAR happy2;
RUN;

/* Représentation de la distribution de happy2 */
PROC SGPLOT DATA=essbonh;
	where happy2>=0;
    HISTOGRAM happy2 / WEIGHT = anweight /* pondération */
        FILLATTRS = (color = &col_ensae10); 
    DENSITY happy2 / WEIGHT = anweight TYPE=KERNEL /* pondération */
        LINEATTRS = (color = &col_ensae); 
    REFLINE 0.73564 / AXIS=X LINEATTRS=(COLOR=&col_ensae PATTERN=ShortDash) 
        LABEL="Médiane : 0.74" LABELPOS=MAX; /* Position et style de la ligne */
    KEYLEGEND / LOCATION=INSIDE POSITION=TOPRIGHT; /* légende */
    XAXIS 
        LABEL = "Indice synthétique de bonheur (happy2).";
RUN;


/* Boîtes de Tukey de l’indice synthétique de bonheur en fonction du revenu net */
PROC SGPLOT DATA =essbonh;
	TITLE " Boîtes de TUKEY du sentiment de bonheur en fonction du revenu net";
	WHERE hinctnta<11;
	VBOX happy / CATEGORY = hinctnta CONNECT = MEAN WEIGHT = anweight
	FILLATTRS = (color = &couleur2)
	CONNECTATTRS = (color = &couleur1)
	LINEATTRS = (color = &couleur1)
	MEANATTRS = (color = &couleur1)
	MEDIANATTRS = (color = &couleur1)
	WHISKERATTRS = (color = &couleur1 PATTERN = MediumDash)
	OUTLIERATTRS = (color = &couleur1);
	YAXIS /* titre des ordonnées */
	LABEL = "Niveau de bonheur (happy).";
	XAXIS /* titre des abscises */
	LABEL = "Revenu net total du ménage (hinctnta)." ;
	FORMAT  hinctnta deciles_fmt.;
	FORMAT happy happy_fmt.;
	

/* Format pour stfjbot */
PROC FORMAT;
    VALUE stfjbot_fmt
        0 = '00 très insatisfait'
        1 = '01'
        2 = '02'
        3 = '03'
        4 = '04'
        5 = '05'
        6 = '06'
        7 = '07'
        8 = '08'
        9 = '09'
        10 = '10 très satisfait';
RUN;

/* Boîtes de Tukey de l’indice synthétique de bonheur en fonction de l’équilibre temps de travail et temps perso*/
PROC SGPLOT DATA=essbonh;
	WHERE stfjbot<11;
    VBOX happy2 / CATEGORY = stfjbot CONNECT = MEAN WEIGHT = anweight
        FILLATTRS = (color = &col_ensae10)
        CONNECTATTRS = (color = &col_ensae)
        LINEATTRS = (color = &col_ensae)
        MEANATTRS = (color = &col_ensae)
        MEDIANATTRS = (color = &col_ensae)
        WHISKERATTRS = (color = &col_ensae PATTERN = MediumDash)
        OUTLIERATTRS = (color = &col_ensae);
    YAXIS 
        LABEL = "Indice synthétique de bonheur (happy2).";
    XAXIS 
        LABEL = "Satisfait de l'équilibre entre le temps consacré au travail et le temps dédié à d'autres aspects (stfjbot).";
    FORMAT stfjbot stfjbot_fmt.;
RUN;

/* Création d’un indice synthétique de “qualité d’emploi” */





/* Création d’une HEATMAP*/
%macro prepCorrData(in=, out=);
  /* Run corr matrix for input data, all numeric vars */
  proc corr data=&in. noprint
    pearson
    outp=work._tmpCorr
    vardef=df;
    weight anweight; /* Ajout de la pondération */
  run;
 
  /* Préparer les donnée */
data &out.;
  keep x y r;
  set work._tmpCorr(where=(_TYPE_="CORR"));
  array v{*} _numeric_;
  x = _NAME_;
  do i = dim(v) to 1 by -1;
    y = vname(v(i));
    r = abs(v(i)); /* Appliquer la valeur absolue au coefficient r */
    output;
  end;
run;
 
proc datasets lib=work nolist nowarn;
  delete _tmpCorr;
quit;
%mend;

ods path work.mystore(update) sashelp.tmplmst(read);

proc template;
  define statgraph corrHeatmap;
    dynamic _Title;
    begingraph;
      entrytitle _Title;
      
      /* Définir la palette de couleur (de blanc à rouge) */
      rangeattrmap name='map';
        range 0 -1 / rangecolormodel=(cxffffff CXAC012A); /* De blanc à rouge */
      endrangeattrmap;

      rangeattrvar var=r attrvar=r attrmap='map';

      layout overlay / 
        xaxisopts=(display=(line ticks tickvalues)) 
        yaxisopts=(display=(line ticks tickvalues));
		
        /* Graphique de la heatmap */
        heatmapparm x=x y=y colorresponse=r / /* Utiliser la valeur absolue de r */
      	xbinaxis=false ybinaxis=false
        name = "heatmap" display=all;
      continuouslegend "heatmap" / 
        orient=vertical location=outside title="Coefficient de corrélation de Pearson";
      endlayout;


    endgraph;
  end;
run;



/* Creation du canvas */
ods graphics /height=600 width=800 imagemap;
%prepCorrData(in=vartravail,out=vartravail_r);
proc print data=vartravail_r(obs=10);
run;

proc sgrender data=vartravail_r template=corrHeatmap;
   dynamic _title="Matrice des corrélations de Pearson des déterminants de la profession";
run;


/*On supprime les valeurs manquantes*/
DATA essbonh;
	SET essbonh;
	IF (0<=stfjbot<=10)and (0<=wkdcorga <=10) and (1<=hinctnta<=10) ;
RUN; 


/* Création de l’indice*/
DATA essbonh;
    SET essbonh;
    /* Normalisation de chaque variable */
   	/* stfjbot : satisfaction vis a vis de l'équilibre vie professionnelle - vie personnelle (0 à 10) */
   	stfjbot_norm = stfjbot/10;
    /* wkdcorga : capacité d'organisation (0 à 10) */
    wkdcorga_norm = wkdcorga/10;
    /* iorgact : capacité d'influencer les décisions (0 à 10) */
    /* hinctnta : revenu total (1 à 10) */
    hinctnta_norm = (hinctnta - 1) / 9;  
    /* Calcul de l'indice de "qualité" de l'emploi */
    qual_emploi = (2*stfjbot_norm + 2*wkdcorga_norm + hinctnta_norm)/5;
RUN;

/* Garder uniquement les variables intéressantes */
DATA vartravail;
	SET essbonh(keep=anweight stfjbot_norm wkdcorga_norm hinctnta_norm);
RUN;


/* Représentation de l’histogramme de qual_emploi */ 
PROC SGPLOT DATA=essbonh;
    HISTOGRAM qual_emploi / WEIGHT = anweight /* pondération */
        FILLATTRS = (color = &col_ensae10); 
    DENSITY qual_emploi / WEIGHT = anweight TYPE=KERNEL /* pondération */
        LINEATTRS = (color = &col_ensae); 
    REFLINE 0.675556/ AXIS=X LINEATTRS=(COLOR=&col_ensae PATTERN=ShortDash) 
        LABEL="Médiane : 0.68" LABELPOS=MAX; /* Position et style de la ligne */
    KEYLEGEND / LOCATION=INSIDE POSITION=TOPRIGHT; /* légende */
    XAXIS 
        LABEL = "Indice synthétique de qualité d’emploi (qual_emploi).";
RUN;


/* Heatmap de l’indice synthétique de bonheur en fonction de l’indice synthétique de qualité de l’emploi */
PROC SGPLOT DATA=essbonh;

    HEATMAP X=qual_emploi Y=happy2 / 
        FREQ=anweight 
        COLORMODEL=(white &col_ensae);
    XAXIS 
        LABEL = "Indice synthétique de qualité d'emploi (qual_emploi).";
    
    YAXIS 
        LABEL = "Niveau de bonheur synthétique (happy2)"
        DISCRETEORDER=FORMATTED; /* Utiliser l'ordre du format appliqué à 'happy' */
        FORMAT happy format_happy.; /* Appliquer le format personnalisé à 'happy' */
RUN;


/* Calcul du coefficient de corrélation de PEARSON pour ces 2 variables */
PROC CORR DATA=essbonh PEARSON;
    VAR qual_emploi happy2; /* Variables à analyser */
RUN;
