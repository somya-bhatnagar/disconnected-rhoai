# Disconnected Environment — RHOAI

Slide decks and notes for **Models as a Service (MaaS)** validation on disconnected OpenShift AI clusters.

## Live decks

| Release | Deck |
| --- | --- |
| Home | [https://somya-bhatnagar.github.io/disconnected-rhoai/](https://somya-bhatnagar.github.io/disconnected-rhoai/) |
| RHOAI 3.4 | [https://somya-bhatnagar.github.io/disconnected-rhoai/3.4.html](https://somya-bhatnagar.github.io/disconnected-rhoai/3.4.html) |
| RHOAI 3.5 GA | [https://somya-bhatnagar.github.io/disconnected-rhoai/3.5.html](https://somya-bhatnagar.github.io/disconnected-rhoai/3.5.html) |
| RHOAI 3.6 GA | [https://somya-bhatnagar.github.io/disconnected-rhoai/3.6.html](https://somya-bhatnagar.github.io/disconnected-rhoai/3.6.html) |

Use **arrow keys**, **space**, or the footer to move through slides. Switch versions from **Home · 3.4 · 3.5 · 3.6** in the footer. Light/dark mode: `theme.js`.

GitHub Pages serves static HTML only (`.nojekyll` disables Jekyll).

## What’s in each deck

**3.4** — Cluster context, eight disconnected workarounds (proxy route, WasmPlugin pull secret, Authorino TLS, NetworkPolicy, PostgreSQL image, endpoint override, HTTPRoute rewrite, custom HTTP server), readiness and smoke tests, component status.

**3.5** — Modularization (RHOAI operator → ai-gateway-operator → maas-controller, ExternalModel instead of KServe), install via FBC + DSC, **seven** workarounds, what **dropped from 3.4**, readiness / smoke / **AITenant multitenancy** (15 checks), troubleshooting.

**3.6** — GA validation on **`maas-dis-aws-36`** (OCP 4.22.20, RHOAI 3.6.0, RHCL 1.5.0). Same seven disconnected workarounds as 3.5; **3.5 → 3.6 delta** (nothing removed—workaround **6** uses Service **443→8000** + DestinationRule TLS **DISABLE** when the operator keeps HTTPRoute on `provider-*:443`). The **3.4 WasmPlugin pull-secret workaround is not required** (gateway uses `WASM_INSECURE_REGISTRIES`; Jenkins **`configure-disconnected-rhcl.sh`** may still create `wasm-plugin-pull-secret` in `openshift-ingress`). Readiness 8/8, smoke 5/5, AITenant multitenancy (same 15-check matrix as 3.5), Praxis default + tenant, session outcome and troubleshooting.

## 3.6 validation (reference cluster)

| Item | Value |
| --- | --- |
| Cluster | `maas-dis-aws-36` |
| FBC | `quay.io/rhoai/rhoai-fbc-fragment@sha256:4d71a830f36f9bfeed7daa84d8e57bbba3d9f82850106d071e49e5a59e9b0e68` |
| Catalog | `rhoai-catalog-base` |

Detailed results, tenant model wiring for multitenancy keys (MT9–11), and out-of-scope items: **`3.6-validation-checklist.md`**.

Re-run automated checks after `oc login`:

```bash
./scripts/validate-36-ga.sh
```

Covers workarounds W1–7, readiness R1–8, smoke T9–13, multitenancy MT9–11, and Praxis deploy checks (see script for full pass count).

## Local preview

```bash
python3 -m http.server 8765
```

Open [http://127.0.0.1:8765/](http://127.0.0.1:8765/) for the home page, or `3.4.html`, `3.5.html`, or `3.6.html`.

## Files

| File | Purpose |
| --- | --- |
| `index.html` | Home — links to 3.4 / 3.5 / 3.6 |
| `3.4.html`, `3.5.html`, `3.6.html` | Validation slide decks |
| `theme.js` | Light/dark toggle |
| `.nojekyll` | Required for GitHub Pages static deploy |
| `3.6-validation-checklist.md` | 3.6 GA cluster sign-off notes (not on Pages) |
| `scripts/validate-36-ga.sh` | Repeatable `oc` + curl validation for 3.6 GA |
