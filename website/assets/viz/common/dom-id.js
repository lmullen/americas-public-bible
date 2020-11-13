export default function domID(prefix, reference) {
  const r = reference.replace(/\s+/g, '-').replace(/:/g, '-').toLowerCase();
  return `${prefix}-${r}`;
}
