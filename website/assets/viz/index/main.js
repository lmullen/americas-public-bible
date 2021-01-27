import * as d3 from 'd3';
import IndexItem from '../common/index-item';
import config from '../config';

const featuredPromise = d3.json(`${config.API_BASE}/apb/index/featured/`);

featuredPromise
  .then((data) => {
    data.forEach((d) => {
      const item = new IndexItem('#featured-verses', d.reference, d.text);
      item.render();
    });
  })
  .catch((e) => console.log(e));
