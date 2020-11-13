import * as d3 from 'd3';
import IndexItem from '../common/index-item';
import config from '../config';

const topPromise = d3.json(`${config.API_BASE}/apb/index/top/`);

topPromise
  .then((data) => {
    data.forEach((d) => {
      const item = new IndexItem('#most-quoted', d.reference, d.text);
      item.render();
    });
  })
  .catch((e) => console.log(e));
