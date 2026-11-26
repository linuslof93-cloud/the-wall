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




## Bevisfiler

Här finns screenshots från testerna. Klicka på länkarna för att se resultaten.

| Test | Bevis |
|---|---|
| V1 – Bygge och start | [Imagebygge](bevis/v1-imagebygge.png), [Lokal start](bevis/v1-lokal-start.png), [Beroendeversioner](bevis/v1-beroendeversioner.png) |
| V2 – Trafikkedja | [HTTPS och omdirigering](bevis/v2-https-redirect.png), [Meddelanden](bevis/v2-meddelanden.png) |
| V3 – Nätverk | [Klient till webb](bevis/v3-klient-till-webb.png), [Blockerad databasanslutning](bevis/v3-databas-blockerad.png) |
| V4 – Säkerhet | [Secret-referenser](bevis/v4-secret-referenser.png), [UID](bevis/v4-uid-webb.png), [Säkerhetsfält](bevis/v4-sakerhetsfalt.png) |
| V5 – Lösenordsbyte | [Felaktigt lösenord nekas](bevis/v5-felaktigt-losenord-nekas.png) |
| V6 – Persistens | [PVC Bound](bevis/v6-pvc-bound.png), [SQL-meddelanden](bevis/v6-meddelanden-sql.png), [PVC-UID](bevis/v6-pvc-uid.png) |
| V7 – Skalning | [Lasttest](bevis/v7-last-4-klienter.png), [HPA 2 till 3 till 2](bevis/v7-hpa-2-3-2.png) |
| V8 – Release | [Källkodsdiff](bevis/v8-kallkodsdiff.png), [ImagePullBackOff](bevis/v8-imagepullbackoff.png), [Imagefel](bevis/v8-image-pull-fel.png) |
| V9 – Incidenter | [Felaktig selector](bevis/v9-felaktig-service-selector.png), [Readiness](bevis/v9-readiness-0-restarts-0.png), [Health 200](bevis/v9-health-200.png), [HTTP 503](bevis/v9-startsida-503.png), [Incident 2](bevis/v9-incident2-crashloop.png) |
| V10 – Återskapande | [Borttagning](bevis/v10-borttagning.png), [Återskapande](bevis/v10-aterskapande.png), [Meddelanden kvar](bevis/v10-meddelanden-kvar.png) |

