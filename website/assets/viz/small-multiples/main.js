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
      const cellID = `cell-${counter}`;
      const url = `/verse-viewer?ref=${encodeURIComponent(d.reference)}`;

      const cell = grid
        .append('a')
        .attr('id', cellID)
        .attr('title', d.text)
        .attr('href', url)
        .classed('cell', true)
        .classed('medium-2', true)
        .classed('small-4', true);

      cell.append('h4').classed('viz-title', true).text(d.reference);

      const sparky = new VerseSparkline(`#${cellID}`, d.reference);
      sparky.render();
    });
  })
  .catch((e) => console.log(e));
