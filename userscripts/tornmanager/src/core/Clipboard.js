export function copyText(text, toastMessage = "Copied to clipboard") {
  const done = () => showToast(toastMessage);

  const fallback = () => {
    const ta = document.createElement("textarea");
    ta.value = text;
    ta.style.position = "fixed";
    ta.style.opacity = "0";
    document.body.appendChild(ta);
    ta.select();
    document.execCommand("copy");
    document.body.removeChild(ta);
    done();
  };

  if (navigator.clipboard?.writeText) {
    navigator.clipboard.writeText(text).then(done).catch(fallback);
  } else {
    fallback();
  }
}

export function showToast(text) {
  const toast = document.createElement("div");
  toast.className = "tm-toast";
  toast.textContent = text;
  document.body.appendChild(toast);

  requestAnimationFrame(() => toast.classList.add("tm-toast--visible"));
  setTimeout(() => {
    toast.classList.remove("tm-toast--visible");
    setTimeout(() => toast.remove(), 300);
  }, 1600);
}
