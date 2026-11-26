
# Incidentlogg – The Wall

## Incident 1 – Fel Service-selector

Tid: 25 november 2026, på kvällen. Exakt tid dokumenterades inte.

**Symptom:** Jag ändrade databasens Service-selector från `app=wall-db` till `app=wall-db-fel`. Efter det blev båda webb-poddarna `0/1 Ready`, men de fortsatte att köra och hade 0 omstarter.

**Hypotes:** Jag misstänkte att webbappen inte kunde nå databasen eftersom Service inte längre hittade rätt databas-pod.

**Bevis:** Jag använde `oc describe service wall-db` och såg att Endpoints var tomt.

Jag använde också port-forward direkt till en webb-pod och testade med curl:

- `/health` gav `200 OK`.
- `/` gav `503 Service Unavailable`.

Det visade att webbprocessen fortfarande kördes, men inte kunde läsa från databasen. Readiness försvann utan att containrarna startades om.

**Åtgärd:** Jag återställde Service-selectorn till `app=wall-db`.

**Verifiering:** Efter reparationen kunde webbappen ansluta till databasen igen. Jag kontrollerade senare att webb-poddarna var redo och att Service hade rätt selector och Endpoints.

**Förebyggande förbättring:** Jag bör kontrollera Service-selector och Endpoints före deployments och efter ändringar, så att Service hittar rätt poddar.

## Incident 2 – Fel DB_NAME

**Tid:** 25 november 2026, på kvällen. Exakt tid dokumenterades inte.

**Symptom:** Jag ändrade `DB_NAME` i ConfigMap från `walldb` till `felaktigdb` och startade om webbappens Deployment.

Den nya webb-podden blev `0/1 Ready` och började starta om. De två gamla webb-poddarna fortsatte fungera eftersom de fortfarande använde det gamla, korrekta databasnamnet.

**Hypotes:** Jag misstänkte att webbappen försökte ansluta till en databas som inte fanns.

En annan möjlig förklaring var att databasens Service inte fungerade, som under incident 1.

**Bevis:** Med `oc logs --previous` såg jag:

`FATAL: database "felaktigdb" does not exist`

Webbappen försökte ansluta 30 gånger och avslutades sedan med:

`RuntimeError: Database could not be initialized`

Till skillnad från incident 1 gick anslutningen fram till PostgreSQL, men servern nekade databasnamnet. Felet uppstod under initieringen, innan Gunicorn han starta webbservern.

**Åtgärd:** Jag ändrade tillbaka `DB_NAME` till `walldb` och körde:

`oc rollout restart deployment/wall-web`

**Verifiering:** Efter återställningen var alla webb-poddar `1/1 Running`. Jag kunde se tidigare meddelanden och skriva ett nytt meddelande.

**Förebyggande förbättring:** Jag ska kontrollera databasnamnet i ConfigMap före en omstart och kontrollera loggarna om en ny pod inte startar.

## Skillnaden mellan incidenterna

I incident 1 kunde webbappen inte hitta databasen genom Service. Webbprocessen fortsatte köra, men readiness försvann.

I incident 2 fungerade nätverksanslutningen till PostgreSQL, men databasnamnet var fel. Därför misslyckades initieringen och den nya webbcontainern startades om.
