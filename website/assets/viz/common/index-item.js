import * as d3 from 'd3';
import colorScale from './color-scale';
import domID from './dom-id';
import randomColorInt from './random-int';
import VerseSparkline from './verse-sparkline';
import { bigNumberFormat, peakDecade } from './display';

export default class IndexItem {
  constructor(id, reference, text, count, peak) {
    this.node = d3
      .select(id)
      .append('div')
      .classed('grid-x', true)
      .classed('grid-margin-x', true)
      .classed('grid-margin-y', true);
    this.reference = reference;
    this.text = text;
    this.count = count;
    this.peak = peak;

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
      colorScale(randomColorInt()),
      false
    );

    this.sparkline.render();

    this.node
      .append('div')
      .classed('cell', true)
      .classed('medium-9', true)
      .html(
        `<h4><a href="${this.link}">${this.reference}</a> <small>(${peakDecade(
          this.peak
        )}${bigNumberFormat(this.count)} quotations)</small></h4><p>&ldquo;${
          this.text
        }&rdquo;</p>`
      );
  }
}
