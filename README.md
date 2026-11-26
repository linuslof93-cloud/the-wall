## Installation

Jag byggde The Walls webbimage med Podman och publicerade den som quay.io/limpich/the-wall:v2. Databasen använder Jonas PostgreSQL-image quay.io/kurs/postgresql:2026-10-29. Installationsfilerna ligger i okd/.

Du behöver Bash, oc och tillgång till ditt tilldelade OKD-projekt. Klustret behöver kunna hämta båda images från Quay.io och tilldela 1 GiB lagring via gp3-csi. HPA:n behöver tillgång till poddarnas CPU-mätvärden.

Beroenden:

The Wall V1 quay.io/limpich/the-wall:v1
THe wall V2 quay.io/limpich/the-wall:v2
Postgresql quay.io/postgresql:21206-10-29

imagen utgår ifron python 3.12-slim och installerar flask, psycog & gunicorn från requirements.txt

## OKD.

Kör kommandona ifrån reports rot .

## Välj projekt

oc project DITT_PROJEKTNAMN
oc whoami

## Skapa dina egna secrets för databasen.

Öppna okd/database-secret.yaml och fyll i egna värden för POSTGRES_USER och POSTGRES_PASSWORD. Både wall-db & wall-webb läser database-secret. Kör sedan oc apply -f okd/database-secret.yaml från repots rot. Filen som lämnas in innehåller exempelvärden. 




## PostgreSQL &  Volym
Kör kommandona från repots rot. Vid en ny installation skapas en tom volym när wall-db-data skapas för första gången. Om PVC:n redan finns återanvänds den.

oc apply -f okd/wall-db-data.yaml
oc apply -f okd/wall-db-service.yaml
oc apply -f okd/wall-db-deployment.yaml
oc rollout status deployment/wall-db --timeout=180s
oc get pvc wall-db-data

Dubbelkolla att PVC:n står som bound.

## Starta webappen

oc apply -f okd/wall-configmap.yaml
oc apply -f okd/wall-db-networkpolicy.yaml
oc apply -f okd/wall-web-service.yaml
oc apply -f okd/wall-web-deployment.yaml
oc rollout status deployment/wall-web --timeout=180s
oc apply -f okd/the-wall-route.yaml
oc apply -f okd/wall-web-hpa.yaml

## Kolla installationen 
Kör oc get route the-wall och öppna adressen från kolumnen HOST/PORT med https:// framför. Vid en ny installation ska meddelandelistan vara tom. Skriv ett testmeddelande och kontrollera att det visas efter att du skickat det.

oc get deploy wall-web wall-db
oc get pvc wall-db-data
oc get hpa wall-web-hpa
oc get route the-wall

Kontrollera att båda Deployments har redo repliker och att PVC:n är Bound. Öppna adressen från kolumnen HOST/PORT med https:// framför. Vid uppstart med en ny tom volym ska sidan visa v2-rubriken och en tom meddelandelista. Skriv ett meddelande på bollplanket och starta om /ta bort poddarna för att se att datan stannar kvar. 

