import { select } from 'd3';

export default class Alert {
  constructor(id, type, text) {
    this.node = select(id);
    this.type = type;
    this.text = text;
  }

  render() {
    this.node
      .append('div')
      .classed('callout', true)
      .classed(this.type, true)
      .html(`<p>${this.text}</p>`);
  }
}
