# The Wall – OKD

**Namn:** Linus Löf  
**Projekt:** The Wall – containerteknik  
**GitHub:** https://github.com/linuslof93-cloud/the-wall  
**Route:** https://the-wall-student-linus-lof93jobb-gmail-com.apps.okd.cloud2.se/

## Om projektet

Jag har byggt och driftsatt The Wall med Flask, Gunicorn och PostgreSQL i OKD. Webbappen och databasen körs i separata Poddar. Meddelandena lagras på en PVC så att de finns kvar efter omstarter.

Jag utgick från Jonas Björks The Wall:

- **Upstream-commit:** `caa199b60b0218675bc2156f0dff00131d464512`
- **Egna ändringar:** Anpassad Containerfile för OKD, v2-rubrik, YAML-filer för driftsättning, hälsokontroller, resurser, HPA och NetworkPolicy.

## Images och beroenden

| Komponent | Image |
|---|---|
| The Wall v1 | `quay.io/limpich/the-wall:v1` |
| The Wall v2 | `quay.io/limpich/the-wall:v2` |
| PostgreSQL | `quay.io/kurs/postgresql:2026-10-29` |

Registry: **Quay.io**

Webbimagen bygger på `python:3.12-slim` och installerar Flask, Psycopg och Gunicorn via `requirements.txt`. De exakta Python-beroendena finns i den filen.

## Bygga webbimagen

Kör från projektets rot:

```bash
podman build -t quay.io/limpich/the-wall:v2 .
podman push quay.io/limpich/the-wall:v2
```

För att ladda upp imagen behöver du behörighet till mitt Quay.io-repository. Den publicerade v2-imagen kan även användas direkt.

## Installation i OKD

Du behöver Git, `oc`, åtkomst till ett OKD-projekt och ett kluster som kan hämta images från Quay.io.

Hämta projektet:

```bash
git clone https://github.com/linuslof93-cloud/the-wall.git
cd the-wall
```

Logga in i OKD och välj projekt:

```bash
oc login https://api.okd.cloud2.se:6443
oc project DITT_PROJEKTNAMN
oc whoami
```

### 1. Databasuppgifter

Filen `okd/database-secret.yaml` innehåller exempeluppgifter.

Ändra lösenordet till ett eget innan installationen. Behåll användarnamnet `walluser`, eftersom databasen använder det.

```bash
oc apply -f okd/database-secret.yaml
```

Använd inte mitt exempellösenord i en riktig installation.

### 2. PostgreSQL och lagring

```bash
oc apply -f okd/wall-db-data.yaml
oc apply -f okd/wall-db-service.yaml
oc apply -f okd/wall-db-deployment.yaml
oc rollout status deployment/wall-db --timeout=180s
oc get pvc wall-db-data
```

PVC:n ska visa `Bound`. Vid en ny installation används en tom volym. Om samma PVC redan finns återanvänds datan.

### 3. Starta webbappen

```bash
oc apply -f okd/wall-configmap.yaml
oc apply -f okd/wall-db-networkpolicy.yaml
oc apply -f okd/wall-web-service.yaml
oc apply -f okd/wall-web-deployment.yaml
oc rollout status deployment/wall-web --timeout=180s
oc apply -f okd/the-wall-route.yaml
oc apply -f okd/wall-web-hpa.yaml
```

Route ska peka på `wall-web`-Service. HPA:n använder minst 2 och högst 3 webb-Poddar.

Använd inte `oc apply -f okd/`, eftersom mappen även innehåller äldre manifest och testfiler.

## Verifiering

Kontrollera att allt har startat:

```bash
oc get pods
oc get deploy wall-web wall-db
oc get pvc wall-db-data
oc get hpa wall-web-hpa
oc get route the-wall
```

Kontrollera att båda Deployments har redo Poddar och att PVC:n är `Bound`.

Öppna Route-adressen med HTTPS. Vid en ny installation ska sidan visa v2-rubriken och en tom meddelandelista.

Skriv ett testmeddelande och kontrollera att det visas. Vid återstart med samma PVC ska tidigare meddelanden finnas kvar.

## Drift och tester

- Driftinstruktioner: [Runbook](drift/runbook.md)
- Genomförda tester: [Verifieringsprotokoll](tester/verifieringsprotokoll.md)
- Driftincidenter: [Incidentlogg](drift/incidentlogg.md)
