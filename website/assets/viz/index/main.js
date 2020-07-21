import * as d3 from 'd3';
import config from '../config';

class IndexItem {
  constructor(id, reference, text) {
    this.node = d3.select(id).append('div');
    this.reference = reference;
    this.text = text;

    const r = encodeURIComponent(reference);
    this.link = `/visualization/verse-viewer?ref=${r}`;
  }

  render() {
    this.node
      .append('p')
      .html(
        `<strong><a href="${this.link}">${this.reference}</a></strong>&mdash;${this.text}`
      );
  }
}

const dataPromise = d3.json(`${config.API_BASE}/apb/index/featured/`);

dataPromise
  .then((data) => {
    data.forEach((d) => {
      const item = new IndexItem('#featured', d.reference, d.text);
      item.render();
    });
  })
  .catch((e) => console.log(e));
