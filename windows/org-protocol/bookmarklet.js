(() => {
  const params = new URLSearchParams({
    template: "w",
    url: location.href,
    title: document.title,
    body: String(window.getSelection() || ""),
  });
  location.href = `org-protocol://capture?${params.toString()}`;
})();
