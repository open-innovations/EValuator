const getUrl = () => new URL(window.location);

export const saveAppState = (update) => {
  const currentPage = getUrl();
  Object.entries(update).forEach(([k, v]) => {
    if (v !== null && v !== undefined) {
      currentPage.searchParams.set(k, v)
    } else {
      currentPage.searchParams.delete(k);
    }
  });
  window.history.replaceState(null, null, currentPage.href);
}

export const loadAppState = (keys) => {
  const currentPage = getUrl();
  return keys.reduce((result, k) => {
    if (currentPage.searchParams.has(k)) {
      result[k] = currentPage.searchParams.get(k);
    };
    return result;
  }, {});
}