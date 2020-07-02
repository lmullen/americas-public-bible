// A set of functions that takes in an ISO 8601 date string,
// e.g. "1844-07-04" and returns a formatted string.

import { timeParse, timeFormat } from 'd3';

const dateParse = timeParse('%Y-%m-%d');
const formatYear = timeFormat('%Y');
const formatDay = timeFormat('%b %d');
const formatDate = timeFormat('%d %B %Y');

export function year(dateString) {
  const d = dateParse(dateString);
  return formatYear(d);
}

export function day(dateString) {
  const d = dateParse(dateString);
  return formatDay(d);
}

export function date(dateString) {
  const d = dateParse(dateString);
  return formatDate(d);
}
