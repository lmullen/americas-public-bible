import * as d3 from 'd3';
import { maxIndex } from 'd3-array';
import Visualization from '../common/visualization';
import { commaFormat, decimal1Format } from '../common/display';
import config from '../config';

export default class VerseTrend extends Visualization {
  constructor(id, ref, title) {
    const dim = {
      width: 1000,
      height: 500,
    };
    const margin = {
      top: 10,
      right: 10,
      bottom: 60,
      left: 65,
    };

    super(id, dim, margin, title);

    const v = encodeURIComponent(ref);
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

    // Axes and scales
    this.xScale = d3
      .scaleLinear()
      .domain(d3.extent(chronam, (d) => d.year))
      .range([0, this.width]);

    this.xAxis = d3
      .axisBottom()
      .scale(this.xScale)
      .tickFormat(d3.format('d'))
      .ticks(20);

    // The max of the y-scale needs to be the max of Chronam AND NCNP
    const max = Math.max(
      d3.max(chronam, (d) => d.smoothed),
      d3.max(ncnp, (d) => d.smoothed)
    );

    this.yScale = d3
      .scaleLinear()
      .domain([0, max * config.MILLIONS])
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
      .attr(
        'transform',
        `translate(${this.margin.left - 5},${this.margin.top})`
      )
      .call(this.yAxis);

    // Axis labels
    this.svg
      .append('text')
      .attr('transform', 'rotate(-90)')
      .attr('y', this.margin.left / 2 - 10)
      .attr('x', -(this.height + this.margin.top) / 2)
      .style('text-anchor', 'middle')
      .text(`Quotations per ${config.MILLIONS}M words`);

    // Legend and data point information
    const legend = this.svg
      .append('g')
      .classed('legend', true)
      .attr(
        'transform',
        `translate(${this.margin.left}, ${this.margin.top + this.height + 40})`
      )
      .classed('legend', true);

    let xOffset = 0;
    legend
      .append('line')
      .attr('x1', xOffset + 0)
      .attr('y1', 0)
      .attr('x2', xOffset + 40)
      .attr('y2', 0)
      .classed('trend', true)
      .classed('chronam', true);
    legend
      .append('text')
      .attr('x', xOffset + 45)
      .attr('y', 0)
      .text('Chronicling America');

    xOffset += 225;
    legend
      .append('line')
      .attr('x1', xOffset + 0)
      .attr('y1', 0)
      .attr('x2', xOffset + 40)
      .attr('y2', 0)
      .classed('trend', true)
      .classed('ncnp', true);
    legend
      .append('text')
      .attr('x', xOffset + 45)
      .attr('y', 0)
      .text('19c Newspapers');

    xOffset += 220;
    legend
      .append('text')
      .attr('x', xOffset + 0)
      .attr('y', 0)
      .text('Year:');
    const detailYear = legend
      .append('text')
      .attr('x', xOffset + 42)
      .attr('y', 0);

    xOffset += 95;
    legend
      .append('text')
      .attr('x', xOffset + 0)
      .attr('y', 0)
      .text('Quotations:');
    const detailQuotations = legend
      .append('text')
      .attr('x', xOffset + 92)
      .attr('y', 0);

    xOffset += 130;
    legend
      .append('text')
      .attr('x', xOffset + 0)
      .attr('y', 0)
      .text('Rate:');
    const detailRate = legend
      .append('text')
      .attr('x', xOffset + 42)
      .attr('y', 0);

    // Mouseover to get details from the visualization
    const maxObs = chronam[maxIndex(chronam, (d) => d.smoothed)];
    const marker = this.viz
      .append('line')
      .classed('detail-marker', true)
      .attr('y2', this.height)
      .attr('x1', this.xScale(maxObs.year))
      .attr('x2', this.xScale(maxObs.year));

    // const highlight = this.viz
    //   .append('circle')
    //   .classed('highlight', true)
    //   .attr('r', 8)
    //   .attr('fill', 'none')
    //   .attr('stroke', 'red');

    const bisect = d3.bisector((d) => d.year);

    const updateDetails = (d) => {
      marker.attr('x1', this.xScale(d.year)).attr('x2', this.xScale(d.year));
      detailYear.text(d.year);
      detailQuotations.text(commaFormat(d.n));
      detailRate.text(decimal1Format(d.smoothed * config.MILLIONS));
      // highlight
      //   .attr('cx', this.xScale(d.year))
      //   .attr('cy', this.yScale(d.smoothed * config.MILLIONS));
    };
    updateDetails(maxObs);

    this.viz.on('mousemove click touchmove', (event) => {
      const x = d3.pointer(event, this.viz.node())[0];
      const year = Math.round(this.xScale.invert(x));
      const i = bisect.left(chronam, year);
      const d = chronam[i];
      updateDetails(d);
    });

    // Draw the lines. NCNP first so that it is on the bottom.
    const line = d3
      .line()
      .defined((d) => !Number.isNaN(d.smoothed))
      .curve(d3.curveBasis)
      .x((d) => this.xScale(d.year))
      .y((d) => this.yScale(d.smoothed * config.MILLIONS));

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
