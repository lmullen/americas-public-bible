import * as d3 from 'd3';
import config from '../config';

export default class VerseDisplayer {
  constructor(id, verse) {
    this.el = d3.select(id);
    const v = encodeURIComponent(verse);
    this.url = `${config.API_BASE}/apb/verse?ref=${v}`;
  }

  async fetch() {
    try {
      this.data = await d3.json(this.url);
    } catch (e) {
      console.log(e);
      this.data = null;
    }
  }

  async render() {
    await this.fetch();
    if (this.data === null) return;
    this.el
      .append('p')
      .html(`<strong>${this.data.reference}</strong>—${this.data.text}`);
    if (this.data.related.length > 0) {
      const rel = this.data.related.join(', ');
      this.el.append('p').html(`Related verses: ${rel}`);
    }
  }
}
