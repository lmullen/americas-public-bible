import BibleBorrowings from './bible-borrowings';
import Alert from '../common/alert';

const id = '#bible-borrowings';
const viz = new BibleBorrowings(id);
const checker = viz.render();

checker.then((status) => {
  if (status === 'failed') {
    const msg = new Alert(id, 'alert', 'Sorry, we have a problem on our end.');
    msg.render();
  }
});
