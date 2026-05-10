const page = document.body.dataset.page || "";

const topnavHTML = `
<header class="topnav">
  <div class="topnav-inner">
    <a class="brand" href="index.html">
      <img src="logo.svg" alt="" />
      <span>sh<span class="ark">ARK</span>lib</span>
    </a>
    <div class="spacer"></div>
    <nav>
      <a href="index.html" data-nav="home">Home</a>
      <a href="guide.html" data-nav="guide">Guide</a>
      <a href="api.html" data-nav="api">API</a>
    </nav>
    <a class="gh" href="https://github.com/Marioispro1/shARKlib" target="_blank" rel="noopener" aria-label="GitHub">
      <svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 .5C5.65.5.5 5.65.5 12c0 5.08 3.29 9.39 7.86 10.91.58.1.79-.25.79-.56v-2c-3.2.7-3.87-1.36-3.87-1.36-.52-1.33-1.27-1.69-1.27-1.69-1.04-.71.08-.7.08-.7 1.15.08 1.76 1.18 1.76 1.18 1.02 1.76 2.69 1.25 3.34.96.1-.74.4-1.25.73-1.54-2.55-.29-5.24-1.27-5.24-5.66 0-1.25.45-2.27 1.18-3.07-.12-.29-.51-1.46.11-3.05 0 0 .96-.31 3.15 1.17.92-.26 1.9-.39 2.88-.39s1.96.13 2.88.39c2.19-1.48 3.15-1.17 3.15-1.17.62 1.59.23 2.76.11 3.05.73.8 1.18 1.82 1.18 3.07 0 4.4-2.7 5.36-5.27 5.65.41.36.78 1.06.78 2.13v3.16c0 .31.21.67.8.56C20.21 21.39 23.5 17.07 23.5 12 23.5 5.65 18.35.5 12 .5z"/></svg>
    </a>
  </div>
</header>`;

const footerHTML = `
<footer class="footer">
  Released under the MIT License · <a href="https://github.com/Marioispro1/shARKlib">github.com/Marioispro1/shARKlib</a>
</footer>`;

const apiSidebarHTML = `
<aside class="sidebar">
  <h4>Bootstrap</h4>
  <a href="api.html#api-SetTemplate">SetTemplate</a>
  <a href="api.html#api-Init">Init</a>

  <h4>Reactive core</h4>
  <a href="api.html#api-source">source</a>
  <a href="api.html#api-derive">derive</a>
  <a href="api.html#api-effect">effect</a>
  <a href="api.html#api-watch">watch</a>
  <a href="api.html#api-root">root</a>
  <a href="api.html#api-cleanup">cleanup</a>
  <a href="api.html#api-untrack">untrack</a>
  <a href="api.html#api-batch">batch</a>
  <a href="api.html#api-context">context</a>
  <a href="api.html#api-read">read</a>
  <a href="api.html#api-errorBoundary">errorBoundary</a>
  <a href="api.html#api-lazy">lazy</a>
  <a href="api.html#api-signal">signal</a>

  <h4>Instances</h4>
  <a href="api.html#api-create">create</a>
  <a href="api.html#api-apply">apply</a>
  <a href="api.html#api-mount">mount</a>
  <a href="api.html#api-Children">Children</a>
  <a href="api.html#api-action">action</a>
  <a href="api.html#api-changed">changed</a>
  <a href="api.html#api-portal">portal</a>
  <a href="api.html#api-tag">tag</a>
  <a href="api.html#api-smoothLayout">smoothLayout</a>
  <a href="api.html#api-onMount">onMount</a>
  <a href="api.html#api-onEvent">onEvent</a>
  <a href="api.html#api-ref">ref</a>
  <a href="api.html#api-keybind">keybind</a>
  <a href="api.html#api-hover">hover</a>
  <a href="api.html#api-pressed">pressed</a>
  <a href="api.html#api-drag">drag</a>
  <a href="api.html#api-screenSize">screenSize</a>
  <a href="api.html#api-fade">fade</a>

  <h4>Control flow</h4>
  <a href="api.html#api-show">show</a>
  <a href="api.html#api-switch">switch</a>
  <a href="api.html#api-match">match</a>
  <a href="api.html#api-indexes">indexes</a>
  <a href="api.html#api-values">values</a>

  <h4>Animation</h4>
  <a href="api.html#api-spring">spring</a>
  <a href="api.html#api-tween">tween</a>

  <h4>Data</h4>
  <a href="api.html#api-resource">resource</a>
  <a href="api.html#api-store">store</a>
  <a href="api.html#api-selector">selector</a>
  <a href="api.html#api-debounce">debounce</a>
  <a href="api.html#api-throttle">throttle</a>
  <a href="api.html#api-combine">combine</a>
  <a href="api.html#api-mapList">mapList</a>

  <h4>Tooling</h4>
  <a href="api.html#api-scheduler">scheduler</a>
</aside>`;

const topMount = document.getElementById("topnav-mount");
if (topMount) topMount.outerHTML = topnavHTML;

const sideMount = document.getElementById("sidebar-mount");
if (sideMount) sideMount.outerHTML = apiSidebarHTML;

const footMount = document.getElementById("footer-mount");
if (footMount) footMount.outerHTML = footerHTML;

document.querySelectorAll(".topnav nav a").forEach((a) => {
  if (a.dataset.nav === page) a.classList.add("active");
});

const sideLinks = document.querySelectorAll("aside.sidebar a");

function currentKey() {
  let file = location.pathname.split("/").pop();
  if (!file) file = "index.html";
  return file + location.hash;
}

function updateActive() {
  const here = currentKey();
  sideLinks.forEach((a) => {
    a.classList.toggle("active", (a.getAttribute("href") || "") === here);
  });
}

function setActive(target) {
  sideLinks.forEach((a) => a.classList.toggle("active", a === target));
}

sideLinks.forEach((a) => {
  a.addEventListener("click", () => setActive(a));
});

updateActive();
window.addEventListener("hashchange", updateActive);
window.addEventListener("popstate", updateActive);

if (window.hljs) hljs.highlightAll();

