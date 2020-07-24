import * as d3 from 'd3';
import config from '../config';

class IndexItem {
  constructor(id, reference, text) {
    this.node = d3.select(id).append('div');
    this.reference = reference;
    this.text = text;

    const r = encodeURIComponent(reference);
    this.link = `/verse-viewer?ref=${r}`;
  }

  render() {
    this.node
      .append('p')
      .html(
        `<strong><a href="${this.link}">${this.reference}</a></strong>&mdash;${this.text}`
      );
  }
}

const featuredPromise = d3.json(`${config.API_BASE}/apb/index/featured/`);

featuredPromise
  .then((data) => {
    data.forEach((d) => {
      const item = new IndexItem('#featured', d.reference, d.text);
      item.render();
    });
  })
  .catch((e) => console.log(e));

// const topPromise = d3.json(`${config.API_BASE}/apb/index/top/`);

// topPromise
//   .then((data) => {
//     data.forEach((d) => {
//       const item = new IndexItem('#top', d.reference, d.text);
//       item.render();
//     });
//   })
//   .catch((e) => console.log(e));
