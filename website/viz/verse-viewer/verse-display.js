import * as d3 from 'd3';
import config from '../config';

export default class VerseDisplayer {
  constructor(id, verse) {
    this.node = d3.select(id);
    this.data = null;
    this.status = 'loading';
    const v = encodeURIComponent(verse);
    this.url = `${config.API_BASE}/apb/verse?ref=${v}`;
  }

  async fetch() {
    try {
      this.data = await d3.json(this.url);
      this.status = 'ok';
    } catch (e) {
      if (e.message === '404 Not Found') {
        this.status = 'missing';
      } else {
        console.log(e);
        this.status = 'failed';
      }
    }
  }

  async render() {
    await this.fetch();
    if (this.status !== 'ok') return this.status;
    this.node
      .append('p')
      .html(`<strong>${this.data.reference}</strong>—${this.data.text}`);
    if (this.data.related.length > 0) {
      const rel = this.data.related.join(', ');
      this.node.append('p').html(`Related verses: ${rel}.`);
    }
    return this.status;
  }
}
