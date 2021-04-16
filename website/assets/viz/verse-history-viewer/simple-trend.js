import * as d3 from 'd3';
// import { maxIndex } from 'd3-array';
import Visualization from '../common/visualization';
// import { commaFormat, decimal1Format } from '../common/display';
import config from '../config';

export default class SimpleVerseTrend extends Visualization {
  constructor(id, ref) {
    const dim = {
      width: 1000,
      height: 250,
    };
    const margin = {
      top: 10,
      right: 10,
      bottom: 20,
      left: 10,
    };
    // Replace `null` to put a title on the visualzation
    super(id, dim, margin, null);
    const v = encodeURIComponent(ref);
    this.url = `${config.API_BASE}/apb/verse-trend?ref=${v}&corpus=chronam`;
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
    return this.status;
  }

  async render() {
    await this.fetch();
    const data = this.data.trend;

    // Axes and scales
    this.xScale = d3
      .scaleLinear()
      .domain(d3.extent(data, (d) => d.year))
      .range([0, this.width]);
    this.xAxis = d3
      .axisBottom()
      .scale(this.xScale)
      .tickFormat(d3.format('d'))
      .ticks(10);
    const max = d3.max(data, (d) => d.smoothed);
    this.yScale = d3
      .scaleLinear()
      .domain([0, max * config.MILLIONS])
      .range([this.height, 0])
      .nice();
    this.svg
      .append('g')
      .attr('class', 'x axis')
      .attr(
        'transform',
        `translate(${this.margin.left},${this.margin.top + this.height})`
      )
      .call(this.xAxis);

    const line = d3
      .line()
      .defined((d) => !Number.isNaN(d.smoothed))
      .curve(d3.curveBasis)
      .x((d) => this.xScale(d.year))
      .y((d) => this.yScale(d.smoothed * config.MILLIONS));
    this.viz
      .append('path')
      .datum(data)
      .classed('trend', true)
      .classed('chronam', true)
      .attr('d', line);
    return this.status;
  }
}
