import * as d3 from 'd3';
import config from '../config';
import VerseSparkline from '../common/verse-sparkline';

const color = d3
  .scaleSequential((t) => d3.hsl(t * 360, 1, 0.5).toString())
  .domain([1, 36]);

const colorNum = d3.shuffle(d3.range(36));

d3.select('#small-multiples')
  .append('h4')
  .classed('viz-title', true)
  .text('Trends in quotation rates for popular verses, 1836–1922');

const grid = d3
  .select('#small-multiples')
  .append('div')
  .classed('grid-x', true)
  .classed('grid-margin-x', true)
  .classed('grid-margin-y', true);

const topPromise = d3.json(`${config.API_BASE}/apb/index/top/`);

topPromise
  .then((data) => {
    const top = data.slice(0, 36);
    let counter = 0;
    top.forEach((d) => {
      const cellID = `cell-${counter}`;
      const url = `/verse-viewer?ref=${encodeURIComponent(d.reference)}`;

      grid
        .append('a')
        .attr('id', cellID)
        .attr('title', d.text)
        .attr('href', url)
        .classed('cell', true)
        .classed('medium-2', true)
        .classed('small-4', true);

      const sparky = new VerseSparkline(
        `#${cellID}`,
        d.reference,
        color(colorNum[counter])
      );
      sparky.render();

      counter += 1;
    });
  })
  .catch((e) => console.log(e));
