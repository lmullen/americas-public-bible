import SimpleVerseTrend from './simple-trend';

// const p = new URLSearchParams(window.location.search);
// const ref = p.get('ref');

const ref = document.querySelector('#trend-preview').dataset.reference;
const trend = new SimpleVerseTrend('#trend-preview', ref);
trend.render();
