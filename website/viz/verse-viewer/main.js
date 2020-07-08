import VerseDisplayer from './verse-display';
import Alert from '../common/alert';
import VerseQuotations from './verse-quotations';
import './style.css';
import VerseTrend from './verse-trend';

const p = new URLSearchParams(window.location.search);
const ref = p.get('ref');

const verse = new VerseDisplayer('#verse', ref);
const checker = verse.render();

checker.then((status) => {
  if (status === 'missing') {
    const msg = new Alert(
      'main',
      'warning',
      'Sorry, that is not a valid verse.'
    );
    msg.render();
  } else if (status === 'failed') {
    const msg = new Alert(
      'main',
      'alert',
      'Sorry, we have a problem on our end.'
    );
    msg.render();
  } else {
    const trend = new VerseTrend(
      '#trend',
      ref,
      'Rate of quotations, 1836&ndash;1922'
    );
    trend.render();
    const quotations = new VerseQuotations('#quotations', ref, verse.data.text);
    quotations.render();
  }
});
