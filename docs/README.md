# shARKlib documentation

This folder contains the static documentation site published to GitHub Pages.

## Local preview

Just open `docs/index.html` in a browser. (For best results, serve the folder over HTTP, e.g.:)

```bash
npx http-server docs
# or
python -m http.server -d docs 8080
```

## Publishing on GitHub Pages

1. Push this repo to GitHub.
2. In the repo's settings, go to **Pages**.
3. Under "Build and deployment", set **Source** = `Deploy from a branch`.
4. Select the branch (e.g. `main`) and **folder = `/docs`**.
5. Save. The site will be live at `https://<user>.github.io/<repo>/`.

## Files

- `index.html` — landing page (intro, install, quick start, concepts).
- `api.html`   — full API reference.
- `style.css`  — shared theme.
- `_sidebar.js` — shared sidebar markup (injected into `<div id="sidebar-mount"></div>`).
