'use strict';
const search = document.querySelector('#search');
const slider = document.querySelector('#threshold');
const list = [...document.querySelectorAll('.pair')];
const normalise = text => text.toLocaleLowerCase('fr').normalize('NFD').replace(/[\u0300-\u036f]/g, '');
function filterPairs() {
  const term = normalise(search.value.trim());
  const threshold = Number(slider.value);
  document.querySelector('#threshold-value').textContent = threshold.toFixed(3).replace(/0+$/, '').replace(/\.$/, '');
  let count = 0;
  for (const pair of list) {
    const visible = Number(pair.dataset.score) >= threshold && normalise(pair.dataset.search).includes(term);
    pair.hidden = !visible;
    if (visible) count++;
  }
  document.querySelector('#visible-count').textContent = count;
}
if (search && slider) {
  search.addEventListener('input', filterPairs);
  slider.addEventListener('input', filterPairs);
  filterPairs();
}
const readings = [...document.querySelectorAll('.reading')];
const marks = readings.flatMap((reading, pane) => [...reading.querySelectorAll('mark.diff')].map(node => ({node, pane})));
let position = -1;
function navigate(direction) {
  if (!marks.length) return;
  if (position >= 0) marks[position].node.classList.remove('focus');
  position = (position + direction + marks.length) % marks.length;
  marks[position].node.classList.add('focus');
  marks[position].node.scrollIntoView({block:'center', behavior:'instant'});
  document.querySelector('#diff-position').textContent = `${position + 1} / ${marks.length}`;
}
document.querySelector('#prev')?.addEventListener('click', () => navigate(-1));
document.querySelector('#next')?.addEventListener('click', () => navigate(1));
document.querySelector('#only-diff')?.addEventListener('change', event => {
  for (const reading of readings) {
    const prose = reading.querySelector('.prose');
    prose.classList.toggle('hide-unchanged', event.target.checked);
    for (const p of prose.querySelectorAll('p')) p.classList.toggle('no-change', !p.querySelector('mark.diff'));
  }
});
let syncing = false;
for (let i = 0; i < readings.length; i++) {
  readings[i].addEventListener('scroll', () => {
    if (syncing || !document.querySelector('#sync')?.checked) return;
    const other = readings[1-i];
    if (!other) return;
    syncing = true;
    const source = readings[i];
    const range = source.scrollHeight - source.clientHeight;
    other.scrollTop = range > 0 ? (source.scrollTop / range) * (other.scrollHeight - other.clientHeight) : 0;
    requestAnimationFrame(() => { syncing = false; });
  }, {passive:true});
}
