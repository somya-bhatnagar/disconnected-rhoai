(function () {
  var KEY = "disconnected-rhoai-theme";

  function current() {
    return document.documentElement.getAttribute("data-theme") === "light" ? "light" : "dark";
  }

  function label(theme) {
    return theme === "light" ? "Dark mode" : "Light mode";
  }

  function apply(theme) {
    document.documentElement.setAttribute("data-theme", theme);
    try { localStorage.setItem(KEY, theme); } catch (e) {}
    var btn = document.getElementById("theme-toggle");
    if (btn) {
      btn.setAttribute("aria-pressed", theme === "light" ? "true" : "false");
      btn.textContent = label(theme);
    }
  }

  window.toggleDisconnectedTheme = function () {
    apply(current() === "light" ? "dark" : "light");
  };

  document.addEventListener("DOMContentLoaded", function () {
    apply(current());
    var btn = document.getElementById("theme-toggle");
    if (btn) btn.addEventListener("click", window.toggleDisconnectedTheme);
  });
})();
