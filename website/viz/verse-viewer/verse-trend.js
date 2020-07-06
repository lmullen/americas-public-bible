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
      .domain([0, d3.max(chronam, (d) => d.smoothed * 100)])
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
      .defined((d) => !Number.isNaN(d.smoothed))
      .curve(d3.curveBasis)
      .x((d) => this.xScale(d.year))
      .y((d) => this.yScale(d.smoothed * 100));

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

    return this.status;
  }
}
