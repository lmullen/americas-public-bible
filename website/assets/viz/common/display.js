import { timeParse, timeFormat, format } from 'd3';

const dateParse = timeParse('%Y-%m-%d');
const formatYear = timeFormat('%Y');
const formatDay = timeFormat('%b %d');
const formatDate = timeFormat('%d %B %Y');

// A set of functions that takes in an ISO 8601 date string,
// e.g. "1844-10-22" and returns a formatted string.
export function year(dateString) {
  const d = dateParse(dateString);
  return formatYear(d); // "1844"
}

export function day(dateString) {
  const d = dateParse(dateString);
  return formatDay(d); // Oct 22
}

export function date(dateString) {
  const d = dateParse(dateString);
  return formatDate(d); // 22 Oct 1844
}

// Take in a probability and return a label
export function probLabel(p) {
  let type;
  if (p >= 0.9) type = 'higher';
  if (p >= 0.8 && p < 0.9) type = 'medium';
  if (p < 0.8) type = 'lower';
  return `<span class="label ${type}" title="Model probability estimate: ${p}">${type}</span>`;
}

export const commaFormat = format(',');
export const decimal1Format = format('.1f');
