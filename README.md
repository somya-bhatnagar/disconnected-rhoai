# Disconnected Environment — RHOAI

Slide decks for **Models as a Service (MaaS)** testing on a disconnected OpenShift AI cluster.

## Live decks

| Release | Deck |
| --- | --- |
| Home | [https://somya-bhatnagar.github.io/disconnected-rhoai/](https://somya-bhatnagar.github.io/disconnected-rhoai/) |
| RHOAI 3.4 | [https://somya-bhatnagar.github.io/disconnected-rhoai/3.4.html](https://somya-bhatnagar.github.io/disconnected-rhoai/3.4.html) |
| RHOAI 3.5 GA | [https://somya-bhatnagar.github.io/disconnected-rhoai/3.5.html](https://somya-bhatnagar.github.io/disconnected-rhoai/3.5.html) |
| RHOAI 3.6 GA | [https://somya-bhatnagar.github.io/disconnected-rhoai/3.6.html](https://somya-bhatnagar.github.io/disconnected-rhoai/3.6.html) |

Use **arrow keys**, **space**, or the footer buttons to move through slides. Switch versions from the **3.4 / 3.5 / 3.6** links in the footer.

## What’s in each deck

**3.4** — cluster context, eight disconnected workarounds (proxy route, WasmPlugin pull secret, Authorino TLS, NetworkPolicy, PostgreSQL image, endpoint override, HTTPRoute rewrite, custom HTTP server), readiness and smoke tests, component status.

**3.5** — modularization (no KServe: RHOAI operator → ai-gateway-operator → maas-controller), install via FBC + DSC, seven workarounds, what dropped from 3.4, readiness / smoke / AITenant multitenancy, troubleshooting.

**3.6** — GA FBC fragment on OCP 4.22.20, RHCL 1.5, enable MaaS on DSC, disconnected workarounds (including 3.6 stub Service port 443→8000), core smoke validation on `maas-dis-aws-36`.

## Local preview

```bash
python3 -m http.server 8765
```

Then open [http://127.0.0.1:8765/](http://127.0.0.1:8765/) for the home page, or `3.4.html`, `3.5.html`, or `3.6.html`.

## Files

- `index.html` — home page
- `3.4.html` — RHOAI 3.4 deck
- `3.5.html` — RHOAI 3.5 GA deck
- `3.6.html` — RHOAI 3.6 GA deck
- `3.6-validation-checklist.md` — cluster validation notes (not published to Pages)
