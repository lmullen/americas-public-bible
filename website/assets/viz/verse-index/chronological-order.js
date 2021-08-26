import * as d3 from 'd3';
import IndexItem from '../common/index-item';
import config from '../config';

const topPromise = d3.json(`${config.API_BASE}/apb/index/peaks`);

topPromise
  .then((data) => {
    console.log(data);
    data.forEach((d) => {
      const item = new IndexItem(
        '#chronological-order',
        d.reference,
        d.text,
        d.count,
        d.peak
      );
      item.render();
    });
  })
  .catch((e) => console.log(e));
