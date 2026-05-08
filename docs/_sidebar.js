// Shared sidebar so we don't repeat 100 links per page.
// Inserted into <div id="sidebar-mount"></div> on every page.
const sidebarHTML = `
<aside class="sidebar">
  <a class="brand-row" href="index.html">
    <img src="logo.svg" alt="" width="60" height="40" />
    <div>
      <div class="brand">sh<span class="ark">ARK</span><span class="lib">lib</span></div>
      <div class="tagline">reactive UI for Roblox</div>
    </div>
  </a>

  <h4>Getting started</h4>
  <a href="index.html#intro">Introduction</a>
  <a href="index.html#install">Installation</a>
  <a href="index.html#quickstart">Quick start</a>
  <a href="index.html#concepts">Concepts</a>

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

document.getElementById("sidebar-mount").outerHTML = sidebarHTML;

const links = document.querySelectorAll("aside.sidebar a");

function currentKey() {
  let file = location.pathname.split("/").pop();
  if (!file) file = "index.html";
  return file + location.hash;
}

function updateActive() {
  const here = currentKey();
  const fileOnly = here.split("#")[0];
  links.forEach((a) => {
    const href = a.getAttribute("href") || "";
    a.classList.toggle("active", href === here || (href === fileOnly && !location.hash));
  });
}

function setActive(target) {
  links.forEach((a) => a.classList.toggle("active", a === target));
}

links.forEach((a) => {
  a.addEventListener("click", () => setActive(a));
});

updateActive();
window.addEventListener("hashchange", updateActive);
window.addEventListener("popstate", updateActive);

if (window.hljs) hljs.highlightAll();
