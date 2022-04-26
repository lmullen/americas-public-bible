import * as d3 from "d3";
import config from "../config";
import { year, day, probLabel } from "../common/display";
import { wordsForUrl } from "../common/text";

export default class VerseQuotations {
  constructor(id, reference, verseText) {
    this.node = d3.select(id);
    this.data = null;
    this.status = "loading";
    const ref = encodeURIComponent(reference);
    this.url = `${config.API_BASE}/apb/verse-quotations?ref=${ref}`;
    this.keywords = wordsForUrl(verseText);
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
  }

  async render() {
    await this.fetch();

    if (this.status !== "ok") {
      this.node.remove();
      return this.status;
    }

    const t = this.node.append("table").classed("hover", true);

    t.append("thead")
      .append("tr")
      .html(
        `<th>Year</th>
      <th style="min-width:80px;">Date</th>
      <th>Newspaper</th>
      <th style="min-width:20%">State</th>
      <th>Certainty</th>
      <th>Context</th>`
      );

    // Here this.table is actually the <tbody> node
    this.table = t.append("tbody");

    this.table
      .selectAll("tr")
      .data(this.data, (d) => d.doc_id)
      .enter()
      .append("tr")
      .html(
        (d) =>
          `<td>${year(d.date)}</td>
          <td>${day(d.date)}</td>
          <td>${d.title}</td>
          <td>${d.state}</td>
          <td>${probLabel(d.probability)}</td>
          <td><a href="${this.chronamQuery(d.docID)}">ChronAm&nbsp;&rarr;</a></td>`
      );

    return this.status;
  }

  chronamQuery(docID) {
    return `${config.CHRONAM_PAGE_BASE}/${docID}#words=${this.keywords}`;
  }
}
