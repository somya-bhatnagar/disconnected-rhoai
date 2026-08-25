# Disconnected Environment — RHOAI

Slide decks for **Models as a Service (MaaS)** testing on a disconnected OpenShift AI cluster.

By [Somya Bhatnagar](https://github.com/somya-bhatnagar) · tracked in [RHOAIENG-38241](https://issues.redhat.com/browse/RHOAIENG-38241)

## Live decks

| Release | Deck |
| --- | --- |
| RHOAI 3.4 | [https://somya-bhatnagar.github.io/disconnected-rhoai/](https://somya-bhatnagar.github.io/disconnected-rhoai/) |
| RHOAI 3.5 GA | [https://somya-bhatnagar.github.io/disconnected-rhoai/3.5.html](https://somya-bhatnagar.github.io/disconnected-rhoai/3.5.html) |

Use **arrow keys**, **space**, or the footer buttons to move through slides. Switch versions from the **3.4 / 3.5** links in the footer.

## What’s in each deck

**3.4** — cluster context, eight disconnected workarounds (proxy route, WasmPlugin pull secret, Authorino TLS, NetworkPolicy, PostgreSQL image, endpoint override, HTTPRoute rewrite, custom HTTP server), readiness and smoke tests, component status.

**3.5** — modularization (no KServe: RHOAI operator → ai-gateway-operator → maas-controller), install via FBC + DSC, seven workarounds, what dropped from 3.4, readiness / smoke / AITenant multitenancy, troubleshooting.

## Local preview

```bash
python3 -m http.server 8765
```

Then open [http://127.0.0.1:8765/](http://127.0.0.1:8765/) for 3.4 or [http://127.0.0.1:8765/3.5.html](http://127.0.0.1:8765/3.5.html) for 3.5.

## Files

- `index.html` — RHOAI 3.4 deck
- `3.5.html` — RHOAI 3.5 GA deck
