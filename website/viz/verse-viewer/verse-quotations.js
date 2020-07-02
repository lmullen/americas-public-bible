import * as d3 from 'd3';
import config from '../config';
import { year, day } from '../common/dates';

export default class VerseQuotations {
  constructor(id, verse) {
    this.node = d3.select(id);
    this.data = null;
    this.status = 'loading';
    const v = encodeURIComponent(verse);
    this.url = `${config.API_BASE}/apb/verse-quotations?ref=${v}`;
  }

  async fetch() {
    try {
      this.data = await d3.json(this.url);
      this.status = 'ok';
    } catch (e) {
      if (e.message === '404 Not Found') {
        console.log(e);
        this.status = 'missing';
      } else {
        console.log(e);
        this.status = 'failed';
      }
    }
  }

  async render() {
    await this.fetch();

    if (this.status !== 'ok') {
      this.node.remove();
      return this.status;
    }

    const t = this.node.append('table').classed('hover', true);

    t.append('thead').html(
      '<tr><th>Year</th><th>Date</th><th>Newspaper</th><th>Version</th><th>Probability</th></tr>'
    );

    // Here this.table is actually the <tbody> node
    this.table = t.append('tbody');

    this.table
      .selectAll('tr')
      .data(this.data, (d) => d.document)
      .enter()
      .append('tr')
      .html(
        (d) =>
          `<td>${year(d.date)}</td><td>${day(d.date)}</td><td>${
            d.title
          }</td><td>${d.version}</td><td>${d.probability}</td>`
      );

    return this.status;
  }
}
