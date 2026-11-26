# Runbook

## 1. Bygga en image

Jag går till projektmappen och bygger en ny image från min Containerfile:

cd ~/the-wall
podman build -t quay.io/limpich/the-wall:v2 .

Sedan laddar jag upp den till Quay.io:

podman push quay.io/limpich/the-wall:v2

## 2. Installera i OKD

Jag loggar in i OKD och väljer mitt projekt.

YAML-filerna finns i mappen `~/the-wall/okd/`.

Först behöver databasen sin Secret och lagringsvolym. Sedan skapas databasen, webbappen och deras Services. Till sist används Route, NetworkPolicy och HPA.

Jag använder `oc apply -f` med respektive YAML-fil för att skapa resurserna.

## 3. Kontrollera att allt fungerar

Jag kontrollerar Poddarna:

oc get pods

Jag kontrollerar också att Deploymenten fungerar:

oc rollout status deployment/wall-web

Sedan öppnar jag The Wall via Route och kontrollerar att gamla meddelanden visas och att jag kan skriva ett nytt.

## 4. Byta databaslösenord

Jag ansluter till PostgreSQL och byter lösenord för walluser med kommandot \password walluser.

Sedan uppdaterar jag samma lösenord i `database-secret.yaml` och applicerar Secret-filen igen.

Till sist startar jag om webbappen:


oc rollout restart deployment/wall-web


Jag kontrollerar därefter att webbappen kan ansluta till databasen.

## 5. Felsökning

Om något inte fungerar börjar jag med:


oc get pods


Sedan kan jag läsa loggarna:


oc logs deployment/wall-web


Om en Pod har problem kan jag använda oc describe pod för att se felmeddelanden och händelser.

Under mina incidenttester såg jag bland annat ImagePullBackOff, HTTP 503 och felaktigt databasnamn.

## 6. Rollback

Om en ny version inte fungerar kan jag gå tillbaka till föregående Deployment-revision:

oc rollout undo deployment/wall-web

## 7. Starta om utan att förlora databasen

Databasen använder en PVC som heter `wall-db-data`.

Jag kan starta om databasen med:

oc rollout restart deployment/wall-db

Jag kontrollerar sedan att databasen startar och att volymen fortfarande finns:


oc get pvc

Meddelandena ligger på PVC:n och ska därför finnas kvar när databas-Podden startas om. Jag ska inte ta bort PVC:n eftersom den innehåller datan.
