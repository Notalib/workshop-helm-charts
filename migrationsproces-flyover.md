# Fra eksisterende system til den nye platform — proces-overblik

> **Status:** udkast til drøftelse. Overblikket er stabilt (kriterierne er vedtaget i
> Teknologirådet); de detaljerede trin under cloud-readiness skrives efter workshop #3, når vi har
> konkrete blockers fra rigtige systemer.

## 1. Formål og kontekst

Som del af overgangen til en **container-first**-strategi skal eksisterende systemer så vidt muligt
containeriseres og migreres til den nye Kubernetes-platform **inden for de næste 3 år**.

Dette dokument er den høje flyvehøjde: *hvordan* går et system fra "kører som i dag" til "kører på
platformen", hvem gør hvad, og hvordan vælger vi hvilke systemer der skal flyttes hvornår.

Det er **ikke** en detaljeret opskrift. Den kommer senere, og den bliver skrevet ud fra de faktiske
forhindringer vi støder på med de første systemer.

## 2. Tragten: udvælgelse før prioritering

Teknologirådet delte kriterierne op i to. Den opdeling er hele rygraden i processen, fordi de to
spørgsmål er forskellige og skal stilles i den rækkefølge:

```
   Alle eksisterende systemer
              │
              ▼
   ┌──────────────────────┐
   │  1. UDVÆLGELSE       │   "Kan systemet overhovedet flyttes?"
   │     Kan vi?          │   → ja / nej / ikke endnu
   └──────────┬───────────┘
              │  kandidater
              ▼
   ┌──────────────────────┐
   │  2. PRIORITERING     │   "I hvilken rækkefølge?"
   │     Hvornår?         │
   └──────────┬───────────┘
              │  næste system
              ▼
        Selve processen (afsnit 6)
```

Pointen med at skille dem: et system kan godt være *muligt* at flytte og alligevel være det helt
forkerte at starte med — og omvendt kan et højt prioriteret system vise sig teknisk eller
licensmæssigt umuligt. Bland de to sammen, og man ender med at bruge tid på analyse af systemer der
aldrig skulle have været kandidater.

## 3. Kriterier for udvælgelse — *kan vi?*

### Kompatibilitet

- Kan systemet **overhovedet** containeriseres?
- Er det et **proprietært købesystem** uden container-understøttelse?
- Gør **licensen** det umuligt — eller ugyldiggør den supporten?
- Er der **afregning per instans**, så modellen bliver urimeligt dyr i Kubernetes?
- Har systemet **særlige krav til hardware** det kører på?

Disse er de billigste spørgsmål at stille, og de er *diskvalificerende*. Stil dem først. Det er
ærgerligt at kortlægge et system i en time for derefter at opdage at licensen forbyder det.

### Placering i systemporteføljen (TIME)

Se afsnit 4.

### Livscyklus og cost/benefit

- Hvor er applikationen i sin livscyklus?
- Giver det mening ift. cost/benefit? Et system der udfases om et år skal ikke migreres.

## 4. TIME-modellen, brugt korrekt

TIME (Gartner) placerer systemer efter **forretningsværdi** × **teknisk egnethed** — det er *ikke*
en modenhedsscore for containerisering. Brugt rigtigt er den mere nyttig, fordi den giver os et
eksplicit "lad være"-udfald:

```
                    høj forretningsværdi
                            │
            MIGRATE         │        INVEST
    værdifuld, men          │   værdifuld og i god
    forældet/dårligt        │   teknisk stand
    understøttet            │
    → containerisér         │   → hold ved lige,
      DENNE gruppe          │     migrér når det passer
  ──────────────────────────┼──────────────────────────  teknisk egnethed →
                            │
           ELIMINATE        │        TOLERATE
    lav værdi, dårlig       │   fungerer fint, lav værdi
    teknisk stand           │
    → NEDLÆG.               │   → lad stå.
      Containerisér ikke    │     Migrér kun hvis det er
      et system der skal    │     billigt at tage med
      dø                    │
                            │
                    lav forretningsværdi
```

**Det vigtigste udfald i hele dokumentet:** systemer i `Eliminate` skal **ikke** migreres. De skal
nedlægges. En migrationsproces uden et "lad være"-udfald bliver en maskine der flytter teknisk gæld
fra én platform til en anden.

`Migrate`-kvadranten er præcis vores kandidatgruppe: systemer med reel værdi, som er forældede eller
dårligt understøttet på nuværende platform.

## 5. Kriterier for prioritering — *i hvilken rækkefølge?*

| Kriterium | Hvorfor |
|---|---|
| **Kompleksitet** | Tag den lavest hængende frugt først, for at opbygge erfaring |
| **Udgivelsesfrekvens** | Tag de systemer der oftest ændrer sig og skal deployes — de får mest ud af pipelinen |
| **Driftsbyrde** | Tag det som volder os flest problemer at drifte |
| **Skalerbarhed** | Tag det som ville have størst gavn af at køre i Kubernetes |
| **Sårbarhed** | Tag det som er særligt sårbart og vigtigst for forretningen |
| **Teamets egen prioritering** | Teamet skal selv kunne prioritere ift. kompetencer, erfaring og tid |

De to første trækker i modsat retning af de to sidste, og det er med vilje. De første systemer skal
vælges for at **bygge erfaring** — ikke for at løse det mest presserende problem. Det mest sårbare og
forretningskritiske system er ikke det første man skal øve sig på.

## 6. Processen, trin for trin

| # | Trin | Ansvar | Resultat |
|---|---|---|---|
| 1 | **Udvælg system** ud fra kriterierne | Dev-team | nominering + kortlægning |
| 2 | **Containerisér komponenter** | Dev-team | en Dockerfile per komponent, i et registry |
| 3 | **`compose.yml` til lokal udvikling** | Dev-team | hele stakken kører på en laptop |
| 4 | **Manuel opsætning i Kubernetes via Rancher** *(anbefalet)* | Dev-team | fungerende manifests |
| 5 | **Konvertér til Helm chart** | Dev-team **+** Platform-team | et linted, testet chart |
| 6 | **GitOps-deployment og CI/CD** | Platform-team | ArgoCD-app + pipeline |
| — | **Cloud-readiness-oprydning** | Dev-team, *parallelt med 2–5* | se afsnit 7 |

### Hvorfor trin 4, når manifests alligevel bliver erstattet af et chart?

Fordi det adskiller to spørgsmål der ellers skal fejlsøges samtidig:

1. *Kan applikationen overhovedet køre i Kubernetes?*
2. *Er mit chart korrekt?*

Får man begge fejl på én gang, er de svære at skille. Og de fungerende manifests er præcis det man
templater chartet ud fra 

⭐ Det er nemmere at gøre kørende YAML manifester konfigurerbar end at skrive et chart i blinde.

⭐ Rancher gør det nemt for udviklere **visuelt** og uden omfattende YAML forståelse at opsætte et system i Kubernetes.

For det **første** system i et team er trinnet reelt obligatorisk. Har teamet allerede et chart de
kan kopiere fra, kan de gå direkte til trin 5.

### Workshop-rækken er trin 2–5

Det er værd at sige højt: **workshop #1, #2 og #3 er Dev-teamets halvdel af denne pipeline.**

| Trin | Workshop |
|---|---|
| 2 Containerisér | #1 Containerisation |
| 3 `compose.yml` | #1 Containerisation |
| 4 Manuelt i Kubernetes | #2 Kubernetes |
| 5 Helm chart | #3 Helm Charts |
| 6 GitOps + CI/CD | Platform-teamet |

Teams der har været igennem de tre workshops er altså trænet i deres egen del af processen. Det er
også derfor snitfladen ligger ved trin 5–6: chartet bygges sammen, og Platform-teamet tager over på
selve deploymentet.

## 7. Cloud-readiness som parallelt spor

**Det her er hvor tiden går.** At skrive en Dockerfile til en eksisterende applikation tager typisk
en dag eller to. At få konfigurationen ud af en properties-fil der er bagt ind i artefaktet, få logs
på stdout, få sessions ud af hukommelsen og gøre applikationen skalerbar — det er uger til måneder,
og det er **applikationsudvikling**, ikke DevOps-arbejde.

Derfor er cloud-readiness ikke et undertrin til containerisering. Det er et selvstændigt spor der
løber parallelt, og det skal **vurderes allerede ved udvælgelsen**, fordi det er den største enkelte
post i estimatet.

### De faktorer der batter mest i Kubernetes

Ud af 12-factor app'ens tolv principper er disse dem der giver konkrete problemer hvis de ignoreres:

| Faktor | Hvad der går galt i Kubernetes |
|---|---|
| **Config** (III) | Konfiguration skal komme fra miljøvariabler, ikke filer bagt ind i imaget. Ellers skal der bygges ét image per miljø. |
| **Logs** (XI) | Logs skal på stdout/stderr. Logs skrevet til disk i en container forsvinder med Pod'en. |
| **Processes** (VI) | Applikationen skal være stateless: ingen state på lokal disk, ingen sessions i hukommelsen. Ellers kan den hverken skaleres eller udrulles. |
| **Disposability** (IX) | Hurtig opstart og pæn håndtering af SIGTERM. Ellers taber hver udrulning requests. |
| **Backing services** (IV) | Afhængigheder findes via navn/URL fra konfiguration — ikke hardcodede hostnames. |
| **Dev/prod parity** (X) | Det er præcis hvad `compose.yml` i trin 3 giver os. |

### Det 12-factor ikke dækker

12-factor app er fra 2011 og er ældre end Kubernetes. Følgende står ikke i den, men er i praksis
**vigtigere** end flere af de tolv:

- **Health-endpoints** — `/healthz` (kører processen?) og `/readyz` (kan den tage trafik?). Uden dem
  kan Kubernetes ikke se forskel på "starter op" og "i stykker", og udrulninger bliver utrygge.
- **Readiness vs liveness** — readiness holder trafik væk til appen er klar; liveness genstarter en
  hængt container. Liveness bør *ikke* tjekke databasen, ellers genstarter et databaseudfald alle
  replicas på én gang.
- **Resource requests og limits** — hvad Pod'en må bruge, og hvad scheduleren garanterer den.
- **Hvor kommer secrets fra** — se nedenfor.

### Secrets

Credentials hører ikke i en values-fil. Values-filer bliver committet, diffet, klistret ind i sager
og sendt til sprogmodeller. Mulighederne, groft rangeret:

1. **External Secrets Operator** — chartet refererer en Secret; operatoren henter værdien fra
   Vault / Key Vault / AWS SM.
   - Oftest det rigtige svar.
   - Den nye platform kommer med HashiCorp Vault.
3. **Sealed Secrets / SOPS** — krypterede værdier, forsvarligt at committe.
4. **`existingSecret`** — chartet tager kun *navnet* på en Secret og templater aldrig værdien.
   Billigst at indføre, og bør altid tilbydes som udvej.

## 8. Pilot: BookCoverService

`Notalib/BookCoverService` er vores referencesystem, og det er valgt fordi det **allerede har været
hele pipelinen igennem** — det er ikke et forslag, det er noget der virker:

| Trin | I repoet |
|---|---|
| 2 Containerisering | 4 komponenter: CoverProxy, CoverService, NotaCoverServiceWebApp, UploadCoverWebApp |
| 3 Lokal udvikling | `compose.yml` + `compose.dev.override.yml` |
| 5 Helm chart | `ci/helm-chart/` — v1.11.12, 21 templates, 4 Deployments inkl. Redis |
| — Flere miljøer | `values_beta.yaml`, `values_live.yaml`, `values_ngt.yaml`, `values_kind.yaml` |
| 6 CI/CD | GitHub Actions, chart-versionen bumpes automatisk |

To detaljer der er værd at fremhæve:

**`values_kind.yaml`** — der findes en values-fil til et lokalt **kind**-cluster. Samme chart kører
altså i produktion, på beta, på ngt *og* på en udviklers laptop. Det er hele pointen med at pakke
systemet som et chart, demonstreret i praksis.

**Cloud-readiness-arbejdet er gjort konkret.** Systemet blev gjort væsentligt mere konfigurerbart som
del af migreringen:

- OAuth2-autentificering og krævede grupper er nu values
  (`Authentication__JwtBearer__Authority`, `ClientId`, `Audience`)
- ingen hardcodede forventninger til URL'er eller domæner for undersystemer og afhængigheder
- Ingress-hostnames er fuldt konfigurerbare

Det er præcis den slags arbejde afsnit 7 handler om, og det er grunden til at det samme chart kan
installeres i fire vidt forskellige miljøer.

> **En bevidst afvigelse fra "best practice":** i dette chart holdes `version` og `appVersion` i takt
> (begge `1.11.12`), hvilket normalt anbefales adskilt. For et chart der kun pakker én applikation er
> det en fornuftig husregel — det er værd at kende forskellen og så vælge.

## 9. Åbne spørgsmål

- **Snitfladen mellem TEK, Platforms-teamet og klassisk app-drift.** Trin 1–5 og trin 6 er aftalt,
  men den løbende drift efter go-live er ikke fuldt afklaret. Hvem er på vagt? Hvem opgraderer
  chartet ved en sikkerhedsopdatering?
- **Namespace-, quota- og RBAC-model per team** på den nye platform.
- **Afregning.** "Afregning per instans" står som udvælgelseskriterium, men vi har ikke en model for
  hvordan platformsforbrug fordeles.
- **Hvor mange systemer skal reelt igennem på 3 år**, og hvad er kadencen per team?

---

## Næste skridt

1. Kør workshop #3 (Helm Charts). Deltagerne kortlægger deres eget system som en del af workshoppen
   — det er trin 1 i denne proces.
2. Saml de blockers deltagerne skriver ned. De er input til den **detaljerede** cloud-readiness-guide
   og til emnet for workshop #4.
3. Skriv den detaljerede guide ud fra faktiske forhindringer i stedet for gæt.

**Workshop-materiale:** <https://github.com/notalib/workshop-helm-charts> — se især
`BEST-PRACTICES.md` (chart-konventioner) og `3-your-own-system/` (kortlægningen).
