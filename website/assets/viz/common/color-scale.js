import * as d3 from 'd3';

const colorScale = d3
  .scaleSequential((t) => d3.hsl(t * 360, 1, 0.425).toString())
  .domain([1, 36]);

export default colorScale;
