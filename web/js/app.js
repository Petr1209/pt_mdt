// State management
const State = {
    officer: null,
    locales: {},
    penalCode: [],
    currentTab: 'dashboard',
    selectedCitizen: null,
    selectedVehicle: null,
    incidentDraftCharges: [],
    incidentDraftSuspects: []
};

// Helper pro NUI volání
async function postNUI(callbackName, data = {}) {
    try {
        const response = await fetch(`https://pt_mdt/${callbackName}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify(data)
        });
        return await response.json();
    } catch (e) {
        // Mock fallback pro testování v běžném prohlížeči mimo FiveM
        console.warn(`[NUI Mock] Volání '${callbackName}':`, data);
        return null;
    }
}

// Lokalizace rozhraní
function applyLocales() {
    if (!State.locales) return;
    document.querySelectorAll('[data-i18n]').forEach(el => {
        const key = el.getAttribute('data-i18n');
        if (State.locales[key]) {
            if (el.tagName === 'INPUT' || el.tagName === 'TEXTAREA') {
                el.placeholder = State.locales[key];
            } else {
                el.textContent = State.locales[key];
            }
        }
    });
}

function t(key, fallback = '') {
    return State.locales[key] || fallback || key;
}

// Přepínání záložek
function switchTab(tabName) {
    State.currentTab = tabName;
    document.querySelectorAll('.nav-item').forEach(item => {
        item.classList.toggle('active', item.getAttribute('data-tab') === tabName);
    });
    document.querySelectorAll('.tab-view').forEach(view => {
        view.classList.toggle('active', view.id === `tab-${tabName}`);
    });

    // Načtení dat podle vybraného tabu
    if (tabName === 'incidents') loadIncidents();
    if (tabName === 'warrants') loadWarrants();
    if (tabName === 'bolo') loadBolos();
    if (tabName === 'penalcode') renderPenalCode();
    if (tabName === 'dispatch') loadDispatch();
}

// Otevření a zavření MDT
function openMDT(data) {
    State.officer = data.officer;
    State.locales = data.locales || {};
    State.penalCode = data.penalCode || [];

    // Nastavení hlavičky
    document.getElementById('badge-code').textContent = State.officer.badge || 'LSPD';
    document.getElementById('badge-label').textContent = State.officer.jobLabel || 'POLICE DEPARTMENT';
    document.getElementById('officer-name').textContent = State.officer.name;
    document.getElementById('officer-rank').textContent = State.officer.grade;

    // Statistiky
    document.getElementById('stat-officers').textContent = data.activeOfficers || 1;
    document.getElementById('stat-warrants').textContent = data.warrantCount || 0;
    document.getElementById('stat-bolos').textContent = data.boloCount || 0;
    document.getElementById('stat-incidents').textContent = data.incidentCount || 0;

    applyLocales();
    renderBulletins(data.bulletins || []);
    renderRecentIncidents(data.recentIncidents || []);
    populatePenalCodeSelect();

    document.body.style.display = 'block';
    switchTab('dashboard');
}

function closeMDT() {
    document.body.style.display = 'none';
    closeAllModals();
    postNUI('close');
}

// Listeners pro FiveM NUI
window.addEventListener('message', (event) => {
    const item = event.data;
    if (item.action === 'open') {
        openMDT(item.data);
    } else if (item.action === 'close') {
        document.body.style.display = 'none';
        closeAllModals();
    }
});

window.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        closeMDT();
    }
});

// Modals management
function openModal(modalId) {
    const modal = document.getElementById(modalId);
    if (modal) modal.style.display = 'flex';
}

function closeAllModals() {
    document.querySelectorAll('.modal-overlay').forEach(modal => {
        modal.style.display = 'none';
    });
}

document.querySelectorAll('.modal-close').forEach(btn => {
    btn.addEventListener('click', closeAllModals);
});

// ==========================================
// 1. DASHBOARD
// ==========================================
function renderBulletins(bulletins) {
    const list = document.getElementById('bulletin-list');
    list.innerHTML = '';
    if (!bulletins || bulletins.length === 0) {
        list.innerHTML = `<div style="color: var(--text-muted); padding: 12px;">${t('no_results')}</div>`;
        return;
    }

    bulletins.forEach(b => {
        const item = document.createElement('div');
        item.className = 'list-item';
        item.style.flexDirection = 'column';
        item.style.alignItems = 'flex-start';
        item.style.gap = '6px';
        item.innerHTML = `
            <div style="display: flex; justify-content: space-between; width: 100%; align-items: center;">
                <div style="font-weight: 700; color: var(--text-primary); font-size: 15px;">
                    ${b.pinned ? '<span class="tag-badge amber">PŘIPNUTÉ</span> ' : ''}${escapeHtml(b.title)}
                </div>
                <div style="font-size: 11px; color: var(--text-muted);">${escapeHtml(b.author)} • ${new Date(b.created_at).toLocaleDateString()}</div>
            </div>
            <div style="color: var(--text-secondary); font-size: 13px; line-height: 1.4;">${escapeHtml(b.message)}</div>
        `;
        list.appendChild(item);
    });
}

function renderRecentIncidents(incidents) {
    const list = document.getElementById('dashboard-recent-incidents');
    list.innerHTML = '';
    if (!incidents || incidents.length === 0) {
        list.innerHTML = `<div style="color: var(--text-muted); padding: 12px;">${t('no_results')}</div>`;
        return;
    }

    incidents.forEach(inc => {
        const item = document.createElement('div');
        item.className = 'list-item';
        item.innerHTML = `
            <div>
                <div style="font-weight: 600; color: var(--text-primary);">${escapeHtml(inc.title)}</div>
                <div style="font-size: 12px; color: var(--text-muted);">${escapeHtml(inc.creator_name)}</div>
            </div>
            <span class="tag-badge blue">#${inc.id}</span>
        `;
        item.addEventListener('click', () => {
            switchTab('incidents');
            loadIncidentDetails(inc.id);
        });
        list.appendChild(item);
    });
}

// ==========================================
// 2. CITIZENS (OBČANÉ)
// ==========================================
document.getElementById('btn-citizen-search').addEventListener('click', async () => {
    const query = document.getElementById('citizen-search-input').value.trim();
    if (!query) return;

    const results = await postNUI('searchCitizens', { query });
    renderCitizenSearchResults(results || []);
});

function renderCitizenSearchResults(results) {
    const list = document.getElementById('citizen-search-results');
    list.innerHTML = '';
    document.getElementById('citizen-detail-section').style.display = 'none';

    if (results.length === 0) {
        list.innerHTML = `<div style="color: var(--text-muted); padding: 12px;">${t('no_results')}</div>`;
        return;
    }

    results.forEach(c => {
        const item = document.createElement('div');
        item.className = 'list-item';
        item.innerHTML = `
            <div style="display: flex; align-items: center; gap: 12px;">
                <div style="width: 38px; height: 38px; border-radius: 50%; overflow: hidden; background: #283548;">
                    <img src="${c.avatar_url || 'img/default_avatar.svg'}" style="width: 100%; height: 100%; object-fit: cover;">
                </div>
                <div>
                    <div style="font-weight: 600; color: var(--text-primary);">${escapeHtml(c.firstname)} ${escapeHtml(c.lastname)}</div>
                    <div style="font-size: 12px; color: var(--text-secondary);">DOB: ${c.dateofbirth || '-'} • Tel: ${c.phone_number || '-'}</div>
                </div>
            </div>
            <button class="btn-primary" style="padding: 6px 12px; font-size: 12px;">Zobrazit kartu</button>
        `;
        item.addEventListener('click', () => loadCitizenProfile(c.identifier));
        list.appendChild(item);
    });
}

async function loadCitizenProfile(identifier) {
    const data = await postNUI('getCitizenProfile', { identifier });
    if (!data || !data.profile) return;

    State.selectedCitizen = data;
    const p = data.profile;

    document.getElementById('citizen-detail-section').style.display = 'grid';
    document.getElementById('citizen-fullname').textContent = `${p.firstname} ${p.lastname}`;
    document.getElementById('citizen-id-badge').textContent = `ID: ${p.identifier.substring(0, 16)}...`;
    document.getElementById('citizen-avatar').src = p.avatar_url || 'img/default_avatar.svg';
    document.getElementById('citizen-edit-avatar').value = p.avatar_url || '';
    document.getElementById('citizen-edit-notes').value = p.notes || '';

    document.getElementById('c-dob').textContent = p.dateofbirth || '-';
    document.getElementById('c-gender').textContent = p.sex === 'm' ? t('male', 'Muž') : t('female', 'Žena');
    document.getElementById('c-height').textContent = p.height ? `${p.height} cm` : '-';
    document.getElementById('c-job').textContent = `${p.job_label || p.job} (${p.grade_label || p.job_grade})`;
    document.getElementById('c-phone').textContent = p.phone_number || '-';

    // Licence
    const licContainer = document.getElementById('citizen-licenses-list');
    licContainer.innerHTML = '';
    if (data.licenses && data.licenses.length > 0) {
        data.licenses.forEach(l => {
            licContainer.innerHTML += `<span class="tag-badge green">${escapeHtml(l.label || l.type)}</span>`;
        });
    } else {
        licContainer.innerHTML = `<span style="color: var(--text-muted); font-size: 13px;">Žádné evidované licence</span>`;
    }

    // Trestní rejstřík
    const convList = document.getElementById('citizen-convictions-list');
    convList.innerHTML = '';
    if (data.convictions && data.convictions.length > 0) {
        data.convictions.forEach(c => {
            convList.innerHTML += `
                <div class="list-item" style="padding: 8px 12px; font-size: 13px;">
                    <div>
                        <strong style="color: var(--text-primary);">${escapeHtml(c.charge_name)}</strong>
                        <div style="font-size: 11px; color: var(--text-muted);">${c.officer_name} • ${new Date(c.created_at).toLocaleDateString()}</div>
                    </div>
                    <div style="text-align: right;">
                        <span style="color: var(--accent-green); font-weight: 600;">$${c.fine}</span>
                        ${c.prison > 0 ? `<span style="color: var(--accent-red); margin-left: 8px;">${c.prison} m</span>` : ''}
                    </div>
                </div>
            `;
        });
    } else {
        convList.innerHTML = `<span style="color: var(--text-muted); font-size: 13px; padding: 6px;">Čistý trestní rejstřík</span>`;
    }
}

document.getElementById('btn-save-citizen').addEventListener('click', async () => {
    if (!State.selectedCitizen) return;
    const identifier = State.selectedCitizen.profile.identifier;
    const avatar_url = document.getElementById('citizen-edit-avatar').value.trim();
    const notes = document.getElementById('citizen-edit-notes').value.trim();

    const success = await postNUI('saveCitizenProfile', { identifier, avatar_url, notes });
    if (success) {
        document.getElementById('citizen-avatar').src = avatar_url || 'img/default_avatar.svg';
        alert(t('saved_success', 'Úspěšně uloženo!'));
    }
});

// ==========================================
// 3. VEHICLES (VOZIDLA)
// ==========================================
document.getElementById('btn-vehicle-search').addEventListener('click', async () => {
    const query = document.getElementById('vehicle-search-input').value.trim();
    if (!query) return;

    const results = await postNUI('searchVehicles', { query });
    renderVehicleSearchResults(results || []);
});

function renderVehicleSearchResults(results) {
    const list = document.getElementById('vehicle-search-results');
    list.innerHTML = '';
    document.getElementById('vehicle-detail-section').style.display = 'none';

    if (results.length === 0) {
        list.innerHTML = `<div style="color: var(--text-muted); padding: 12px;">${t('no_results')}</div>`;
        return;
    }

    results.forEach(v => {
        const item = document.createElement('div');
        item.className = 'list-item';
        item.innerHTML = `
            <div>
                <div style="font-weight: 700; color: var(--text-primary); letter-spacing: 1px;">${escapeHtml(v.plate)}</div>
                <div style="font-size: 12px; color: var(--text-secondary);">${v.owner_name || t('unknown')}</div>
            </div>
            <div>
                ${v.stolen ? '<span class="tag-badge red">ODCIZENÉ</span>' : '<span class="tag-badge green">PLATNÉ</span>'}
            </div>
        `;
        item.addEventListener('click', () => loadVehicleProfile(v.plate));
        list.appendChild(item);
    });
}

async function loadVehicleProfile(plate) {
    const data = await postNUI('getVehicleProfile', { plate });
    if (!data || !data.vehicle) return;

    State.selectedVehicle = data.vehicle;
    const v = data.vehicle;

    document.getElementById('vehicle-detail-section').style.display = 'block';
    document.getElementById('v-plate-title').textContent = `Vozidlo: ${v.plate}`;
    document.getElementById('v-plate').textContent = v.plate;
    document.getElementById('v-owner').textContent = v.owner_name || t('unknown');
    document.getElementById('v-stolen-status').textContent = v.stolen ? t('stolen') : t('not_stolen');
    document.getElementById('v-toggle-stolen').checked = !!v.stolen;
    document.getElementById('v-notes').value = v.notes || '';

    const badge = document.getElementById('v-status-badge');
    badge.innerHTML = v.stolen 
        ? '<span class="tag-badge red">PÁTRÁNÍ - ODCIZENÉ VOZIDLO</span>' 
        : '<span class="tag-badge green">ČISTÝ ZÁZNAM</span>';

    // Klik na majitele otevře občana
    document.getElementById('v-owner').onclick = () => {
        if (v.owner) {
            switchTab('citizens');
            loadCitizenProfile(v.owner);
        }
    };
}

document.getElementById('btn-save-vehicle').addEventListener('click', async () => {
    if (!State.selectedVehicle) return;
    const plate = State.selectedVehicle.plate;
    const stolen = document.getElementById('v-toggle-stolen').checked;
    const notes = document.getElementById('v-notes').value.trim();

    const success = await postNUI('saveVehicleStatus', { plate, stolen, notes });
    if (success) {
        alert(t('saved_success', 'Uloženo!'));
        loadVehicleProfile(plate);
    }
});

// ==========================================
// 4. INCIDENTS (INCIDENTY)
// ==========================================
async function loadIncidents() {
    const query = document.getElementById('incidents-search-input').value.trim();
    const incidents = await postNUI('getIncidents', { query });
    const list = document.getElementById('incidents-list');
    list.innerHTML = '';

    if (!incidents || incidents.length === 0) {
        list.innerHTML = `<div style="color: var(--text-muted); padding: 12px;">${t('no_results')}</div>`;
        return;
    }

    incidents.forEach(inc => {
        const item = document.createElement('div');
        item.className = 'list-item';
        item.innerHTML = `
            <div>
                <div style="font-weight: 600; color: var(--text-primary); font-size: 15px;">#${inc.id} - ${escapeHtml(inc.title)}</div>
                <div style="font-size: 12px; color: var(--text-muted);">Založil: ${escapeHtml(inc.creator_name)} • ${new Date(inc.created_at).toLocaleDateString()}</div>
            </div>
            <button class="btn-secondary" style="font-size: 12px; padding: 6px 12px;">Zobrazit spis</button>
        `;
        item.addEventListener('click', () => loadIncidentDetails(inc.id));
        list.appendChild(item);
    });
}

document.getElementById('incidents-search-input').addEventListener('input', loadIncidents);

async function loadIncidentDetails(id) {
    const inc = await postNUI('getIncidentDetails', { id });
    if (!inc) return;

    alert(`Incident #${inc.id}: ${inc.title}\n\nPopis:\n${inc.description}\n\nDůstojník: ${inc.creator_name}`);
}

document.getElementById('btn-open-new-incident').addEventListener('click', () => {
    State.incidentDraftCharges = [];
    State.incidentDraftSuspects = [];
    document.getElementById('inc-title').value = '';
    document.getElementById('inc-desc').value = '';
    document.getElementById('inc-suspect-search').value = '';
    renderDraftSuspects();
    renderDraftCharges();
    openModal('modal-incident');
});

function populatePenalCodeSelect() {
    const select = document.getElementById('inc-charge-select');
    select.innerHTML = '';
    State.penalCode.forEach(cat => {
        const optgroup = document.createElement('optgroup');
        optgroup.label = cat.category;
        cat.items.forEach(item => {
            const opt = document.createElement('option');
            opt.value = item.id;
            opt.textContent = `${item.title} ($${item.fine} | ${item.prison}m)`;
            optgroup.appendChild(opt);
        });
        select.appendChild(optgroup);
    });
}

document.getElementById('btn-add-charge').addEventListener('click', () => {
    const selectedId = document.getElementById('inc-charge-select').value;
    for (const cat of State.penalCode) {
        const found = cat.items.find(i => i.id === selectedId);
        if (found) {
            State.incidentDraftCharges.push(found);
            break;
        }
    }
    renderDraftCharges();
});

function renderDraftCharges() {
    const container = document.getElementById('inc-charges-tags');
    container.innerHTML = '';
    let totalFine = 0;
    let totalPrison = 0;

    State.incidentDraftCharges.forEach((c, idx) => {
        totalFine += c.fine || 0;
        totalPrison += c.prison || 0;

        const chip = document.createElement('span');
        chip.className = 'tag-badge blue';
        chip.style.display = 'inline-flex';
        chip.style.alignItems = 'center';
        chip.style.gap = '6px';
        chip.style.cursor = 'pointer';
        chip.innerHTML = `${escapeHtml(c.title)} ($${c.fine}) &times;`;
        chip.addEventListener('click', () => {
            State.incidentDraftCharges.splice(idx, 1);
            renderDraftCharges();
        });
        container.appendChild(chip);
    });

    document.getElementById('inc-total-fine').textContent = `$${totalFine.toLocaleString()}`;
    document.getElementById('inc-total-prison').textContent = `${totalPrison} měsíců`;
}

document.getElementById('btn-add-suspect').addEventListener('click', () => {
    const name = document.getElementById('inc-suspect-search').value.trim();
    if (!name) return;
    State.incidentDraftSuspects.push({ name: name, identifier: '' });
    document.getElementById('inc-suspect-search').value = '';
    renderDraftSuspects();
});

function renderDraftSuspects() {
    const list = document.getElementById('inc-suspects-list');
    list.innerHTML = '';
    State.incidentDraftSuspects.forEach((s, idx) => {
        list.innerHTML += `
            <div style="display: flex; justify-content: space-between; align-items: center; background: #111827; padding: 6px 12px; border-radius: 4px; margin-top: 4px;">
                <span style="color: var(--text-primary); font-size: 13px;">${escapeHtml(s.name)}</span>
                <span style="color: var(--accent-red); cursor: pointer;" onclick="removeSuspect(${idx})">&times;</span>
            </div>
        `;
    });
}

window.removeSuspect = function(idx) {
    State.incidentDraftSuspects.splice(idx, 1);
    renderDraftSuspects();
};

document.getElementById('btn-save-incident').addEventListener('click', async () => {
    const title = document.getElementById('inc-title').value.trim();
    const description = document.getElementById('inc-desc').value.trim();
    if (!title) {
        alert('Vyplňte prosím název incidentu!');
        return;
    }

    const suspects = State.incidentDraftSuspects.map(s => ({
        name: s.name,
        identifier: s.identifier,
        charges: State.incidentDraftCharges
    }));

    const result = await postNUI('createIncident', {
        title,
        description,
        suspects,
        officers: [State.officer.name]
    });

    if (result) {
        closeAllModals();
        loadIncidents();
        alert('Incident byl úspěšně zaevidován!');
    }
});

// ==========================================
// 5. WARRANTS (ZATYKAČE)
// ==========================================
async function loadWarrants() {
    const warrants = await postNUI('getWarrants', { status: 'active' });
    const list = document.getElementById('warrants-list');
    list.innerHTML = '';

    if (!warrants || warrants.length === 0) {
        list.innerHTML = `<div style="color: var(--text-muted); padding: 12px;">${t('no_results')}</div>`;
        return;
    }

    warrants.forEach(w => {
        const item = document.createElement('div');
        item.className = 'list-item';
        item.innerHTML = `
            <div>
                <div style="font-weight: 700; color: var(--accent-red); font-size: 15px;">ZATYKAČ: ${escapeHtml(w.suspect_name)}</div>
                <div style="font-size: 13px; color: var(--text-secondary); margin-top: 4px;">${escapeHtml(w.reason)}</div>
                <div style="font-size: 11px; color: var(--text-muted); margin-top: 4px;">Vydal: ${escapeHtml(w.creator_name)} • ${new Date(w.created_at).toLocaleDateString()}</div>
            </div>
            <button class="btn-primary" style="font-size: 12px; background: var(--accent-green);">Uzavřít / Zadržen</button>
        `;
        item.querySelector('button').addEventListener('click', async (e) => {
            e.stopPropagation();
            await postNUI('updateWarrantStatus', { id: w.id, status: 'closed' });
            loadWarrants();
        });
        list.appendChild(item);
    });
}

document.getElementById('btn-open-new-warrant').addEventListener('click', () => {
    document.getElementById('w-suspect-name').value = '';
    document.getElementById('w-reason').value = '';
    openModal('modal-warrant');
});

document.getElementById('btn-save-warrant').addEventListener('click', async () => {
    const suspect_name = document.getElementById('w-suspect-name').value.trim();
    const reason = document.getElementById('w-reason').value.trim();
    if (!suspect_name || !reason) return;

    const success = await postNUI('createWarrant', { suspect_name, reason });
    if (success) {
        closeAllModals();
        loadWarrants();
    }
});

// ==========================================
// 6. BOLO (PÁTRÁNÍ)
// ==========================================
async function loadBolos() {
    const bolos = await postNUI('getBolos');
    const list = document.getElementById('bolo-list');
    list.innerHTML = '';

    if (!bolos || bolos.length === 0) {
        list.innerHTML = `<div style="color: var(--text-muted); padding: 12px;">${t('no_results')}</div>`;
        return;
    }

    bolos.forEach(b => {
        const item = document.createElement('div');
        item.className = 'list-item';
        item.style.borderLeft = '4px solid var(--accent-amber)';
        item.innerHTML = `
            <div>
                <div style="display: flex; gap: 8px; align-items: center;">
                    <span class="tag-badge ${b.type === 'vehicle' ? 'blue' : 'amber'}">${b.type.toUpperCase()}</span>
                    <strong style="color: var(--text-primary); font-size: 15px;">${escapeHtml(b.title)}</strong>
                    ${b.plate ? `<span class="tag-badge red">SPZ: ${escapeHtml(b.plate)}</span>` : ''}
                </div>
                <div style="font-size: 13px; color: var(--text-secondary); margin-top: 6px;">${escapeHtml(b.description)}</div>
                <div style="font-size: 11px; color: var(--text-muted); margin-top: 4px;">Vyhlásil: ${escapeHtml(b.creator_name)} • ${new Date(b.created_at).toLocaleDateString()}</div>
            </div>
            <button class="btn-danger" style="font-size: 12px;">Odvolat BOLO</button>
        `;
        item.querySelector('button').addEventListener('click', async (e) => {
            e.stopPropagation();
            await postNUI('deleteBolo', { id: b.id });
            loadBolos();
        });
        list.appendChild(item);
    });
}

document.getElementById('bolo-type-select').addEventListener('change', (e) => {
    const isVehicle = e.target.value === 'vehicle';
    document.getElementById('bolo-plate-group').style.display = isVehicle ? 'flex' : 'none';
    document.getElementById('bolo-person-group').style.display = isVehicle ? 'none' : 'flex';
});

document.getElementById('btn-open-new-bolo').addEventListener('click', () => {
    document.getElementById('bolo-title').value = '';
    document.getElementById('bolo-plate').value = '';
    document.getElementById('bolo-person').value = '';
    document.getElementById('bolo-desc').value = '';
    openModal('modal-bolo');
});

document.getElementById('btn-save-bolo').addEventListener('click', async () => {
    const type = document.getElementById('bolo-type-select').value;
    const title = document.getElementById('bolo-title').value.trim();
    const plate = document.getElementById('bolo-plate').value.trim();
    const suspect_name = document.getElementById('bolo-person').value.trim();
    const description = document.getElementById('bolo-desc').value.trim();

    if (!title || !description) return;

    const success = await postNUI('createBolo', { type, title, plate, suspect_name, description });
    if (success) {
        closeAllModals();
        loadBolos();
    }
});

// ==========================================
// 7. PENAL CODE (SAZEBNÍK)
// ==========================================
function renderPenalCode() {
    const container = document.getElementById('penal-code-container');
    container.innerHTML = '';
    const searchFilter = document.getElementById('penal-search').value.toLowerCase();

    State.penalCode.forEach(cat => {
        const filteredItems = cat.items.filter(i => 
            i.title.toLowerCase().includes(searchFilter) || 
            cat.category.toLowerCase().includes(searchFilter)
        );

        if (filteredItems.length === 0) return;

        const card = document.createElement('div');
        card.className = 'panel-card';
        let itemsHtml = '';
        filteredItems.forEach(i => {
            itemsHtml += `
                <div class="list-item" style="padding: 10px 14px;">
                    <div>
                        <div style="font-weight: 600; color: var(--text-primary); font-size: 14px;">${escapeHtml(i.title)}</div>
                    </div>
                    <div style="display: flex; gap: 14px; align-items: center;">
                        <span style="color: var(--accent-green); font-weight: 700; font-size: 14px;">$${i.fine.toLocaleString()}</span>
                        <span class="tag-badge ${i.prison > 0 ? 'red' : 'blue'}">${i.prison > 0 ? `${i.prison} měsíců` : 'Bez trestu'}</span>
                    </div>
                </div>
            `;
        });

        card.innerHTML = `
            <div class="panel-header">
                <h2>${escapeHtml(cat.category)}</h2>
            </div>
            <div class="item-list">${itemsHtml}</div>
        `;
        container.appendChild(card);
    });
}

document.getElementById('penal-search').addEventListener('input', renderPenalCode);

// ==========================================
// 8. DISPATCH (DISPEČINK)
// ==========================================
async function loadDispatch() {
    const calls = await postNUI('getDispatchCalls');
    const list = document.getElementById('dispatch-list');
    list.innerHTML = '';

    if (!calls || calls.length === 0) {
        list.innerHTML = `<div style="color: var(--text-muted); padding: 12px;">Žádná aktivní tísňová volání.</div>`;
        return;
    }

    calls.forEach(c => {
        const item = document.createElement('div');
        item.className = 'list-item';
        item.innerHTML = `
            <div>
                <div style="display: flex; gap: 8px; align-items: center;">
                    <span class="tag-badge red">${escapeHtml(c.code)}</span>
                    <strong style="color: var(--text-primary);">${escapeHtml(c.title)}</strong>
                    <span style="font-size: 12px; color: var(--text-muted);">${c.time}</span>
                </div>
                <div style="font-size: 13px; color: var(--text-secondary); margin-top: 4px;">${escapeHtml(c.message)}</div>
                <div style="font-size: 11px; color: var(--text-muted); margin-top: 2px;">Volající: ${escapeHtml(c.caller)}</div>
            </div>
            <button class="btn-primary" style="font-size: 12px;">${t('set_waypoint', 'GPS Cíl')}</button>
        `;
        item.querySelector('button').addEventListener('click', () => {
            postNUI('setWaypoint', { x: c.coords.x, y: c.coords.y });
        });
        list.appendChild(item);
    });
}

// Nástěnka - přidání
document.getElementById('btn-add-bulletin').addEventListener('click', () => {
    document.getElementById('b-title').value = '';
    document.getElementById('b-message').value = '';
    document.getElementById('b-pinned').checked = false;
    openModal('modal-bulletin');
});

document.getElementById('btn-save-bulletin').addEventListener('click', async () => {
    const title = document.getElementById('b-title').value.trim();
    const message = document.getElementById('b-message').value.trim();
    const pinned = document.getElementById('b-pinned').checked;
    if (!title || !message) return;

    const success = await postNUI('addBulletin', { title, message, pinned });
    if (success) {
        closeAllModals();
        // Znovu načteme dashboard data
        const initial = await postNUI('getInitialData');
        if (initial && initial.bulletins) renderBulletins(initial.bulletins);
    }
});

// Tlačítko zavřít
document.getElementById('btn-close-mdt').addEventListener('click', closeMDT);

// Navigace tabs listeners
document.querySelectorAll('.nav-item').forEach(item => {
    item.addEventListener('click', () => {
        const tab = item.getAttribute('data-tab');
        switchTab(tab);
    });
});

// Helper XSS ochrana
function escapeHtml(text) {
    if (!text) return '';
    return String(text)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#039;');
}
