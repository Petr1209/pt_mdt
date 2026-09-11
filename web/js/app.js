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

    if (tabName === 'map') {
        startTacticalMapPolling();
    } else {
        stopTacticalMapPolling();
    }

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

    if (data.bootTime) {
        checkServerBoot(data.bootTime);
    }

    applyLocales();
    renderBulletins(data.bulletins || []);
    renderRecentIncidents(data.recentIncidents || []);
    populatePenalCodeSelect();

    const tabletWrapper = document.querySelector('.tablet-wrapper');
    if (tabletWrapper) {
        tabletWrapper.style.display = 'flex';
        tabletWrapper.classList.add('open');
    }
    switchTab('dashboard');
}

function closeMDT() {
    const tabletWrapper = document.querySelector('.tablet-wrapper');
    if (tabletWrapper) {
        tabletWrapper.style.display = 'none';
        tabletWrapper.classList.remove('open');
    }
    stopTacticalMapPolling();
    closeAllModals();
    postNUI('close');
}

// Listeners pro FiveM NUI
window.addEventListener('message', (event) => {
    const item = event.data;
    if (item.action === 'open') {
        openMDT(item.data);
    } else if (item.action === 'initSession') {
        checkServerBoot(item.bootTime);
    } else if (item.action === 'resetRadarPosition') {
        resetRadarPosition();
    } else if (item.action === 'close') {
        const tabletWrapper = document.querySelector('.tablet-wrapper');
        if (tabletWrapper) {
            tabletWrapper.style.display = 'none';
            tabletWrapper.classList.remove('open');
        }
        stopTacticalMapPolling();
        closeAllModals();
    } else if (item.action === 'toggleRadar') {
        const radar = document.getElementById('police-radar-hud');
        if (radar) {
            if (item.show) {
                radar.classList.add('active');
            } else {
                radar.classList.remove('active');
            }
        }
    } else if (item.action === 'updateRadar') {
        updateRadarDisplay(item.data);
    } else if (item.action === 'lockRadar') {
        applyRadarLock(item.locked, item.lockedData);
    } else if (item.action === 'setRadarEditMode') {
        setRadarEditMode(item.editing);
    }
});

window.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        const radar = document.getElementById('police-radar-hud');
        if (radar && radar.classList.contains('editing')) {
            setRadarEditMode(false);
            postNUI('saveRadarPosition');
            return;
        }
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
            <button class="btn-primary" style="padding: 6px 12px; font-size: 12px;">${t('view_card', 'Zobrazit kartu')}</button>
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

    // Licence (s možností odebrání)
    const licContainer = document.getElementById('citizen-licenses-list');
    licContainer.innerHTML = '';
    if (data.licenses && data.licenses.length > 0) {
        data.licenses.forEach(l => {
            const badge = document.createElement('div');
            badge.className = 'tag-badge green';
            badge.style.display = 'inline-flex';
            badge.style.alignItems = 'center';
            badge.style.gap = '6px';
            badge.innerHTML = `
                <span>${escapeHtml(l.label || l.type)}</span>
                <span class="revoke-lic-btn" style="cursor: pointer; opacity: 0.75; font-weight: bold; padding: 0 3px;" title="${t('revoke_license', 'Odebrat')}">✕</span>
            `;
            badge.querySelector('.revoke-lic-btn').addEventListener('click', async (e) => {
                e.stopPropagation();
                const ok = await postNUI('removeLicense', { identifier: p.identifier, type: l.type });
                if (ok) {
                    loadCitizenProfile(p.identifier);
                }
            });
            licContainer.appendChild(badge);
        });
    } else {
        licContainer.innerHTML = `<span style="color: var(--text-muted); font-size: 13px;">${t('no_licenses', 'Žádné evidované licence')}</span>`;
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
        convList.innerHTML = `<span style="color: var(--text-muted); font-size: 13px; padding: 6px;">${t('clean_record', 'Čistý trestní rejstřík')}</span>`;
    }
}

// Otevření a potvrzení přidání licence
const btnOpenAddLic = document.getElementById('btn-open-add-license');
if (btnOpenAddLic) {
    btnOpenAddLic.addEventListener('click', () => {
        if (!State.selectedCitizen || !State.selectedCitizen.profile) return;
        openModal('modal-add-license');
    });
}

const btnConfirmAddLic = document.getElementById('btn-confirm-add-license');
if (btnConfirmAddLic) {
    btnConfirmAddLic.addEventListener('click', async () => {
        if (!State.selectedCitizen || !State.selectedCitizen.profile) return;
        const identifier = State.selectedCitizen.profile.identifier;
        const type = document.getElementById('license-type-select').value;
        const success = await postNUI('addLicense', { identifier, type });
        if (success) {
            closeAllModals();
            loadCitizenProfile(identifier);
        }
    });
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
                        <span class="tag-badge ${i.prison > 0 ? 'red' : 'blue'}">${i.prison > 0 ? `${i.prison} ${t('months', 'měsíců')}` : t('no_jail', 'Bez trestu')}</span>
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
        list.innerHTML = `<div style="color: var(--text-muted); padding: 12px;">${t('no_dispatch_calls', 'Žádná aktivní tísňová volání.')}</div>`;
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
                <div style="font-size: 11px; color: var(--text-muted); margin-top: 2px;">${t('caller', 'Volající')}: ${escapeHtml(c.caller)}</div>
            </div>
            <button class="btn-primary" style="font-size: 12px;">${t('set_waypoint', 'GPS Cíl')}</button>
        `;
        item.querySelector('button').addEventListener('click', () => {
            postNUI('setWaypoint', { x: c.coords.x, y: c.coords.y });
        });
        list.appendChild(item);
    });
}

// ==========================================
// 9. TACTICAL LIVE GPS MAP (LEAFLET HD)
// ==========================================
let leafletMap = null;
let leafletMarkers = new Map();
let mapInitialized = false;
let mapPollingInterval = null;
let currentMapFilter = 'all';

const CALIB_SX = 0.995209;
const CALIB_SY = 1.003941;
const CALIB_OX = 2.47;
const CALIB_OY = 7.61;

function toMapLatLng(coords) {
    const x = coords.x || 0;
    const y = coords.y || 0;
    return [CALIB_SY * y + CALIB_OY, CALIB_SX * x + CALIB_OX];
}

function getCustomCRS() {
    const zoomNumb = 0.6931471805599453;
    return L.extend({}, L.CRS.Simple, {
        projection: L.Projection.LonLat,
        scale: (zoom) => Math.pow(2, zoom),
        zoom: (sc) => Math.log(sc) / zoomNumb,
        distance: (pos1, pos2) => {
            const dx = pos2.lng - pos1.lng;
            const dy = pos2.lat - pos1.lat;
            return Math.sqrt(dx * dx + dy * dy);
        },
        transformation: new L.Transformation(0.02072, 117.3, -0.0205, 172.8),
        infinite: false,
    });
}

function initLeafletMap() {
    if (mapInitialized && leafletMap) {
        setTimeout(() => leafletMap.invalidateSize(), 80);
        return;
    }
    const container = document.getElementById('leaflet-map');
    if (!container) return;

    mapInitialized = true;
    leafletMap = L.map(container, {
        crs: getCustomCRS(),
        minZoom: 1.5,
        maxZoom: 6,
        zoom: 2.7,
        center: [-1500, 200],
        zoomControl: true,
        attributionControl: false
    });

    const sw = leafletMap.unproject([0, 1024], 2);
    const ne = leafletMap.unproject([1024, 0], 2);
    const bounds = new L.LatLngBounds(sw, ne);

    L.imageOverlay('img/gtav_map.jpg', bounds).addTo(leafletMap);

    // Rychlá navigační tlačítka
    document.getElementById('map-btn-recenter')?.addEventListener('click', () => {
        leafletMap.flyTo([-1200, 100], 3.6);
    });
    document.getElementById('map-btn-county')?.addEventListener('click', () => {
        leafletMap.flyTo([2200, 1600], 3.3);
    });
    document.getElementById('map-btn-paleto')?.addEventListener('click', () => {
        leafletMap.flyTo([6500, -100], 3.6);
    });

    // Filtry v pravém panelu
    document.querySelectorAll('.filter-tag').forEach(btn => {
        btn.addEventListener('click', () => {
            document.querySelectorAll('.filter-tag').forEach(b => b.classList.remove('active'));
            btn.classList.add('active');
            currentMapFilter = btn.getAttribute('data-filter');
            loadTacticalMap();
        });
    });
}

function startTacticalMapPolling() {
    initLeafletMap();
    loadTacticalMap();
    if (!mapPollingInterval) {
        mapPollingInterval = setInterval(loadTacticalMap, 2500);
    }
}

function stopTacticalMapPolling() {
    if (mapPollingInterval) {
        clearInterval(mapPollingInterval);
        mapPollingInterval = null;
    }
}

async function loadTacticalMap() {
    if (!leafletMap) initLeafletMap();
    const units = await postNUI('getLiveUnits');
    renderTacticalUnits(units || []);
}

function renderTacticalUnits(units) {
    if (!leafletMap) return;
    const roster = document.getElementById('map-units-roster');
    if (!roster) return;

    const seenIds = new Set();
    roster.innerHTML = '';

    const filteredUnits = units.filter(unit => {
        if (currentMapFilter === 'police') return unit.job !== 'ambulance';
        if (currentMapFilter === 'ambulance') return unit.job === 'ambulance';
        return true;
    });

    if (filteredUnits.length === 0) {
        roster.innerHTML = `<div style="color: var(--text-muted); padding: 16px; text-align: center;">${t('no_results', 'Žádné jednotky v terénu.')}</div>`;
    }

    filteredUnits.forEach(unit => {
        const id = String(unit.id);
        seenIds.add(id);

        const coords = unit.coords || { x: 0, y: 0 };
        const latlng = toMapLatLng(coords);
        const isEMS = unit.job === 'ambulance';
        const vehIcon = unit.inVehicle ? '🚔' : '👮';
        const dotClass = isEMS ? 'marker-beacon ems' : 'marker-beacon';

        // 1. Leaflet Custom Pulsing Marker
        const iconHtml = `
            <div class="custom-leaflet-marker">
                <div class="${dotClass}" style="transform: rotate(${unit.heading || 0}deg);">
                    <span>${isEMS ? '🚑' : vehIcon}</span>
                </div>
                <div class="marker-label">${escapeHtml(unit.name)}</div>
            </div>
        `;

        const icon = L.divIcon({
            className: 'leaflet-unit-div-icon',
            html: iconHtml,
            iconSize: [80, 50],
            iconAnchor: [40, 25]
        });

        let marker = leafletMarkers.get(id);
        if (marker) {
            marker.setLatLng(latlng);
            marker.setIcon(icon);
        } else {
            marker = L.marker(latlng, { icon: icon }).addTo(leafletMap);
            marker.bindPopup(`
                <div style="font-size: 12px; min-width: 170px; line-height: 1.5;">
                    <div style="font-weight: 700; color: #38bdf8; font-size: 14px;">${escapeHtml(unit.name)}</div>
                    <div style="color: #94a3b8; font-size: 11px;">${escapeHtml(unit.jobLabel)} - ${escapeHtml(unit.grade)}</div>
                    <div style="color: #cbd5e1; margin-top: 4px;">${t('status', 'Stav')}: ${unit.inVehicle ? ('🚔 ' + t('in_vehicle', 'Ve voze')) : ('🚶 ' + t('on_foot', 'Pěší'))}</div>
                    <button id="btn-popup-gps-${id}" class="btn-primary" style="margin-top: 8px; width: 100%; font-size: 11px; padding: 4px 8px;">
                        🎯 ${t('set_waypoint', 'Zaměřit GPS')}
                    </button>
                </div>
            `);
            marker.on('popupopen', () => {
                document.getElementById(`btn-popup-gps-${id}`)?.addEventListener('click', () => {
                    postNUI('setWaypoint', { x: coords.x, y: coords.y });
                });
            });
            leafletMarkers.set(id, marker);
        }

        // 2. Karta v postranním seznamu jednotek
        const card = document.createElement('div');
        card.className = 'list-item';
        card.style.flexDirection = 'column';
        card.style.alignItems = 'stretch';
        card.style.gap = '8px';
        card.innerHTML = `
            <div style="display: flex; justify-content: space-between; align-items: center;">
                <div style="display: flex; align-items: center; gap: 8px;">
                    <div class="${dotClass}" style="width: 12px; height: 12px; border-width: 1px;"></div>
                    <strong style="color: var(--text-primary); font-size: 13px;">${escapeHtml(unit.name)}</strong>
                </div>
                <span class="tag-badge ${isEMS ? 'red' : 'blue'}" style="font-size: 10px;">${escapeHtml(unit.jobLabel)}</span>
            </div>
            <div style="display: flex; justify-content: space-between; align-items: center; font-size: 11px; color: var(--text-secondary);">
                <span>${t('rank', 'Hodnost')}: <strong style="color: var(--text-primary);">${escapeHtml(unit.grade)}</strong></span>
                <span>${unit.inVehicle ? ('🚔 ' + t('in_vehicle', 'Ve voze')) : ('🚶 ' + t('on_foot', 'Pěší'))}</span>
            </div>
            <div style="display: flex; gap: 6px; justify-content: flex-end; margin-top: 4px;">
                <button class="btn-secondary btn-card-focus" style="font-size: 11px; padding: 4px 8px;">
                    🔍 ${t('view_focus', 'Pohled')}
                </button>
                <button class="btn-primary btn-card-gps" style="font-size: 11px; padding: 4px 8px;">
                    🎯 ${t('set_waypoint', 'GPS')}
                </button>
            </div>
        `;

        card.querySelector('.btn-card-focus').addEventListener('click', () => {
            leafletMap.flyTo(latlng, 4.5);
            marker.openPopup();
        });

        card.querySelector('.btn-card-gps').addEventListener('click', () => {
            postNUI('setWaypoint', { x: coords.x, y: coords.y });
        });

        roster.appendChild(card);
    });

    // Odstranit offline jednotky
    for (const [id, marker] of leafletMarkers.entries()) {
        if (!seenIds.has(id)) {
            marker.remove();
            leafletMarkers.delete(id);
        }
    }
}

const btnRefreshMap = document.getElementById('btn-refresh-map');
if (btnRefreshMap) {
    btnRefreshMap.addEventListener('click', loadTacticalMap);
}

// ==========================================
// 10. POLICE IN-VEHICLE SPEED RADAR & /radarset
// ==========================================
let radarIsDragging = false;
let radarDragOffset = { x: 0, y: 0 };

function checkServerBoot(bootTime) {
    if (!bootTime) return;
    const storedBoot = localStorage.getItem('pt_mdt_server_boot');
    if (storedBoot && String(storedBoot) !== String(bootTime)) {
        // Server restart detected: reset radar position to default
        resetRadarPosition();
    }
    localStorage.setItem('pt_mdt_server_boot', String(bootTime));
}

function resetRadarPosition() {
    localStorage.removeItem('pt_mdt_radar_pos');
    const radar = document.getElementById('police-radar-hud');
    if (radar) {
        radar.style.left = '';
        radar.style.top = '';
        radar.style.bottom = '30px';
        radar.style.right = '30px';
    }
}

function initRadarDraggable() {
    const radar = document.getElementById('police-radar-hud');
    const saveBtn = document.getElementById('btn-save-radar-pos');
    if (!radar) return;

    // Načtení uložené pozice z localStorage
    const savedPos = localStorage.getItem('pt_mdt_radar_pos');
    if (savedPos) {
        try {
            const pos = JSON.parse(savedPos);
            if (pos && pos.left !== undefined && pos.top !== undefined) {
                radar.style.left = pos.left;
                radar.style.top = pos.top;
                radar.style.bottom = 'auto';
                radar.style.right = 'auto';
            }
        } catch (e) {}
    }

    // Dragging myší při edit módu
    const startDrag = (e) => {
        if (!radar.classList.contains('editing')) return;
        radarIsDragging = true;
        const rect = radar.getBoundingClientRect();
        radarDragOffset.x = e.clientX - rect.left;
        radarDragOffset.y = e.clientY - rect.top;
        e.preventDefault();
    };

    radar.addEventListener('mousedown', startDrag);

    window.addEventListener('mousemove', (e) => {
        if (!radarIsDragging) return;
        const x = Math.max(10, Math.min(window.innerWidth - radar.offsetWidth - 10, e.clientX - radarDragOffset.x));
        const y = Math.max(10, Math.min(window.innerHeight - radar.offsetHeight - 10, e.clientY - radarDragOffset.y));

        radar.style.left = `${x}px`;
        radar.style.top = `${y}px`;
        radar.style.bottom = 'auto';
        radar.style.right = 'auto';
    });

    window.addEventListener('mouseup', () => {
        if (radarIsDragging) {
            radarIsDragging = false;
            saveCurrentRadarPos();
        }
    });

    if (saveBtn) {
        saveBtn.addEventListener('click', () => {
            saveCurrentRadarPos();
            setRadarEditMode(false);
            postNUI('saveRadarPosition');
        });
    }
}

function saveCurrentRadarPos() {
    const radar = document.getElementById('police-radar-hud');
    if (!radar) return;
    const pos = {
        left: radar.style.left,
        top: radar.style.top
    };
    localStorage.setItem('pt_mdt_radar_pos', JSON.stringify(pos));
}

function setRadarEditMode(editing) {
    const radar = document.getElementById('police-radar-hud');
    const dragHandle = document.getElementById('radar-drag-handle');
    if (!radar) return;

    if (editing) {
        radar.classList.add('active');
        radar.classList.add('editing');
        if (dragHandle) dragHandle.style.display = 'flex';
    } else {
        radar.classList.remove('editing');
        if (dragHandle) dragHandle.style.display = 'none';
    }
}

function updateRadarDisplay(data) {
    if (!data) return;
    const patrolEl = document.getElementById('radar-patrol-speed');
    const frontSpeedEl = document.getElementById('radar-front-speed');
    const frontPlateEl = document.getElementById('radar-front-plate');
    const rearSpeedEl = document.getElementById('radar-rear-speed');
    const rearPlateEl = document.getElementById('radar-rear-plate');
    const lockSpeedEl = document.getElementById('radar-lock-speed');

    if (patrolEl) patrolEl.textContent = String(data.patrolSpeed || 0).padStart(3, '0');
    if (frontSpeedEl) frontSpeedEl.textContent = String(data.frontSpeed || 0).padStart(3, '0');
    if (frontPlateEl) frontPlateEl.textContent = data.frontPlate && data.frontPlate !== '---' ? data.frontPlate : t('radar_no_target', 'NO TARGET');
    if (rearSpeedEl) rearSpeedEl.textContent = String(data.rearSpeed || 0).padStart(3, '0');
    if (rearPlateEl) rearPlateEl.textContent = data.rearPlate && data.rearPlate !== '---' ? data.rearPlate : t('radar_no_target', 'NO TARGET');

    if (data.locked && data.lockedData && lockSpeedEl) {
        lockSpeedEl.textContent = String(data.lockedData.speed || 0).padStart(3, '0');
    }
}

function applyRadarLock(locked, lockedData) {
    const lockBox = document.getElementById('radar-lock-box');
    const lockSpeedEl = document.getElementById('radar-lock-speed');
    if (!lockBox || !lockSpeedEl) return;

    if (locked && lockedData) {
        lockBox.classList.add('locked');
        lockSpeedEl.textContent = String(lockedData.speed || 0).padStart(3, '0');
    } else {
        lockBox.classList.remove('locked');
        lockSpeedEl.textContent = '---';
    }
}

// Live Digital Clock
function startLiveClock() {
    const clock = document.getElementById('live-clock');
    if (!clock) return;
    const update = () => {
        const now = new Date();
        clock.textContent = now.toTimeString().split(' ')[0];
    };
    update();
    setInterval(update, 1000);
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

// Inicializace při načtení NUI
initRadarDraggable();
startLiveClock();
