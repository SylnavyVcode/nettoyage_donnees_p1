# Movie Data Analysis — PostgreSQL

Pipeline d'analyse reproductible sur 508 films sortis entre 2012 et 2016 :
import CSV, nettoyage en base, exploration, analyse économétrique et
contrôle qualité automatisé. Tout s'exécute avec une seule commande.

```bash
./scripts/run_sql.sh
```

**Stack** PostgreSQL 16 · SQL · Bash · Python (pandas, matplotlib) · Git

---

## Résultats principaux

| Indicateur | Valeur |
|---|---|
| Films analysés | 508 (06/01/2012 → 26/08/2016) |
| Genres | 17 |
| Réalisateurs principaux | 414 |
| Budget médian / moyen | 30,0 M$ / 48,9 M$ |
| Recette médiane / moyenne | 79,4 M$ / 152,0 M$ |
| Budget cumulé | 24,8 Md$ |
| Recette cumulée | 77,2 Md$ |
| Corrélation budget ↔ recette (Pearson) | **0,759** (R² = 0,576) |
| Corrélation des rangs (Spearman) | 0,732 |
| Élasticité recette/budget | **0,859** |
| Films au-dessus du seuil de rentabilité sectoriel | **53,1 %** |
| Tests qualité | 16 / 16 au vert |

### Trois constats

**1. Le budget explique un peu plus de la moitié de la variance des
recettes, pas davantage.**
R² = 0,576 : près de 42 % de la variation reste inexpliquée par le seul
budget. Pearson (0,759) et Spearman (0,732) étant proches, la relation
n'est pas un artefact de quelques blockbusters. Et la relation n'est pas
causale : les studios investissent davantage sur les projets qu'ils
anticipent comme porteurs.

**2. Les rendements sont décroissants.**
L'élasticité de 0,859 signifie qu'un budget supérieur de 1 % s'accompagne
d'une recette supérieure de 0,86 % seulement. Doubler le budget ne double
pas la recette.

**3. Le choix du seuil de rentabilité change presque tout.**

| Critère retenu | Films « rentables » | Part |
|---|---|---|
| `recette > budget` | 415 | 81,7 % |
| `recette ≥ 2,5 × budget` (seuil sectoriel) | 270 | **53,1 %** |

L'écart porte sur **145 films**, soit 28,5 % de l'échantillon. Le seuil
naïf ignore que les salles conservent environ la moitié des recettes et
que le marketing (P&A) est absent du jeu de données. C'est le résultat
méthodologique le plus important de ce dépôt, et il est détaillé dans
[`docs/methodology.md`](docs/methodology.md).

### Un résultat contre-intuitif

Le multiple recette/budget ne décroît pas régulièrement avec le budget :

| Quintile de budget | Plage | Multiple médian | Part au-dessus de 2,5x |
|---|---|---|---|
| 1 | 1 – 11,8 M$ | 3,95 | 60,8 % |
| 2 | 12 – 20 M$ | 2,53 | 52,0 % |
| 3 | 21 – 40 M$ | 2,36 | 48,0 % |
| 4 | 40 – 80 M$ | 2,33 | 48,5 % |
| 5 | 80 – 250 M$ | 2,84 | 56,4 % |

La relation est en U : les petits budgets (horreur, thriller) et les très
gros budgets performent mieux en relatif que le milieu de gamme. Le
modèle log-log, qui impose une pente unique, ne pouvait pas le montrer —
d'où l'intérêt de croiser régression et découpage en quintiles.

![Budget et recette](results/figures/01_budget_vs_recette.png)

---

## Avertissement sur les données

`revenue` est une **recette brute de box-office**, pas un revenu encaissé
par le studio. `revenue - budget` n'est donc **pas un profit** :

- les exploitants de salles conservent environ la moitié des recettes ;
- les dépenses de marketing et distribution (P&A), couramment 50 à 100 %
  du budget de production, sont absentes du fichier ;
- les revenus annexes (vidéo, streaming, TV, produits dérivés) aussi.

C'est pourquoi la colonne dérivée s'appelle `gross_minus_budget` et non
`profit`, et pourquoi les analyses de rentabilité utilisent le seuil de
2,5 × le budget. Limites complètes : [`docs/methodology.md`](docs/methodology.md).

---

## Structure du dépôt

```
movie-data-analysis/
├── README.md
├── LICENSE
├── requirements.txt              dépendances Python (étape optionnelle)
├── .env.example                  modèle de configuration (versionné)
├── .env                          identifiants réels (JAMAIS versionné)
├── .gitignore
│
├── data/
│   ├── raw/movieData.csv         source, versionnée et jamais modifiée
│   └── processed/                généré par sql/03
│
├── sql/
│   ├── 01_create_tables.sql      schéma : staging + table analytique
│   ├── 02_import_data.sql        import CSV (psql uniquement)
│   ├── 03_clean_data.sql         nettoyage, typage, export CSV propre
│   ├── 04_exploration.sql        volumétrie, distributions, descriptives
│   ├── 05_analysis.sql           rentabilité, corrélation, régressions
│   └── 06_quality_tests.sql      16 tests, échoue si un invariant casse
│
├── scripts/
│   ├── run_sql.sh                exécute le SQL et archive les résultats
│   └── analyze.py                extraction PostgreSQL → graphiques
│
├── results/
│   ├── reports/                  sorties texte lisibles, versionnées
│   ├── tables/                   tableaux CSV exportés
│   └── figures/                  graphiques PNG
│
├── docs/methodology.md           données, choix techniques, limites
└── .vscode/settings.json         configuration SQLTools du projet
```

---

## Installation

### Prérequis

PostgreSQL 12 ou supérieur (les colonnes `GENERATED ... STORED` en
dépendent), et le client `psql`.

```bash
# Debian / Ubuntu
sudo apt install postgresql postgresql-client

# vérifier
psql --version
pg_isready
```

### 1. Créer le rôle et la base

```bash
sudo -u postgres psql
```

```sql
CREATE ROLE movie_user WITH LOGIN PASSWORD 'votre_mot_de_passe';
CREATE DATABASE movie_analysis OWNER movie_user;
\q
```

### 2. Configurer les identifiants

```bash
cp .env.example .env
```

Puis renseigner `.env` :

```bash
PGHOST=localhost
PGPORT=5432
PGDATABASE=movie_analysis
PGUSER=movie_user
PGPASSWORD=votre_mot_de_passe
```

> **À quoi sert `.env`, concrètement**
>
> `PGHOST`, `PGPORT`, `PGDATABASE`, `PGUSER` et `PGPASSWORD` ne sont pas
> des noms choisis au hasard : ce sont les variables d'environnement
> standard de **libpq**, la bibliothèque cliente de PostgreSQL. `psql`,
> `pg_dump` et `psycopg2` les lisent automatiquement.
>
> Une fois ces variables chargées dans le shell, la commande
> `psql -f sql/04_exploration.sql` fonctionne **sans aucun argument**
> `-h`, `-p`, `-U` ni `-d`. C'est `run_sql.sh` qui fait ce chargement, via
> `set -a; source ./.env; set +a` — `set -a` exporte les variables dans
> l'environnement, ce qui est indispensable puisque psql est un processus
> enfant.
>
> `.env` est ignoré par git. Aucun mot de passe ne part sur GitHub.

### 3. Lancer le pipeline

```bash
./scripts/run_sql.sh
```

Sortie attendue :

```
Connexion OK : movie_user@localhost:5432/movie_analysis
=====> 01_create_tables
=====> 02_import_data
=====> 03_clean_data
=====> 04_exploration
=====> 05_analysis
=====> 06_quality_tests
Termine. 6 script(s) execute(s).
```

---

## Exécuter les requêtes : trois façons

### A. Le script (recommandé)

```bash
./scripts/run_sql.sh              # tout le pipeline, 01 → 06
./scripts/run_sql.sh 04           # une seule étape
./scripts/run_sql.sh 01 02 03     # plusieurs, dans cet ordre
./scripts/run_sql.sh --help
```

Chaque exécution affiche les résultats **et** les archive dans
`results/reports/<étape>.txt`. C'est la réponse à « comment sauvegarder
les résultats » : `psql | tee fichier` fait les deux en une fois.

Le script charge `.env`, se place à la racine du dépôt (ce qui rend tous
les chemins relatifs valides), vérifie la connexion avant de commencer, et
s'arrête à la première erreur SQL.

**Codes de sortie**, pour l'intégration continue :

| Code | Cause |
|---|---|
| 0 | succès |
| 1 | `.env` absent, argument invalide, connexion impossible |
| 3 | erreur SQL ou test qualité en échec |

### B. psql directement

```bash
set -a; source ./.env; set +a      # charge les identifiants
psql -v ON_ERROR_STOP=1 -f sql/04_exploration.sql

# avec archivage du résultat
psql -f sql/04_exploration.sql | tee results/reports/04_exploration.txt

# export CSV d'une requête ponctuelle
psql --csv -c "SELECT genre, count(*) FROM movie_data GROUP BY genre" \
     > results/tables/genres.csv
```

`ON_ERROR_STOP=1` n'est pas optionnel : **sans ce réglage, psql continue
après une erreur et renvoie malgré tout un code de sortie 0.** Un pipeline
cassé passerait pour un succès.

### C. SQLTools dans VS Code

L'extension est déjà configurée pour ce projet : `.vscode/settings.json`
contient la connexion `movie_analysis (local)`, versionnée sans mot de
passe (`askForPassword: true`).

1. Installer **SQLTools** et **SQLTools PostgreSQL/Cockroach Driver**
   (VS Code les propose automatiquement, voir `.vscode/extensions.json`).
2. Ouvrir le dossier du projet — pas un fichier isolé : c'est l'ouverture
   du **dossier** qui charge `.vscode/settings.json`.
3. Icône SQLTools dans la barre latérale → la connexion apparaît →
   **Connect** → saisir le mot de passe.
4. Ouvrir un `.sql` et lancer avec `Ctrl+E Ctrl+E` (requête sous le
   curseur) ou `Ctrl+E Ctrl+B` (fichier entier).

> **Le point qui bloque tout le monde : `sql/02_import_data.sql` ne peut
> pas être exécuté depuis SQLTools.**
>
> `\copy` n'est **pas du SQL**. C'est une méta-commande de `psql`, le
> client en ligne de commande. SQLTools et pgAdmin sont d'autres clients :
> ils envoient du SQL au serveur et ignorent les commandes commençant par
> `\`. Lancer ce fichier depuis SQLTools produit une erreur de syntaxe.
>
> Faire l'import une fois avec `./scripts/run_sql.sh 02`. Ensuite, **tout
> le reste du projet (03 à 06) s'exécute normalement depuis SQLTools**,
> à l'exception des quelques lignes `\copy` d'export en fin de fichiers 03,
> 04 et 05 — elles n'affectent pas les données, seulement l'écriture des
> CSV.

Pour exporter un résultat depuis SQLTools : bouton **Export** au-dessus
de la grille de résultats. La destination est déjà pointée sur
`results/tables/` dans la configuration.

---

## Le pipeline, étape par étape

| Fichier | Rôle | SQLTools |
|---|---|---|
| `01_create_tables.sql` | Table de staging (tout en `TEXT`) + table analytique typée, avec contraintes `CHECK`, `UNIQUE` et trois colonnes générées | oui |
| `02_import_data.sql` | `\copy` du CSV vers le staging, encodage UTF-8 déclaré | **non** |
| `03_clean_data.sql` | `"$15,000,000.00"` → `15000000.00`, chaînes vides → `NULL`, typage des dates, export du CSV propre | oui |
| `04_exploration.sql` | Volumétrie, répartitions, saisonnalité, statistiques descriptives, top réalisateurs et acteurs | oui |
| `05_analysis.sql` | Performance par genre, seuils de rentabilité, corrélations, régressions, quintiles | oui |
| `06_quality_tests.sql` | 16 tests de qualité et de non-régression | oui |

### Modèle de données

```
movie_data_raw                     movie_data
─────────────────                  ───────────────────────────────
movie_title    TEXT                movie_id        PK, identity
release_date   TEXT       ──┐      movie_title     VARCHAR(120) NOT NULL
wikipedia_url  TEXT         │      release_date    DATE         NOT NULL
genre          TEXT         │      genre           VARCHAR(30)  NOT NULL
director_1..2  TEXT         │      director_1..2   VARCHAR(60)
cast_1..5      TEXT         │      cast_1..5       VARCHAR(60)
budget         TEXT         │      budget          NUMERIC(14,2) CHECK > 0
revenue        TEXT         │      revenue         NUMERIC(14,2) CHECK > 0
                            │      ─── colonnes générées ───
      nettoyage sql/03  ────┘      release_year         SMALLINT
                                   gross_minus_budget   NUMERIC(14,2)
                                   revenue_budget_ratio NUMERIC(10,4)
```

Trois choix de conception, justifiés dans `docs/methodology.md` :

- **un étage de staging** parce que `"$15,000,000.00"` ne peut pas être
  casté directement — on charge brut, on transforme dans la base (ELT) ;
- **des colonnes générées** plutôt qu'une vue : impossible à
  désynchroniser, disponibles partout, aucun objet de plus à maintenir ;
- **aucun index** hors clés : sur 508 lignes, un *Seq Scan* est plus
  rapide qu'un parcours d'index. Un index ici serait du code mort.

---

## Tests qualité

```bash
./scripts/run_sql.sh 06
```

16 contrôles couvrant la cohérence du pipeline et la validité des
données :

| # | Contrôle |
|---|---|
| T01–T03 | staging chargé, aucune perte staging → table analytique, empreinte du dataset (508 lignes) |
| T04–T05 | sommes des budgets et des recettes identiques avant/après nettoyage — détecte une erreur de parsing des montants |
| T06–T09 | aucun `NULL` obligatoire, aucun doublon, aucune chaîne vide résiduelle, montants strictement positifs |
| T10–T11 | cohérence des colonnes générées |
| T12–T13 | dates dans la plage attendue, aucune date future |
| T14–T16 | genres mono-valués, aucun caractère monétaire résiduel, URL sources cohérentes |

En cas d'échec, le script lève une exception PostgreSQL et renvoie un code
de sortie non nul — `run_sql.sh` s'arrête. **Un test incapable de faire
échouer la chaîne n'est pas un test, c'est un affichage.** Le
comportement a été vérifié par corruption volontaire d'une ligne : 4 tests
passent en FAIL, code de sortie 3.

---

## Étape Python (optionnelle)

Les six scripts SQL produisent l'intégralité des résultats chiffrés sans
Python. Python ne sert ici qu'à ce que SQL ne sait pas faire : dessiner.

```bash
pip install -r requirements.txt
set -a; source ./.env; set +a
python3 scripts/analyze.py
```

Produit quatre figures dans `results/figures/` : nuage budget/recette avec
droite des moindres carrés, version log-log, multiple médian par genre,
taux de franchissement du seuil par genre.

Le script lit la base via `psycopg2.connect("")` — avec une chaîne vide,
libpq se rabat sur les mêmes variables `PG*` que psql, donc aucun
identifiant n'est écrit dans le code. Si la base est injoignable, il
bascule automatiquement sur `data/processed/movieData_clean.csv`.

---

## Où sont les résultats

| Dossier | Contenu | Versionné |
|---|---|---|
| `results/reports/` | sortie texte complète de chaque étape, horodatée | oui |
| `results/tables/` | tableaux CSV (genres, évolution annuelle, rentabilité par film) | oui |
| `results/figures/` | graphiques PNG | oui |
| `data/processed/` | `movieData_clean.csv`, jeu nettoyé | non (régénérable) |

Les rapports et tableaux sont versionnés volontairement : un lecteur doit
pouvoir consulter les résultats sans installer PostgreSQL.

---

## Dépannage

| Symptôme | Cause et correctif |
|---|---|
| `ERREUR : fichier .env absent` | `cp .env.example .env` puis renseigner les identifiants |
| `connexion a PostgreSQL impossible` | vérifier `pg_isready`, l'existence de la base (`createdb movie_analysis`) et du rôle (`psql -d postgres -c "\du"`) |
| `syntax error at or near "\"` dans SQLTools | fichier contenant `\copy` : utiliser `./scripts/run_sql.sh 02` |
| `could not open file ... for reading` | psql n'est pas lancé depuis la racine du dépôt — passer par `run_sql.sh`, qui s'y place seul |
| `permission denied for table movie_data` | la base n'appartient pas au rôle : `ALTER DATABASE movie_analysis OWNER TO movie_user;` |
| Caractères accentués corrompus | base créée avec un encodage non UTF-8 : `createdb -E UTF8 movie_analysis` |
| Un test qualité en FAIL après modification du CSV | comportement attendu : T03 verrouille l'empreinte du dataset. Mettre à jour la valeur attendue **après** avoir revalidé les analyses |

---

## Données et licence

Le fichier `data/raw/movieData.csv` rassemble des métadonnées de films
(titre, date, genre, équipe, budget, recette) dont chaque entrée référence
une page Wikipédia en anglais. Les montants sont des estimations publiques
arrondies, pas des chiffres comptables — voir `docs/methodology.md`,
section 2.

Le code de ce dépôt (SQL, Bash, Python) est publié sous licence MIT
(`LICENSE`). Cette licence ne couvre pas les données.

---

## Auteur

**MABIKA Sylnavy**
Développeur web fullstack · QA · Statisticien-économiste
