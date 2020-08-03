import BibleTrend from './bible-trend';
import Alert from '../common/alert';

const id = '#bible-trend';
const trend = new BibleTrend(id);
const checker = trend.render();

checker.then((status) => {
  if (status === 'failed') {
    const msg = new Alert(id, 'alert', 'Sorry, we have a problem on our end.');
    msg.render();
  }
});
