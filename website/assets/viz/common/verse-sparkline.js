import * as d3 from "d3";
import Visualization from "./visualization";
import config from "../config";

export default class VerseSparkline extends Visualization {
  constructor(id, ref, width, height, color, title) {
    const dim = { width, height };
    const margin = {
      top: 0,
      right: 0,
      bottom: 0,
      left: 0,
    };

    const titleText = title ? ref : null;

    super(id, dim, margin, titleText);

    const v = encodeURIComponent(ref);
    this.url = `${config.API_BASE}/apb/verse-trend?ref=${v}&corpus=chronam`;
    this.color = color;
  }

  async fetch() {
    try {
      this.data = await d3.json(this.url);
      this.status = "ok";
    } catch (e) {
      if (e.message === "404 Not Found") {
        console.log(e);
        this.status = "missing";
      } else {
        console.log(e);
        this.status = "failed";
      }
    }
    return this.status;
  }

  async render() {
    await this.fetch();

    if (this.status !== "ok") {
      this.node.remove();
      return this.status;
    }

    const data = this.data.trend;

    // Axes and scales
    this.xScale = d3
      .scaleLinear()
      .domain(d3.extent(data, (d) => d.year))
      .range([0, this.width]);

    this.yScale = d3
      .scaleLinear()
      .domain([0, d3.max(data, (d) => d.smoothed) * config.MILLIONS])
      .range([this.height, 0])
      .nice();

    const line = d3
      .line()
      .defined((d) => !Number.isNaN(d.smoothed))
      .curve(d3.curveBasis)
      .x((d) => this.xScale(d.year))
      .y((d) => this.yScale(d.smoothed * config.MILLIONS));

    this.viz
      .append("path")
      .datum(data)
      .classed("trend", true)
      .classed("sparkline", true)
      .attr("d", line)
      .style("stroke", this.color)
      .style("stroke-width", 2)
      .style("fill", "none");

    return this.status;
  }
}
