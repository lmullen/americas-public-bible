import * as d3 from 'd3';
import config from '../config';
import VerseSparkline from '../common/verse-sparkline';

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
      counter += 1;
      const cell = `cell-${counter}`;
      grid
        .append('div')
        .attr('id', cell)
        .classed('cell', true)
        .classed('medium-2', true)
        .classed('small-4', true);

      const sparky = new VerseSparkline(`#${cell}`, d.reference);
      sparky.render();
    });
  })
  .catch((e) => console.log(e));
