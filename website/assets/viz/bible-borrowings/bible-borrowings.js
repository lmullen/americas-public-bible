import * as d3 from 'd3';
import Visualization from '../common/visualization';
import config from '../config';

export default class BibleBorrowings extends Visualization {
  constructor(id) {
    const dim = {
      width: 1000,
      height: 900,
    };
    const margin = {
      top: 10,
      right: 10,
      bottom: 10,
      left: 10,
    };

    super(id, dim, margin, 'How Books of the Bible borrow from one another');

    this.viz.attr('transform', `translate(${dim.width / 2},${dim.height / 2})`);

    this.booksURL = `${config.API_BASE}/apb/bible-books`;
    this.edgesURL = `${config.API_BASE}/apb/bible-similarity`;

    const scale = d3.scaleOrdinal(d3.schemeCategory10);
    this.color = (d) => scale(d.part);

    this.drag = (simulation) => {
      function dragstarted(event, d) {
        if (!event.active) simulation.alphaTarget(0.3).restart();
        d.fx = d.x;
        d.fy = d.y;
      }

      function dragged(event, d) {
        d.fx = event.x;
        d.fy = event.y;
      }

      function dragended(event, d) {
        if (!event.active) simulation.alphaTarget(0);
        d.fx = null;
        d.fy = null;
      }

      return d3
        .drag()
        .on('start', dragstarted)
        .on('drag', dragged)
        .on('end', dragended);
    };
  }

  async fetch() {
    try {
      this.books = await d3.json(this.booksURL);
      this.edges = await d3.json(this.edgesURL);
      this.status = 'ok';
    } catch (e) {
      if (e.message === '404 Not Found') {
        console.log(e);
        this.status = 'missing';
      } else {
        console.log(e);
        this.status = 'failed';
      }
    }
    return this.status;
  }

  async render() {
    await this.fetch();

    if (this.status !== 'ok') {
      this.title.remove();
      this.svg.remove();
      return this.status;
    }

    const uniqueNodes = new Set();
    this.edges.forEach((d) => {
      uniqueNodes.add(d.source);
      uniqueNodes.add(d.target);
    });

    const booksInGraph = this.books.filter((book) =>
      uniqueNodes.has(book.book)
    );

    const links = this.edges.map((d) => Object.create(d));
    const nodes = booksInGraph.map((d) => Object.create(d));

    const simulation = d3
      .forceSimulation(nodes)
      .force(
        'link',
        d3.forceLink(links).id((d) => d.book)
      )
      .force('charge', d3.forceManyBody().strength(-600))
      .force('center', d3.forceCenter().strength(1.6))
      .force('x', d3.forceX())
      .force('y', d3.forceY());

    const link = this.viz
      .append('g')
      .attr('stroke', '#999')
      .attr('stroke-opacity', 0.6)
      .selectAll('line')
      .data(links)
      .join('line')
      .attr('stroke-width', (d) => Math.sqrt(d.n / 18));

    const node = this.viz
      .append('g')
      .attr('stroke', '#fff')
      .attr('stroke-width', 1.5);

    node.selectAll('g').data(nodes).join('g');

    node
      .selectAll('g')
      .append('circle')
      .attr('r', 5)
      .attr('fill', this.color)
      .call(this.drag(simulation));

    node
      .selectAll('g')
      .append('text')
      .attr('dx', 12)
      .attr('dy', '0.35em')
      .style('fill', 'black')
      .style('stroke', 'none')
      .text((d) => d.book);

    simulation.on('tick', () => {
      link
        .attr('x1', (d) => d.source.x)
        .attr('y1', (d) => d.source.y)
        .attr('x2', (d) => d.target.x)
        .attr('y2', (d) => d.target.y);

      node
        .selectAll('g')
        .select('circle')
        .attr('cx', (d) => d.x)
        .attr('cy', (d) => d.y);
      node
        .selectAll('g')
        .select('text')
        .attr('x', (d) => d.x)
        .attr('y', (d) => d.y);
    });

    // invalidation.then(() => simulation.stop());
    // simulation.stop();

    return this.status;
  }
}
