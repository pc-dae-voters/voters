// Voter register web UI, a single page app using the voters API, served by the API at /.
// Routes, in the URL's hash:
//   #/                        dashboard
//   #/<resource>?<filters>    list, e.g. #/voters?constituencyId=12&page=2
//   #/<resource>/new?<values> create form, the values prefill it, e.g. #/voters/new?citizenId=5
//   #/<resource>/<id>         record, with its related records, edit and delete
'use strict';

const API = 'api';

// Column, field and filter helpers
const col = (name, label, opts = {}) => ({ name, label, ...opts });
const link = (resource, idField) => ({ resource, idField });
const field = (name, label, opts = {}) => ({ name, label, type: 'text', ...opts });

// Each resource's list columns, list filters, form fields and related records. A column's sort is the API's sort
// property, columns without one can't be sorted. A related list's params are its filters and add, if set, prefills
// its create form.
const RESOURCES = {
  voters: {
    title: 'Voters', singular: 'Voter', group: 'Register',
    label: r => r.citizenName || `Voter ${r.id}`,
    columns: [
      col('id', 'ID', { sort: 'id', num: true }),
      col('citizenName', 'Name', { link: link('citizens', 'citizenId') }),
      col('address', 'Address', { link: link('addresses', 'addressId') }),
      col('postcode', 'Postcode'),
      col('constituencyName', 'Constituency', { link: link('constituencies', 'constituencyId') }),
      col('openRegister', 'Open register', { sort: 'openRegister', bool: true }),
      col('registrationDate', 'Registered', { sort: 'registrationDate' }),
    ],
    filters: [
      field('q', 'Name'), field('postcode', 'Postcode'),
      field('openRegister', 'Open register', { type: 'bool' }),
    ],
    fields: [
      field('citizenId', 'Citizen', { type: 'ref', ref: 'citizens', required: true }),
      field('addressId', 'Address', { type: 'ref', ref: 'addresses', required: true }),
      field('openRegister', 'On the open register', { type: 'checkbox' }),
      field('registrationDate', 'Registration date', { type: 'date', hint: 'Defaults to today' }),
    ],
  },
  citizens: {
    title: 'Citizens', singular: 'Citizen', group: 'Register',
    label: r => [r.firstName, r.surname].filter(Boolean).join(' ') || `Citizen ${r.id}`,
    columns: [
      col('id', 'ID', { sort: 'id', num: true }),
      col('firstName', 'First name', { sort: 'firstName.name' }),
      col('surname', 'Surname', { sort: 'surname.name' }),
      col('gender', 'Gender', { sort: 'gender' }),
      col('statusDescription', 'Status'),
      col('birthDate', 'Born'),
      col('died', 'Died', { sort: 'died' }),
      col('voterId', 'Voter', { link: link('voters', 'voterId') }),
    ],
    filters: [
      field('q', 'Name'),
      field('gender', 'Gender', { type: 'select', options: ['M', 'F'] }),
      field('statusCode', 'Status', { type: 'select', optionsFrom: 'citizen-statuses', optionValue: 'code', optionLabel: 'description' }),
      field('alive', 'Alive', { type: 'bool' }),
    ],
    fields: [
      field('firstName', 'First name', { required: true, hint: 'Added to the names if new' }),
      field('surname', 'Surname', { required: true, hint: 'Added to the names if new' }),
      field('gender', 'Gender', { type: 'select', options: ['M', 'F'], required: true }),
      field('statusCode', 'Status', { type: 'select', optionsFrom: 'citizen-statuses', optionValue: 'code', optionLabel: 'description' }),
      field('died', 'Date of death', { type: 'date' }),
    ],
    related: r => [
      { title: 'Voter registration', resource: 'voters', params: { citizenId: r.id }, add: r.voterId ? null : { citizenId: r.id } },
      { title: 'Birth record', resource: 'births', params: { citizenId: r.id }, add: { citizenId: r.id, firstName: r.firstName, surname: r.surname, gender: r.gender } },
      { title: 'Children', resource: 'births', params: { parentId: r.id }, add: { [r.gender === 'F' ? 'motherId' : 'fatherId']: r.id, surname: r.surname } },
      { title: 'Marriages', resource: 'marriages', params: { citizenId: r.id }, add: { partner1Id: r.id } },
      { title: 'Record changes', resource: 'citizen-changes', params: { citizenId: r.id }, add: { citizenId: r.id } },
    ],
  },
  constituencies: {
    title: 'Constituencies', singular: 'Constituency', group: 'Geography',
    label: r => r.name,
    columns: [
      col('name', 'Name', { sort: 'name', link: link('constituencies', 'id') }),
      col('code', 'Code', { sort: 'code' }),
      col('nation', 'Nation', { sort: 'nation' }),
      col('region', 'Region', { sort: 'region' }),
      col('ctype', 'Type', { sort: 'ctype' }),
      col('area', 'Area', { sort: 'area', num: true }),
    ],
    filters: [
      field('q', 'Name or code'),
      field('nation', 'Nation', { type: 'select', optionsUrl: 'constituencies/nations' }),
      field('region', 'Region', { type: 'select', optionsUrl: 'constituencies/regions' }),
    ],
    fields: [
      field('name', 'Name', { required: true }), field('code', 'Code'), field('tla', 'Three letter abbreviation'),
      field('nation', 'Nation'), field('region', 'Region'), field('ctype', 'Type'), field('area', 'Area', { type: 'number' }),
    ],
    related: r => [
      { title: 'Voters', resource: 'voters', params: { constituencyId: r.id } },
      { title: 'Addresses', resource: 'addresses', params: { constituencyId: r.id }, add: { constituencyId: r.id } },
      { title: 'Postcodes', resource: 'postcodes', params: { conCode: r.code }, add: { conCode: r.code } },
    ],
  },
  addresses: {
    title: 'Addresses', singular: 'Address', group: 'Geography',
    label: r => r.address,
    columns: [
      col('id', 'ID', { sort: 'id', num: true }),
      col('address', 'Address', { sort: 'address', link: link('addresses', 'id') }),
      col('postcode', 'Postcode', { sort: 'postcode', link: link('postcodes', 'postcode') }),
      col('placeName', 'Place', { link: link('places', 'placeId') }),
      col('constituencyName', 'Constituency', { link: link('constituencies', 'constituencyId') }),
    ],
    filters: [field('q', 'Address'), field('postcode', 'Postcode')],
    fields: [
      field('address', 'Address', { required: true, wide: true }),
      field('postcode', 'Postcode', { required: true }),
      field('placeId', 'Place', { type: 'ref', ref: 'places' }),
      field('countryId', 'Country', { type: 'ref', ref: 'countries' }),
      field('constituencyId', 'Constituency', { type: 'ref', ref: 'constituencies', hint: 'Leave empty to use the postcode\'s constituency' }),
    ],
    related: r => [
      { title: 'Voters at this address', resource: 'voters', params: { addressId: r.id }, add: { addressId: r.id } },
    ],
  },
  postcodes: {
    title: 'Postcodes', singular: 'Postcode', group: 'Geography', idField: 'postcode',
    label: r => r.postcode,
    columns: [
      col('postcode', 'Postcode', { sort: 'postcode', link: link('postcodes', 'postcode') }),
      col('conCode', 'Constituency code', { sort: 'conCode' }),
      col('constituencyName', 'Constituency', { link: link('constituencies', 'constituencyId') }),
    ],
    filters: [field('q', 'Postcode starts with'), field('conCode', 'Constituency code')],
    fields: [
      field('postcode', 'Postcode', { required: true, readonlyOnEdit: true }),
      field('conCode', 'Constituency code', { required: true }),
    ],
    related: r => [
      { title: 'Addresses', resource: 'addresses', params: { postcode: r.postcode }, add: { postcode: r.postcode } },
      { title: 'Voters', resource: 'voters', params: { postcode: r.postcode } },
    ],
  },
  places: {
    title: 'Places', singular: 'Place', group: 'Geography',
    label: r => r.name,
    columns: [
      col('id', 'ID', { sort: 'id', num: true }),
      col('name', 'Name', { sort: 'name', link: link('places', 'id') }),
      col('countryName', 'Country', { link: link('countries', 'countryId') }),
    ],
    filters: [field('q', 'Name')],
    fields: [field('name', 'Name', { required: true }), field('countryId', 'Country', { type: 'ref', ref: 'countries' })],
    related: r => [
      { title: 'Addresses', resource: 'addresses', params: { placeId: r.id }, add: { placeId: r.id } },
      { title: 'Voters', resource: 'voters', params: { placeId: r.id } },
      { title: 'Births', resource: 'births', params: { placeId: r.id } },
    ],
  },
  countries: {
    title: 'Countries', singular: 'Country', group: 'Geography',
    label: r => r.name,
    columns: [col('id', 'ID', { sort: 'id', num: true }), col('name', 'Name', { sort: 'name', link: link('countries', 'id') })],
    filters: [field('q', 'Name')],
    fields: [field('name', 'Name', { required: true })],
    related: r => [{ title: 'Places', resource: 'places', params: { countryId: r.id }, add: { countryId: r.id } }],
  },
  births: {
    title: 'Births', singular: 'Birth', group: 'Life events',
    label: r => `Birth of ${[r.firstName, r.surname].filter(Boolean).join(' ') || r.citizenName || r.id}`,
    columns: [
      col('id', 'ID', { sort: 'id', num: true, link: link('births', 'id') }),
      col('citizenName', 'Citizen', { link: link('citizens', 'citizenId') }),
      col('firstName', 'Name at birth'),
      col('date', 'Date', { sort: 'date' }),
      col('placeName', 'Place', { link: link('places', 'placeId') }),
      col('fatherName', 'Father', { link: link('citizens', 'fatherId') }),
      col('motherName', 'Mother', { link: link('citizens', 'motherId') }),
    ],
    filters: [field('citizenId', 'Citizen ID', { type: 'number' }), field('parentId', 'Parent ID', { type: 'number' })],
    fields: [
      field('citizenId', 'Citizen', { type: 'ref', ref: 'citizens' }),
      field('date', 'Date of birth', { type: 'date', required: true }),
      field('firstName', 'First name at birth'), field('surname', 'Surname at birth'),
      field('gender', 'Gender', { type: 'select', options: ['M', 'F'] }),
      field('placeId', 'Place', { type: 'ref', ref: 'places' }),
      field('fatherId', 'Father', { type: 'ref', ref: 'citizens' }),
      field('motherId', 'Mother', { type: 'ref', ref: 'citizens' }),
    ],
  },
  marriages: {
    title: 'Marriages', singular: 'Marriage', group: 'Life events',
    label: r => `${r.partner1Name} and ${r.partner2Name}`,
    columns: [
      col('id', 'ID', { sort: 'id', num: true, link: link('marriages', 'id') }),
      col('partner1Name', 'Partner', { link: link('citizens', 'partner1Id') }),
      col('partner2Name', 'Partner', { link: link('citizens', 'partner2Id') }),
      col('marriedDate', 'Married', { sort: 'marriedDate' }),
      col('divorcedDate', 'Divorced', { sort: 'divorcedDate' }),
    ],
    filters: [field('citizenId', 'Citizen ID', { type: 'number' }), field('current', 'Still married', { type: 'bool' })],
    fields: [
      field('partner1Id', 'Partner', { type: 'ref', ref: 'citizens', required: true }),
      field('partner2Id', 'Partner', { type: 'ref', ref: 'citizens', required: true }),
      field('marriedDate', 'Marriage date', { type: 'date', required: true }),
      field('divorcedDate', 'Divorce date', { type: 'date' }),
    ],
  },
  'citizen-changes': {
    title: 'Record changes', singular: 'Record change', group: 'Life events',
    label: r => `Change ${r.id} to ${r.citizenName}`,
    columns: [
      col('id', 'ID', { sort: 'id', num: true, link: link('citizen-changes', 'id') }),
      col('citizenName', 'Citizen', { link: link('citizens', 'citizenId') }),
      col('changeDate', 'Date', { sort: 'changeDate' }),
      col('details', 'Details', { json: true }),
    ],
    filters: [field('citizenId', 'Citizen ID', { type: 'number' })],
    fields: [
      field('citizenId', 'Citizen', { type: 'ref', ref: 'citizens', required: true }),
      field('changeDate', 'Date', { type: 'date', required: true }),
      field('details', 'Details', { type: 'json', wide: true, hint: 'A JSON object, e.g. {"type": "surname_change"}' }),
    ],
  },
  'first-names': {
    title: 'First names', singular: 'First name', group: 'Reference data',
    label: r => r.name,
    columns: [col('id', 'ID', { sort: 'id', num: true }), col('name', 'Name', { sort: 'name', link: link('first-names', 'id') }), col('gender', 'Gender', { sort: 'gender' })],
    filters: [field('q', 'Name'), field('gender', 'Gender', { type: 'select', options: ['M', 'F'] })],
    fields: [field('name', 'Name', { required: true }), field('gender', 'Gender', { type: 'select', options: ['M', 'F'] })],
    related: r => [{ title: 'Citizens', resource: 'citizens', params: { firstName: r.name } }],
  },
  surnames: {
    title: 'Surnames', singular: 'Surname', group: 'Reference data',
    label: r => r.name,
    columns: [col('id', 'ID', { sort: 'id', num: true }), col('name', 'Name', { sort: 'name', link: link('surnames', 'id') })],
    filters: [field('q', 'Name')],
    fields: [field('name', 'Name', { required: true })],
    related: r => [{ title: 'Citizens', resource: 'citizens', params: { surname: r.name } }],
  },
  'citizen-statuses': {
    title: 'Citizen statuses', singular: 'Citizen status', group: 'Reference data',
    label: r => r.description || r.code,
    columns: [col('id', 'ID', { sort: 'id', num: true }), col('code', 'Code', { sort: 'code', link: link('citizen-statuses', 'id') }), col('description', 'Description', { sort: 'description' })],
    filters: [],
    fields: [field('code', 'Code', { required: true }), field('description', 'Description')],
    related: r => [{ title: 'Citizens', resource: 'citizens', params: { statusCode: r.code } }],
  },
};

const PAGING = ['page', 'size', 'sort'];
const main = document.getElementById('main');

// --- Utilities

const esc = v => String(v ?? '').replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const fmtNum = n => Number(n).toLocaleString('en-GB');
const idOf = (def, r) => r[def.idField || 'id'];
const href = (resource, id, params) => `#/${resource}${id !== undefined ? '/' + encodeURIComponent(id) : ''}${qs(params)}`;

function qs(params) {
  const entries = Object.entries(params || {}).filter(([, v]) => v !== undefined && v !== null && v !== '');
  return entries.length ? '?' + new URLSearchParams(entries).toString() : '';
}

async function api(path, options = {}) {
  const res = await fetch(`${API}/${path}`, {
    ...options,
    headers: { Accept: 'application/json', ...(options.body ? { 'Content-Type': 'application/json' } : {}) },
  });
  if (res.status === 204) return null;
  const body = await res.json().catch(() => null);
  if (!res.ok) throw new Error(body?.detail || body?.message || `${res.status} ${res.statusText}`);
  return body;
}

const optionCache = {};
async function options(f) {
  const key = f.optionsUrl || f.optionsFrom;
  if (!optionCache[key]) {
    optionCache[key] = f.optionsUrl
      ? api(f.optionsUrl).then(list => list.map(v => [v, v]))
      : api(`${f.optionsFrom}?size=500`).then(p => p.content.map(r => [r[f.optionValue], r[f.optionLabel] || r[f.optionValue]]));
    optionCache[key].catch(() => delete optionCache[key]);
  }
  return f.options ? f.options.map(v => [v, v]) : optionCache[key];
}

function toast(message) {
  const el = document.getElementById('toast');
  el.textContent = message;
  el.hidden = false;
  clearTimeout(toast.timer);
  toast.timer = setTimeout(() => { el.hidden = true; }, 3500);
}

function cell(c, r) {
  const v = r[c.name];
  if (c.bool) return v ? '<span class="pill yes">Yes</span>' : '<span class="pill no">No</span>';
  if (c.json) return v ? `<code>${esc(JSON.stringify(v))}</code>` : '';
  if (v === null || v === undefined || v === '') return '<span class="muted">–</span>';
  const text = c.num && typeof v === 'number' ? fmtNum(v) : esc(v);
  const target = c.link && r[c.link.idField];
  return target !== undefined && target !== null ? `<a href="${href(c.link.resource, target)}">${text}</a>` : text;
}

// --- Navigation

function renderNav(active) {
  const groups = {};
  for (const [key, def] of Object.entries(RESOURCES)) (groups[def.group] ||= []).push([key, def]);
  document.getElementById('nav').innerHTML =
    `<a href="#/" class="${active ? '' : 'active'}">Dashboard</a>` +
    Object.entries(groups).map(([group, items]) => `<h2>${esc(group)}</h2>` +
      items.map(([key, def]) => `<a href="#/${key}" class="${key === active ? 'active' : ''}">${esc(def.title)}</a>`).join('')).join('');
}

document.querySelector('.nav-toggle').addEventListener('click', e => {
  const nav = document.getElementById('nav');
  const open = nav.classList.toggle('open');
  e.currentTarget.setAttribute('aria-expanded', String(open));
});

// --- Views

async function dashboard() {
  renderNav(null);
  main.innerHTML = `<div class="page-head"><div><h1>Dashboard</h1><div class="muted">Synthetic UK voter register</div></div></div>
    <div class="quick">
      <form class="card filters" data-go="citizens" data-param="q"><label>Find a citizen<input name="v" placeholder="e.g. Jane Smith"></label><button class="primary">Search</button></form>
      <form class="card filters" data-go="voters" data-param="postcode"><label>Voters by postcode<input name="v" placeholder="e.g. SW1A 1AA"></label><button class="primary">Search</button></form>
      <form class="card filters" data-go="constituencies" data-param="q"><label>Find a constituency<input name="v" placeholder="e.g. Bristol"></label><button class="primary">Search</button></form>
    </div>
    <div id="stats"><p class="muted">Loading statistics…</p></div>`;
  main.querySelectorAll('form[data-go]').forEach(form => form.addEventListener('submit', e => {
    e.preventDefault();
    location.hash = href(form.dataset.go, undefined, { [form.dataset.param]: form.v.value.trim() });
  }));
  try {
    const s = await api('statistics');
    const stat = (value, label, to) => `<a class="stat" href="${to}"><div class="value">${fmtNum(value)}</div><div class="label">${esc(label)}</div></a>`;
    document.getElementById('stats').innerHTML =
      `<div class="stats">${Object.entries(s.counts).map(([k, v]) => stat(v, RESOURCES[k]?.title || k, `#/${k}`)).join('')}</div>
       <h2>Breakdown</h2>
       <div class="stats">
         ${stat(s.votersOnOpenRegister, 'Voters on the open register', '#/voters?openRegister=true')}
         ${stat(s.citizensAlive, 'Citizens alive', '#/citizens?alive=true')}
         ${stat(s.citizensMale, 'Male citizens', '#/citizens?gender=M')}
         ${stat(s.citizensFemale, 'Female citizens', '#/citizens?gender=F')}
       </div>`;
  } catch (e) {
    document.getElementById('stats').innerHTML = `<div class="error">${esc(e.message)}</div>`;
  }
}

// A paged, sortable table of a resource's records. Used by the list view and the related lists on a record's page,
// navigate is called with the new params when the page or sort changes.
async function renderTable(container, resource, params, navigate) {
  const def = RESOURCES[resource];
  container.innerHTML = '<p class="muted">Loading…</p>';
  let page;
  try {
    page = await api(resource + qs(params));
  } catch (e) {
    container.innerHTML = `<div class="error">${esc(e.message)}</div>`;
    return;
  }
  const [sortField, sortDir] = (params.sort || '').split(',');
  const info = page.page;
  if (!page.content.length) {
    container.innerHTML = '<div class="empty">No records found.</div>';
    return;
  }
  container.innerHTML = `<div class="table-wrap"><table><thead><tr>${def.columns.map(c => {
      if (!c.sort) return `<th scope="col">${esc(c.label)}</th>`;
      const active = sortField === c.sort;
      const arrow = active ? (sortDir === 'desc' ? ' ↓' : ' ↑') : '';
      return `<th scope="col" aria-sort="${active ? (sortDir === 'desc' ? 'descending' : 'ascending') : 'none'}"><button type="button" data-sort="${esc(c.sort)}">${esc(c.label)}${arrow}</button></th>`;
    }).join('')}<th></th></tr></thead>
    <tbody>${page.content.map(r => `<tr>${def.columns.map((c, i) =>
      `<td class="${c.num ? 'num' : ''}">${cell(c, r)}</td>`).join('')}<td><a href="${href(resource, idOf(def, r))}" aria-label="Open ${esc(def.label(r))}">Open</a></td></tr>`).join('')}</tbody></table></div>
    <div class="pager"><span>${fmtNum(info.totalElements)} record${info.totalElements === 1 ? '' : 's'} · page ${info.number + 1} of ${fmtNum(Math.max(info.totalPages, 1))}</span>
      <span class="actions"><button type="button" data-page="${info.number - 1}" ${info.number <= 0 ? 'disabled' : ''}>Previous</button>
      <button type="button" data-page="${info.number + 1}" ${info.number + 1 >= info.totalPages ? 'disabled' : ''}>Next</button></span></div>`;
  container.querySelectorAll('[data-sort]').forEach(b => b.addEventListener('click', () => {
    const dir = sortField === b.dataset.sort && sortDir !== 'desc' ? 'desc' : 'asc';
    navigate({ ...params, sort: `${b.dataset.sort},${dir}`, page: undefined });
  }));
  container.querySelectorAll('[data-page]').forEach(b => b.addEventListener('click', () => {
    navigate({ ...params, page: Number(b.dataset.page) || undefined });
  }));
}

async function filterInput(f, value) {
  const name = `name="${esc(f.name)}"`;
  if (f.type === 'bool') {
    return `<select ${name}><option value="">Any</option>${[['true', 'Yes'], ['false', 'No']].map(([v, l]) =>
      `<option value="${v}" ${value === v ? 'selected' : ''}>${l}</option>`).join('')}</select>`;
  }
  if (f.type === 'select') {
    const opts = await options(f).catch(() => []);
    return `<select ${name}><option value="">Any</option>${opts.map(([v, l]) =>
      `<option value="${esc(v)}" ${String(value) === String(v) ? 'selected' : ''}>${esc(l)}</option>`).join('')}</select>`;
  }
  return `<input ${name} type="${f.type === 'number' ? 'number' : 'search'}" value="${esc(value ?? '')}">`;
}

async function list(resource, params) {
  const def = RESOURCES[resource];
  renderNav(resource);
  const filterParams = Object.fromEntries(Object.entries(params).filter(([k]) => !PAGING.includes(k)));
  const known = new Set(def.filters.map(f => f.name));
  const extra = Object.entries(filterParams).filter(([k]) => !known.has(k));
  main.innerHTML = `<div class="page-head"><div><h1>${esc(def.title)}</h1>
      ${extra.length ? `<div class="muted">Filtered by ${extra.map(([k, v]) => `${esc(k)} = ${esc(v)}`).join(', ')} · <a href="#/${resource}">clear</a></div>` : ''}</div>
      <a class="button primary" href="${href(resource, 'new', Object.fromEntries(extra))}">New ${esc(def.singular.toLowerCase())}</a></div>
    ${def.filters.length ? `<form class="card filters" id="filters">${(await Promise.all(def.filters.map(async f =>
      `<label>${esc(f.label)}${await filterInput(f, params[f.name])}</label>`))).join('')}
      <button class="primary">Filter</button><a class="button" href="#/${resource}">Reset</a></form>` : ''}
    <div class="card" id="results"></div>`;
  const form = document.getElementById('filters');
  if (form) {
    form.addEventListener('submit', e => {
      e.preventDefault();
      const values = Object.fromEntries(extra);
      for (const f of def.filters) values[f.name] = form.elements[f.name].value.trim();
      location.hash = href(resource, undefined, { ...values, sort: params.sort });
    });
  }
  await renderTable(document.getElementById('results'), resource, params, p => { location.hash = href(resource, undefined, p); });
}

async function detail(resource, id) {
  const def = RESOURCES[resource];
  renderNav(resource);
  main.innerHTML = '<p class="muted">Loading…</p>';
  let r;
  try {
    r = await api(`${resource}/${encodeURIComponent(id)}`);
  } catch (e) {
    main.innerHTML = `<div class="error">${esc(e.message)}</div><p><a href="#/${resource}">Back to ${esc(def.title.toLowerCase())}</a></p>`;
    return;
  }
  const shown = new Set();
  const rows = [];
  const allCols = [...def.columns, ...def.fields.map(f => col(f.name, f.label, f.type === 'json' ? { json: true } : {}))];
  for (const c of allCols) {
    if (shown.has(c.name) || c.name.endsWith('Id') && allCols.some(o => o.link?.idField === c.name)) continue;
    shown.add(c.name);
    const value = c.json && r[c.name] ? `<pre class="json">${esc(JSON.stringify(r[c.name], null, 2))}</pre>` : cell(c, r);
    rows.push(`<dt>${esc(c.label)}</dt><dd>${value}</dd>`);
  }
  const related = def.related ? def.related(r) : [];
  main.innerHTML = `<div class="page-head"><div><div class="crumbs"><a href="#/${resource}">${esc(def.title)}</a></div>
      <h1>${esc(def.label(r))}</h1></div>
      <div class="actions"><button type="button" id="edit">Edit</button><button type="button" class="danger" id="delete">Delete</button></div></div>
    <section class="card" id="record"><dl class="fields">${rows.join('')}</dl></section>
    ${related.map((rel, i) => `<section class="card"><div class="related-head"><h2>${esc(rel.title)}</h2>
      ${rel.add ? `<a class="button" href="${href(rel.resource, 'new', rel.add)}">Add</a>` : ''}</div><div id="related-${i}"></div></section>`).join('')}`;

  document.getElementById('edit').addEventListener('click', () => editForm(resource, r));
  const del = document.getElementById('delete');
  del.addEventListener('click', async () => {
    if (!del.classList.contains('confirm')) {
      del.classList.add('confirm');
      del.textContent = 'Confirm delete';
      setTimeout(() => { del.classList.remove('confirm'); del.textContent = 'Delete'; }, 4000);
      return;
    }
    try {
      await api(`${resource}/${encodeURIComponent(idOf(def, r))}`, { method: 'DELETE' });
      toast(`${def.singular} deleted`);
      location.hash = `#/${resource}`;
    } catch (e) {
      toast(e.message);
    }
  });
  related.forEach((rel, i) => {
    const container = document.getElementById(`related-${i}`);
    const show = params => renderTable(container, rel.resource, params, show);
    show({ ...rel.params, size: 10 });
  });
}

async function formInput(f, value, editing) {
  const attrs = `name="${esc(f.name)}" id="f-${esc(f.name)}" ${f.required ? 'required' : ''} ${editing && f.readonlyOnEdit ? 'readonly' : ''}`;
  if (f.type === 'checkbox') return `<input type="checkbox" ${attrs} ${value ? 'checked' : ''}>`;
  if (f.type === 'select') {
    const opts = await options(f).catch(() => []);
    return `<select ${attrs}><option value=""></option>${opts.map(([v, l]) =>
      `<option value="${esc(v)}" ${String(value ?? '') === String(v) ? 'selected' : ''}>${esc(l)}</option>`).join('')}</select>`;
  }
  if (f.type === 'json') return `<textarea ${attrs} rows="5">${esc(value ? JSON.stringify(value, null, 2) : '')}</textarea>`;
  const type = { date: 'date', number: 'number', ref: 'number' }[f.type] || 'text';
  return `<input type="${type}" ${type === 'number' ? 'step="any"' : ''} ${attrs} value="${esc(value ?? '')}">`;
}

// Shows the name of the record a reference field's id refers to, as it is typed
function watchRef(form, f) {
  const input = form.elements[f.name];
  const out = document.getElementById(`ref-${f.name}`);
  const lookup = async () => {
    const id = input.value.trim();
    if (!id) { out.textContent = `${RESOURCES[f.ref].singular} ID`; return; }
    try {
      const r = await api(`${f.ref}/${encodeURIComponent(id)}`);
      out.innerHTML = `<a href="${href(f.ref, id)}" target="_blank" rel="noopener">${esc(RESOURCES[f.ref].label(r))}</a>`;
    } catch {
      out.textContent = `No ${RESOURCES[f.ref].singular.toLowerCase()} with ID ${id}`;
    }
  };
  input.addEventListener('change', lookup);
  lookup();
}

function readForm(def, form) {
  const body = {};
  for (const f of def.fields) {
    const el = form.elements[f.name];
    if (f.type === 'checkbox') body[f.name] = el.checked;
    else if (f.type === 'json') body[f.name] = el.value.trim() ? JSON.parse(el.value) : null;
    else if (f.type === 'ref' || f.type === 'number') body[f.name] = el.value.trim() === '' ? null : Number(el.value);
    else body[f.name] = el.value.trim() === '' ? null : el.value.trim();
  }
  return body;
}

async function editForm(resource, record, prefill = {}) {
  const def = RESOURCES[resource];
  const editing = Boolean(record);
  const values = { ...(record || {}), ...prefill };
  renderNav(resource);
  const fields = await Promise.all(def.fields.map(async f => `<label class="${f.wide || f.type === 'json' ? 'wide' : ''}" for="f-${esc(f.name)}">
      ${esc(f.label)}${f.required ? ' *' : ''}${await formInput(f, values[f.name], editing)}
      ${f.type === 'ref' ? `<span class="hint" id="ref-${esc(f.name)}"></span>` : ''}${f.hint ? `<span class="hint">${esc(f.hint)}</span>` : ''}</label>`));
  const title = editing ? `Edit ${def.label(record)}` : `New ${def.singular.toLowerCase()}`;
  main.innerHTML = `<div class="page-head"><div><div class="crumbs"><a href="#/${resource}">${esc(def.title)}</a></div><h1>${esc(title)}</h1></div></div>
    <form class="card" id="edit-form" novalidate><div class="form-grid">${fields.join('')}</div>
      <div id="form-error"></div>
      <div class="actions"><button class="primary">${editing ? 'Save' : 'Create'}</button>
      <a class="button" href="${editing ? href(resource, idOf(def, record)) : '#/' + resource}" id="cancel">Cancel</a></div></form>`;
  const form = document.getElementById('edit-form');
  def.fields.filter(f => f.type === 'ref').forEach(f => watchRef(form, f));
  if (editing) document.getElementById('cancel').addEventListener('click', e => { e.preventDefault(); route(); });
  form.addEventListener('submit', async e => {
    e.preventDefault();
    const error = document.getElementById('form-error');
    error.innerHTML = '';
    if (!form.reportValidity()) return;
    let body;
    try {
      body = readForm(def, form);
    } catch {
      error.innerHTML = '<div class="error">Details must be valid JSON</div>';
      return;
    }
    try {
      const saved = editing
        ? await api(`${resource}/${encodeURIComponent(idOf(def, record))}`, { method: 'PUT', body: JSON.stringify({ ...record, ...body }) })
        : await api(resource, { method: 'POST', body: JSON.stringify(body) });
      toast(`${def.singular} ${editing ? 'saved' : 'created'}`);
      const target = href(resource, idOf(def, saved));
      if (location.hash === target) route(); else location.hash = target;
    } catch (err) {
      error.innerHTML = `<div class="error" style="margin-bottom:12px">${esc(err.message)}</div>`;
    }
  });
  form.elements[0]?.focus();
}

// --- Router

function route() {
  const [path, query = ''] = location.hash.replace(/^#\/?/, '').split('?');
  const params = Object.fromEntries(new URLSearchParams(query));
  const [resource, id] = path.split('/').map(decodeURIComponent);
  document.getElementById('nav').classList.remove('open');
  window.scrollTo(0, 0);
  if (!resource) return dashboard();
  if (!RESOURCES[resource]) {
    main.innerHTML = '<div class="error">Page not found</div>';
    return;
  }
  document.title = `${RESOURCES[resource].title} · Voter Register`;
  if (id === 'new') return editForm(resource, null, params);
  if (id) return detail(resource, id);
  return list(resource, params);
}

window.addEventListener('hashchange', route);
route();
