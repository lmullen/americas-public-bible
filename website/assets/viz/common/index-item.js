import * as d3 from 'd3';
import domID from './dom-id';
import VerseSparkline from './verse-sparkline';

export default class IndexItem {
  constructor(id, reference, text) {
    this.node = d3
      .select(id)
      .append('div')
      .classed('grid-x', true)
      .classed('grid-margin-x', true)
      .classed('grid-margin-y', true);
    this.reference = reference;
    this.text = text;

    const r = encodeURIComponent(reference);
    this.link = `/verse-viewer?ref=${r}`;
    this.sparkID = domID('featured', reference);
  }

  render() {
    this.node
      .append('a')
      .attr('id', this.sparkID)
      .attr('href', this.link)
      .classed('cell', true)
      .classed('medium-3', true);

    this.sparkline = new VerseSparkline(
      `#${this.sparkID}`,
      this.reference,
      300,
      75,
      'green',
      false
    );

    this.sparkline.render();

    this.node
      .append('div')
      .classed('cell', true)
      .classed('medium-9', true)
      .html(
        `<p><strong><a href="${this.link}">${this.reference}</a></strong>&mdash;${this.text}</p>`
      );
  }
}
