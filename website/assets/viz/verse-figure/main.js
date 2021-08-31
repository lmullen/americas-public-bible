import VerseTrend from '../verse-viewer/verse-trend';

const ref = document.currentScript.getAttribute('data-ref');
const id = document.currentScript.getAttribute('data-id');

const trend = new VerseTrend(
  `#${id}`,
  ref,
  `Rate of quotations to ${ref}, 1836&ndash;1922`,
  false
);
trend.render();
