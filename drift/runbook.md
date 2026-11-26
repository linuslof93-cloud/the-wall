# Runbook – The Wall

Den här runbooken beskriver hur jag bygger, installerar, kontrollerar och felsöker The Wall i OKD.

GitHub: https://github.com/linuslof93-cloud/the-wall

Route: https://the-wall-student-linus-lof93jobb-gmail-com.apps.okd.cloud2.se/

## 1. Hämta projektet och bygga en image

För att återskapa lösningen behövs Git, Podman, oc och tillgång till ett OKD-projekt.

Jag hämtar projektet från GitHub:

```bash
git clone https://github.com/linuslof93-cloud/the-wall.git
cd the-wall
```

Jag bygger webbappens image från min Containerfile:

```bash
podman build -t quay.io/limpich/the-wall:v2 .
```

Sedan laddar jag upp imagen till Quay.io:

```bash
podman push quay.io/limpich/the-wall:v2
```

För att pusha krävs inloggning och rättigheter till Quay.io. Den publicerade v2-imagen kan också användas direkt utan att byggas igen.

Webbappen använder Python, Flask, Psycopg och Gunicorn. Databasen använder PostgreSQL-imagen `quay.io/kurs/postgresql:2026-10-29`.

## 2. Installera i OKD

Jag loggar in i OKD och väljer projektet där applikationen ska köras.

```bash
oc login https://api.okd.cloud2.se:6443
oc project MITT_PROJEKT
```

`MITT_PROJEKT` byts ut mot namnet på det projekt som ska användas.

YAML-filerna finns i mappen `okd/`.

### Databasuppgifter

I GitHub finns `okd/database-secret.yaml` med ett exempellösenord.

Jag gör en separat kopia för installationen:

```bash
cp okd/database-secret.yaml okd/database-secret-local.yaml
```

Jag öppnar kopian och ändrar `POSTGRES_PASSWORD` till ett eget lösenord.

```bash
vim okd/database-secret-local.yaml
```

Jag ska inte lägga upp filen med mitt riktiga lösenord på GitHub.

Sedan skapar jag Secret i OKD:

```bash
oc apply -f okd/database-secret-local.yaml
```

### Installera databasen

Jag skapar först databassens lagring och Service:

```bash
oc apply -f okd/wall-db-data.yaml
oc apply -f okd/wall-db-service.yaml
```

Sedan startar jag PostgreSQL:

```bash
oc apply -f okd/wall-db-deployment.yaml
```

Jag kontrollerar att databasen är redo:

```bash
oc rollout status deployment/wall-db
oc get pvc
```

PVC:n heter `wall-db-data` och ska visa `Bound`.

### Installera webbappen

Jag skapar ConfigMap och webbappens Service:

```bash
oc apply -f okd/wall-configmap.yaml
oc apply -f okd/wall-web-service.yaml
```

Sedan lägger jag till nätverkspolicyn och webbappens Deployment:

```bash
oc apply -f okd/wall-db-networkpolicy.yaml
oc apply -f okd/wall-web-deployment.yaml
```

Till sist skapar jag HPA och Route:

```bash
oc apply -f okd/wall-web-hpa.yaml
oc apply -f okd/the-wall-route.yaml
```

Route ska peka på Service `wall-web`.


## 3. Kontrollera att allt fungerar

Jag kontrollerar att Poddarna körs:

```bash
oc get pods
```

Sedan kontrollerar jag båda Deployments:

```bash
oc rollout status deployment/wall-db
oc rollout status deployment/wall-web
```

Jag kontrollerar även Services, PVC och Route:

```bash
oc get services
oc get pvc
oc get route
```

Webb-Poddarna och databasen ska vara redo. PVC:n ska vara `Bound`.

Jag öppnar sedan webbappen via Route och kontrollerar att sidan fungerar.

Vid en ny installation ska jag kunna skriva ett nytt meddelande och se att det sparas.

Vid en återstart med befintlig PVC ska även de gamla meddelandena finnas kvar.

## 4. Byta databaslösenord

Jag ansluter till PostgreSQL:

```bash
oc exec -it deployment/wall-db -- psql -U walluser -d walldb
```

I PostgreSQL byter jag lösenord:

```text
\password walluser
```

Jag avslutar med:

```text
\q
```

Sedan ändrar jag lösenordet i min lokala Secret-fil så att det blir samma som i PostgreSQL.

Jag uppdaterar Secret i OKD:

```bash
oc apply -f okd/database-secret-local.yaml
```

Efteråt startar jag om webbappen så att den läser det nya lösenordet:

```bash
oc rollout restart deployment/wall-web
```

Jag kontrollerar att webbappen fungerar igen. Under själva bytet kan det bli ett kort avbrott om lösenorden inte stämmer överens.

## 5. Felsökning

Om något inte fungerar börjar jag med:

```bash
oc get pods
```

Sedan kan jag läsa webbappens loggar:

```bash
oc logs deployment/wall-web
```

Om en Pod har problem använder jag `oc describe pod` och anger Poddens namn.

Under mina tester såg jag bland annat:

- `ImagePullBackOff` när en image inte fanns.
- HTTP 503 när webbappen inte kunde nå databasen.
- Felaktigt databasnamn som gjorde att den nya webbcontainern startade om.

Jag kan även kontrollera att databasens Service hittar rätt Pod:

```bash
oc describe service wall-db
```

Den ska ha selectorn `app=wall-db` och en adress under Endpoints.

Jag kontrollerar också att ConfigMap har rätt databasnamn:

```bash
oc get configmap wall-config -o yaml
```

`DB_NAME` ska vara `walldb`.

## 6. Rollback

Om en ny webbversion inte fungerar kan jag återställa föregående Deployment-revision:

```bash
oc rollout undo deployment/wall-web
```

Sedan kontrollerar jag att utrullningen lyckades:

```bash
oc rollout status deployment/wall-web
```

Jag kontrollerar även att webbappen använder rätt image och fungerar via Route.

Rollback kräver att det finns en tidigare fungerande revision i OKD.

## 7. Starta om utan att förlora databasen

Databasen använder PVC:n `wall-db-data`, där meddelandena lagras.

Jag kan starta om PostgreSQL med:

```bash
oc rollout restart deployment/wall-db
```

Jag kontrollerar att databasen startar igen:

```bash
oc rollout status deployment/wall-db
oc get pvc
```

Jag kontrollerar sedan att gamla meddelanden fortfarande visas i The Wall.

Om Deployments och Services behöver återskapas kan jag använda samma YAML-filer som i installationsdelen.

Jag ska behålla den befintliga Secret och PVC:n vid återskapandet.

Jag ska inte ta bort PVC:n eftersom den innehåller datan.

En PVC är inte samma sak som en backup. För en riktig driftmiljö behöver PostgreSQL också säkerhetskopieras separat. Det har jag inte testat i det här projektet.
