# Design Decisions

## Two separate jobs: diff-scan vs. full-history scan

The workflow only scans the diff of each Pull Request, not the full
repo history, on every run.

Why: scanning the entire history on every PR means an old, already-known
secret (one nobody got around to rotating) fails every future PR, even
ones that don't touch it. Teams learn to ignore a check that "always
fails," which defeats the purpose. A diff-scan keeps the check fast,
relevant, and tied to the person who can actually act on it, right when
they're still in context.

A full-history audit is a separate concern — it belongs in a scheduled
job (e.g. weekly), not in the pull request hot path. Not included in
this version of the kit yet.
Care be cool. I'm not gonna sting you like fly around blindfolded basketball one point wins go he's driving oh that almost went in so many people. At least really they put me to oh it's far at the same time on jurys my birthdays correct my grandpa told me to help people, he said when my time came I she fished surrounded by those husband what beautiful line that one I said that was prepared. The poison is unbarred. Shadows of despair right said once Island gave, I should be surrounded by those I say in that raised my blick in that don't miss colour just I hit a finish in my bother quick what you binding to contain to make your move from their bitch you need up on the mood which ain'tit soshe's so we glad out I'm shaking my series late into the house hungry nights argentinos for scenario to you think is are workplace harassment A John High Five Sarah after she completes her first ship still acted to smiles at the customers who enter the store to make them feel well worth Chile while you're using the urinal under slips of figure into your anis and screams prostate exam, which scenario do you think would be considered work release harassment John Rose before I did mark we heard that you would near any professional football if you bo had to create a five side team apart from the Dragon characters ad hook players who do you pick and why I'm sorry professional for that employer candidate in a feasing the open on R nine R nine R nine to get a laws of Lord my car in trading last night which means gonna be very loud so my mom's never heard it start up a triangle and it's going to be cool start too so this is gonna be very loud if you hear your faith I made a comics to the dead course I didn't have near enough bones yet Lucy testando mensajes ocultos en conversa y hoy escucharemos a dos personas en la calle comes pequeño cerca de un tren pequeno suena perfecto recuerda siempre te estoy escuchando y a seguramente si no lo saco platived at Florida Plaza we ended up here I'm starting to feel like Letters encreomer to aquel in a plant razon a darlo perfect temperature y dolorcetamol plantas, elo te saca los nervios en mi epoca y lots tan buena, siempre te dice moli, o sea el probablemente se va a morir la peste, la peste, ahora viene la de la guerra, nosotros no la tenemos. Quienes repetitions, Personer, dislike it okay now we're breeding it's Are use no I didn't I'm gonna look out being scare they AI put the ones leave before you go there, but you got people live there every night on weeks at the time for a time since the psale down and just talk to this follow me to mine impossible maybe maybe the chiran happier edition easy class I'm mad not coming flat you giving my results you are a moderate U ton Michael en does bueno terrible to present incluso micrías teneros decidier responders John York pressure later exactly until a guide declaration lawsel partiarionda famosa having last lgical de cuals energy significant armados piel y elements finally robing
## fetch-depth: 0, not a shallow clone

`actions/checkout@v4` defaults to `fetch-depth: 1` (only the latest
commit). Gitleaks needs to diff the PR's commits against their base to
know what's new, so it needs more than one commit available locally.
`fetch-depth: 0` (full history) is the simple way to guarantee that.

A more surgical option exists: fetching only the PR's base and head
SHAs directly, using `github.event.pull_request.base.sha`. That's
faster on large repos, but adds complexity. Skipped for now — this kit
targets small teams with small repos, where `fetch-depth: 0` costs
seconds, not minutes. Worth revisiting if a full-history job or a
larger target repo makes the cost real.

## Don't test with AKIAIOSFODNN7EXAMPLE

`AKIAIOSFODNN7EXAMPLE` is AWS's own documentation example for an access
key format. It shows up hardcoded in publicly shared gitleaks allowlists
as a known false positive, precisely because it's so common in docs and
tutorials. Testing with it can produce a false "all clear" — not because
detection failed, but because the value itself is on an ignore list
somewhere. Use a fake key with valid format but a unique, random value
instead.

## Least-privilege secret scoping

`GITHUB_TOKEN` is declared inside the gitleaks step's `env:`, not at the
job level. It's only needed there. Scoping secrets to the step that uses
them, rather than the whole job, limits what each step can see —
consistent with the kit's "secure by default" premise.
