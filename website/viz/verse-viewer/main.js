// import * as d3 from 'd3';
import VerseDisplayer from './verse-display';

const p = new URLSearchParams(window.location.search);
const ref = p.get('ref');

const verse = new VerseDisplayer('#verse', ref);
verse.render();
