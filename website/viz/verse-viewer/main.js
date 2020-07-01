import VerseDisplayer from './verse-display';
import Alert from '../common/alert';

const p = new URLSearchParams(window.location.search);
const ref = p.get('ref');

const verse = new VerseDisplayer('#verse', ref);
const checker = verse.render();

checker.then((status) => {
  if (status === 'missing') {
    const msg = new Alert(
      '#verse',
      'warning',
      'Sorry, that is not a valid verse.'
    );
    msg.render();
  } else if (status === 'failed') {
    const msg = new Alert(
      '#verse',
      'alert',
      'Sorry, we have a problem on our end.'
    );
    msg.render();
  }
});
