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
      bottom: 20,
      left: 40,
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
    return this.data
      .filter((d) => d.corpus === 'chronam')
      .filter((d) => d.year <= 1926);
  }

  async render() {
    await this.fetch();

    if (this.status !== 'ok') {
      this.node.remove();
      return this.status;
    }

    console.log(this.currentData());

    const data = this.currentData();

    this.xScale = d3
      .scaleLinear()
      .domain(d3.extent(data, (d) => d.year))
      .range([0, this.width]);

    this.xAxis = d3.axisBottom().scale(this.xScale).tickFormat(d3.format('d'));

    this.yScale = d3
      .scaleLinear()
      .domain([0, d3.max(data, (d) => d.q_per_word_e6 * 1e6)])
      .range([this.height, 0])
      .nice();

    this.yAxis = d3.axisLeft().scale(this.yScale);

    this.viz
      .append('g')
      .attr('class', 'x axis')
      .attr('transform', `translate(0,${this.height})`)
      .call(this.xAxis);

    this.viz
      .append('g')
      .attr('class', 'y axis')
      .attr('transform', 'translate(0,0)')
      .call(this.yAxis);

    const line = d3
      .line()
      .defined((d) => !Number.isNaN(d.q_per_word_e6))
      .curve(d3.curveBasis)
      .x((d) => this.xScale(d.year))
      .y((d, i) => {
        return this.yScale(d.q_per_word_e6 * 1e6);
      });

    this.viz.append('path').datum(data).classed('line', true).attr('d', line);

    return this.status;
  }
}
