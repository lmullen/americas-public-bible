import * as d3 from 'd3';
import Visualization from '../common/visualization';
import config from '../config';

export default class VerseTrend extends Visualization {
  constructor(id, verse) {
    const dim = {
      width: 1200,
      height: 600,
    };
    const margin = {
      top: 10,
      right: 10,
      bottom: 10,
      left: 10,
    };

    super(id, dim, margin);

    const v = encodeURIComponent(verse);
    this.url = `${config.API_BASE}/apb/verse-trend?ref=${v}`;
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

  currentData() {
    return this.data.filter((d) => d.corpus === 'chronam');
  }

  async render() {
    await this.fetch();

    if (this.status !== 'ok') {
      this.node.remove();
      return this.status;
    }

    return this.status;
  }
}
