import * as d3 from 'd3';

export default class Visualization {
  constructor(id, dim, margin) {
    this.margin = margin;

    // Select the SVG, figure out the correct height, and use the
    // viewBox property to make it scale responsively.
    this.node = d3.select(id);
    this.svg = this.node.append('svg').attr('width', '100%');
    this.width = dim.width;
    this.height = dim.height;
    const outerWidth = this.width + this.margin.left + this.margin.right;
    const outerHeight = this.height + this.margin.top + this.margin.bottom;
    this.svg
      .attr('viewBox', `0 0 ${outerWidth} ${outerHeight}`)
      .style('overflow', 'visible');

    // The viz is the usable part of the plot, excluding the margins
    this.viz = this.svg
      .append('g')
      .attr('transform', `translate(${margin.left},${margin.top})`);

    // Capture mouse events on the just the useable part of the plot. We need
    // an empty rect in order to capture mouse events.
    this.viz
      .style('pointer-events', 'all')
      .append('rect')
      .style('visibility', 'hidden')
      .attr('x', 0)
      .attr('y', 0)
      .attr('width', this.width)
      .attr('height', this.height);
  }
}
