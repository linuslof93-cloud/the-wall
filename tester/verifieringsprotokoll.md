Verifieringsprotokoll – The Wall

Samtliga tester är genomförda -  Resultaten finns dokumenterade med printscreens i min ursprungliga projektdokumentation. Bevisbilderna ligger i tester/bevis/

V1 – Bygge och start

Test: Byggde och startade The Wall med Podman.

Kommandon: podman build, podman run

Förväntat: Applikationen ska starta.

Resultat: Imagen byggdes och webbappen fungerade lokalt.

V2 – Trafikkedja

Test: Öppnade webbappen via OKD Route.

Kommando: oc get route

Förväntat: Webbappen ska kunna nås via HTTPS.

Resultat: The Wall gick att öppna via Route och visade meddelanden.

V3 – Nätverk

Test: Testade anslutningar från en tillfällig test-Pod.

Förväntat: Test-Podden ska kunna nå webbappen men inte PostgreSQL direkt.

Resultat: Webbappen svarade och anslutningen till databasporten blockerades.

V4 – Säkerhet

Test: Kontrollerade UID, Secret och säkerhetsinställningar.

Förväntat: Containrarna ska kunna köras utan root och lösenordet ska hämtas från Secret.

Resultat: Kontrollerade UID och Secret-referenser i OKD.

V5 – Lösenordsbyte

Test: Bytte PostgreSQL-lösenord och uppdaterade Secret.

Förväntat: Webbappen ska fungera med det nya lösenordet.

Resultat: Webbappen fungerade efter uppdatering och omstart. Jag testade också att ett felaktigt lösenord nekades.

V6 – Persistens

Test: Tog bort databas-Podden och lät OKD skapa en ny.

Kommando: oc get pvc

Förväntat: Meddelandena ska finnas kvar.

Resultat: Databas-Podden ersattes men PVC:n behölls och meddelandena fanns kvar.

V7 – Skalning

Test: Belastade webbappen och följde HPA.

Kommando: oc get hpa wall-web-hpa -w

Förväntat: HPA ska kunna skala mellan 2 och 3 Poddar.

Resultat: Efter att jag sänkt CPU-requesten till 10m såg jag förloppet 2 → 3 → 2.

V8 – Release och rollback

Test: Byggde v1 och v2 samt testade en felaktig image.

Kommandon: oc rollout history, oc rollout undo

Förväntat: Den felaktiga utrullningen ska kunna återställas.

Resultat: Den nya Podden fick ImagePullBackOff. Jag gjorde rollback och återställde fungerande v2.

V9 – Driftincidenter

Test: Ändrade databasens Service-selector och därefter DB_NAME.

Förväntat: Felen ska kunna diagnostiseras och repareras.

Resultat: Första incidenten gav 200 på /health, 503 på / och förlorad readiness. Andra incidenten gav databasfel vid uppstart och containeromstart. Båda felen reparerades.

V10 – Återskapande

Test: Tog bort och återskapade två Deployments och två Services från YAML.

Förväntat: Applikationen ska fungera med befintlig Secret och PVC.

Resultat: Webbappen och databasen startade igen. Gamla meddelanden fanns kvar och nya kunde sparas.
