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
    this.chronamURL = `${config.API_BASE}/apb/verse-trend?ref=${v}&corpus=chronam`;
    this.ncnpURL = `${config.API_BASE}/apb/verse-trend?ref=${v}&corpus=ncnp`;
  }

  async fetch() {
    const dataPromises = [d3.json(this.chronamURL), d3.json(this.ncnpURL)];
    await Promise.all(dataPromises)
      .then((data) => {
        [this.chronamData, this.ncnpData] = data;
        this.status = 'ok';
      })
      .catch((e) => {
        console.log(e);
        this.status = 'failed';
      });
    return this.status;
  }

  get chronam() {
    return this.chronamData.trend;
  }

  get ncnp() {
    return this.ncnpData.trend;
  }

  async render() {
    await this.fetch();

    if (this.status !== 'ok') {
      this.node.remove();
      return this.status;
    }

    const [chronam, ncnp] = [this.chronam, this.ncnp];

    this.xScale = d3
      .scaleLinear()
      .domain(d3.extent(chronam, (d) => d.year))
      .range([0, this.width]);

    this.xAxis = d3.axisBottom().scale(this.xScale).tickFormat(d3.format('d'));

    this.yScale = d3
      .scaleLinear()
      .domain([0, d3.max(chronam, (d) => d.smoothed * config.MILLIONS)])
      .range([this.height, 0])
      .nice();

    this.yAxis = d3.axisLeft().scale(this.yScale);

    this.svg
      .append('g')
      .attr('class', 'x axis')
      .attr(
        'transform',
        `translate(${this.margin.left},${this.margin.top + this.height})`
      )
      .call(this.xAxis);

    this.svg
      .append('g')
      .attr('class', 'y axis')
      .attr('transform', `translate(${this.margin.left},${this.margin.top})`)
      .call(this.yAxis);

    const line = d3
      .line()
      .defined((d) => !Number.isNaN(d.smoothed))
      .curve(d3.curveBasis)
      .x((d) => this.xScale(d.year))
      .y((d) => this.yScale(d.smoothed * config.MILLIONS));

    // Draw the lines. NCNP first so that it is on the bottom.
    this.viz
      .append('path')
      .datum(ncnp)
      .classed('trend', true)
      .classed('ncnp', true)
      .attr('d', line);

    this.viz
      .append('path')
      .datum(chronam)
      .classed('trend', true)
      .classed('chronam', true)
      .attr('d', line);

    const legend = this.viz
      .append('g')
      .attr('transform', 'translate(10, 20)')
      .classed('legend', true);

    legend
      .append('line')
      .attr('x1', 0)
      .attr('y1', 0)
      .attr('x2', 40)
      .attr('y2', 0)
      .classed('trend', true)
      .classed('chronam', true);
    legend
      .append('text')
      .attr('x', 45)
      .attr('y', 0)
      .text('Chronicling America');

    legend
      .append('line')
      .attr('x1', 0)
      .attr('y1', 30)
      .attr('x2', 40)
      .attr('y2', 30)
      .classed('trend', true)
      .classed('ncnp', true);
    legend.append('text').attr('x', 45).attr('y', 30).text('19c Newspapers');

    return this.status;
  }
}
