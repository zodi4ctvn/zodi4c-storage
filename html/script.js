let storages = [];
let favorites = JSON.parse(localStorage.getItem('zodi4c-storage-favs') || '[]');
let currentFilter = 'all';
let pricing = {};
let limits = {};
let security = {};
let defaultImage = "";
let locales = {};
let searchQuery = "";
let currentPage = 1;
const itemsPerPage = 6;
let currentManageId = null;
let pendingStorageId = null;

// Escape any value that is interpolated into HTML. Storage names, member names
// and log details are player-controlled, so they must never be rendered raw.
function escapeHtml(value) {
    return String(value ?? '')
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#39;');
}

function t(key, ...args) {
    let value = locales[key];
    if (typeof value !== 'string') return key;
    args.forEach((arg) => {
        value = value.replace('%s', arg);
    });
    return value;
}

function applyTranslations() {
    document.querySelectorAll('[data-i18n]').forEach((el) => {
        const value = locales[el.dataset.i18n];
        if (typeof value === 'string') el.textContent = value;
    });

    document.querySelectorAll('[data-i18n-placeholder]').forEach((el) => {
        const value = locales[el.dataset.i18nPlaceholder];
        if (typeof value === 'string') el.placeholder = value;
    });

    document.querySelectorAll('[data-i18n-title]').forEach((el) => {
        const value = locales[el.dataset.i18nTitle];
        if (typeof value === 'string') el.title = value;
    });
}

document.addEventListener('DOMContentLoaded', () => {
    setTimeout(() => {
        if (window.lucide) {
            lucide.createIcons();
        }
    }, 200);

    // Interaction UI
    window.addEventListener('message', (event) => {
        const data = event.data;

        switch (data.action) {
            case 'showInteraction': {
                const interactionUI = document.getElementById('interaction-ui');
                if (interactionUI) {
                    interactionUI.classList.remove('hidden');
                    const textEl = document.querySelector('.interaction-text');
                    const keyEl = document.querySelector('.key-cap');
                    if (textEl) textEl.innerText = data.text || '';
                    if (keyEl) keyEl.innerText = data.key || 'E';
                }
                break;
            }
            case 'hideInteraction': {
                const interactionUI = document.getElementById('interaction-ui');
                if (interactionUI) {
                    interactionUI.classList.add('hidden');
                }
                break;
            }
            case 'updateInteractionPos': {
                const el = document.getElementById('interaction-ui');
                if (el) {
                    el.style.left = `${data.x}%`;
                    el.style.top = `${data.y}%`;
                }
                break;
            }
            case 'openMenu': {
                storages = data.storages || [];
                pricing = data.pricing || {};
                limits = data.limits || {};
                security = data.security || {};
                defaultImage = data.defaultImage || '';
                locales = data.locales || {};

                document.documentElement.lang = data.locale || 'tr';
                applyTranslations();

                const maxSlotsHint = document.getElementById('max-slots-hint');
                const maxWeightHint = document.getElementById('max-weight-hint');
                const capSlotsHint = document.getElementById('capacity-slots-hint');
                const capWeightHint = document.getElementById('capacity-weight-hint');
                const maxWeightKg = (limits.maxWeight || 500000) / 1000;

                if (maxSlotsHint) maxSlotsHint.innerText = t('max_value', limits.maxSlots || 100);
                if (maxWeightHint) maxWeightHint.innerText = t('max_value', `${maxWeightKg} kg`);
                if (capSlotsHint) capSlotsHint.innerText = t('max_value', limits.maxSlots || 100);
                if (capWeightHint) capWeightHint.innerText = t('max_value', `${maxWeightKg} kg`);

                const minPasswordLength = security.minPasswordLength || 4;
                const maxPasswordLength = security.maxPasswordLength || 50;
                document.querySelectorAll('.min-password-hint').forEach((el) => {
                    el.innerText = t('min_chars', minPasswordLength);
                });
                document.querySelectorAll('.password-length-input').forEach((el) => {
                    el.maxLength = maxPasswordLength;
                });

                updatePricingUI();
                renderStorages();
                document.documentElement.style.setProperty('--blur-level', `${data.blurLevel || 10}px`);
                const mainMenu = document.getElementById('main-menu');
                if (mainMenu) mainMenu.classList.remove('hidden');
                break;
            }
            case 'updateStorages': {
                storages = data.storages || [];
                renderStorages();
                break;
            }
            case 'notify': {
                sendNotify(data.text, data.type);
                break;
            }
        }
    });

    // Close on Escape & Disable Tab
    window.addEventListener('keydown', (e) => {
        if (e.key === 'Escape') {
            const subModalIds = [
                'logs-modal',
                'delete-confirm-modal',
                'change-password-modal',
                'capacity-modal',
                'edit-storage-modal',
                'members-modal',
                'manage-modal',
                'create-modal',
                'password-modal'
            ];

            const openSubModal = subModalIds.find(id => {
                const el = document.getElementById(id);
                return el && !el.classList.contains('hidden');
            });

            if (openSubModal) {
                const modal = document.getElementById(openSubModal);
                if (modal) modal.classList.add('hidden');

                const anyOpen = subModalIds.some(id => {
                    const el = document.getElementById(id);
                    return el && !el.classList.contains('hidden');
                });
                if (!anyOpen) {
                    const container = document.querySelector('.menu-container');
                    if (container) container.classList.remove('modal-blur');
                }
            } else {
                const mainMenu = document.getElementById('main-menu');
                if (mainMenu && !mainMenu.classList.contains('hidden')) {
                    closeAll();
                }
            }
        }
        if (e.key === 'Tab') {
            e.preventDefault();
        }
    });

    // Image Preview logic
    const imageInput = document.getElementById('storage-image');
    if (imageInput) {
        imageInput.addEventListener('input', (e) => {
            const url = e.target.value;
            const preview = document.getElementById('image-preview');
            if (preview) {
                if (url && (url.startsWith('http') || url.startsWith('https') || url.startsWith('data:'))) {
                    // object-fit keeps the full image visible inside the preview box.
                    preview.innerHTML = `<img src="${escapeHtml(url)}" onerror="this.src='${defaultImage}'" alt="preview" style="width:100%; height:100%; object-fit:contain; border-radius:8px; padding:8px;">`;
                } else {
                    preview.innerHTML = `<i data-lucide="image"></i>`;
                    if (window.lucide) lucide.createIcons();
                }
            }
        });
    }

    // Favorite Filter
    const filterFavBtn = document.getElementById('filter-fav');
    if (filterFavBtn) {
        filterFavBtn.addEventListener('click', function () {
            currentFilter = currentFilter === 'all' ? 'fav' : 'all';
            this.classList.toggle('active', currentFilter === 'fav');
            renderStorages();
        });
    }

    // Clear Filter
    const clearFilterBtn = document.getElementById('clear-filter');
    if (clearFilterBtn) {
        clearFilterBtn.addEventListener('click', () => {
            currentFilter = 'all';
            const filterFav = document.getElementById('filter-fav');
            if (filterFav) filterFav.classList.remove('active');
            renderStorages();
        });
    }

    // Search Logic
    const searchInput = document.getElementById('storage-search');
    if (searchInput) {
        searchInput.addEventListener('input', (e) => {
            searchQuery = e.target.value.toLowerCase();
            currentPage = 1;
            renderStorages();
        });
    }

    // Pagination Listeners
    const prevPageBtn = document.getElementById('prev-page');
    if (prevPageBtn) {
        prevPageBtn.addEventListener('click', () => {
            if (currentPage > 1) {
                currentPage--;
                renderStorages();
            }
        });
    }

    const nextPageBtn = document.getElementById('next-page');
    if (nextPageBtn) {
        nextPageBtn.addEventListener('click', () => {
            const filtered = getFilteredStorages();
            const maxPages = Math.ceil(filtered.length / itemsPerPage);
            if (currentPage < maxPages) {
                currentPage++;
                renderStorages();
            }
        });
    }

    // Create Modal
    const openCreateBtn = document.getElementById('open-create');
    if (openCreateBtn) {
        openCreateBtn.addEventListener('click', () => {
            const modal = document.getElementById('create-modal');
            const container = document.querySelector('.menu-container');
            if (modal) modal.classList.remove('hidden');
            if (container) container.classList.add('modal-blur');
        });
    }

    // Confirm Create
    const confirmCreateBtn = document.getElementById('confirm-create');
    if (confirmCreateBtn) {
        confirmCreateBtn.addEventListener('click', () => {
            const nameInput = document.getElementById('storage-name');
            const imageInput = document.getElementById('storage-image');
            const slotsInput = document.getElementById('storage-slots');
            const weightInput = document.getElementById('storage-weight');
            const passwordInput = document.getElementById('storage-password');
            const paymentRadio = document.querySelector('input[name="payment"]:checked');

            const name = nameInput?.value || '';
            const image = imageInput?.value || defaultImage;
            const slots = parseInt(slotsInput?.value) || 50;
            const weight = parseInt(weightInput?.value) || 100;
            const password = passwordInput?.value || '';
            const paymentType = paymentRadio?.value || 'bank';

            if (name.length < (limits.minNameLength || 3)) {
                sendNotify(t('name_too_short', limits.minNameLength || 3), 'error');
                return;
            }

            if (password.length > 0 && password.length < (security.minPasswordLength || 4)) {
                sendNotify(t('password_too_short', security.minPasswordLength || 4), 'error');
                return;
            }

            if (slots > (limits.maxSlots || 100)) {
                sendNotify(t('slots_limit_exceeded', limits.maxSlots || 100), 'error');
                return;
            }

            if (weight > ((limits.maxWeight || 500000) / 1000)) {
                sendNotify(t('weight_limit_exceeded', (limits.maxWeight || 500000) / 1000), 'error');
                return;
            }

            const data = {
                name: name,
                image: image,
                slots: slots,
                weight: weight * 1000,
                password: password,
                paymentType: paymentType
            };

            postNUI('createStorage', data);

            const createModal = document.getElementById('create-modal');
            const container = document.querySelector('.menu-container');
            if (createModal) createModal.classList.add('hidden');
            if (container) container.classList.remove('modal-blur');

            // Reset form
            if (nameInput) nameInput.value = '';
            if (imageInput) imageInput.value = '';
            if (slotsInput) slotsInput.value = '';
            if (weightInput) weightInput.value = '';
            if (passwordInput) passwordInput.value = '';
        });
    }

    // Save Edit
    const saveEditBtn = document.getElementById('save-storage-edit');
    if (saveEditBtn) {
        saveEditBtn.addEventListener('click', () => {
            const nameInput = document.getElementById('edit-storage-name');
            const imageInput = document.getElementById('edit-storage-image');

            const name = nameInput?.value || '';
            const image = imageInput?.value || defaultImage;

            if (name.length < (limits.minNameLength || 3)) {
                sendNotify(t('name_too_short', limits.minNameLength || 3), 'error');
                return;
            }

            postNUI('updateStorage', {
                id: currentManageId,
                name: name,
                image: image
            });

            // Close only the edit modal; the management modal stays open.
            const editModal = document.getElementById('edit-storage-modal');
            if (editModal) editModal.classList.add('hidden');
        });
    }

    // Save Password Change
    const savePasswordBtn = document.getElementById('save-password-change');
    if (savePasswordBtn) {
        savePasswordBtn.addEventListener('click', () => {
            const oldPassInput = document.getElementById('old-password');
            const newPassInput = document.getElementById('new-password');

            const oldPass = oldPassInput?.value || '';
            const newPass = newPassInput?.value || '';

            if (newPass.length === 0) {
                sendNotify(t('new_password_empty'), 'error');
                return;
            }

            if (newPass.length < (security.minPasswordLength || 4)) {
                sendNotify(t('password_too_short', security.minPasswordLength || 4), 'error');
                return;
            }

            postNUI('changePassword', {
                id: currentManageId,
                oldPass: oldPass,
                newPass: newPass
            });

            // Close only the password modal; the management modal stays open.
            const changePassModal = document.getElementById('change-password-modal');
            if (changePassModal) changePassModal.classList.add('hidden');

            if (oldPassInput) oldPassInput.value = '';
            if (newPassInput) newPassInput.value = '';
        });
    }

    // Close Modals
    document.querySelectorAll('.close-modal').forEach(btn => {
        btn.addEventListener('click', () => {
            const modal = btn.closest('.modal-overlay');
            if (modal) {
                modal.classList.add('hidden');
                const mainMenu = document.getElementById('main-menu');
                if (modal.id === 'main-menu' || (mainMenu && mainMenu.classList.contains('hidden'))) {
                    closeAll();
                } else {
                    const hasOpenModal = Array.from(document.querySelectorAll('.modal-overlay')).some(m =>
                        !m.classList.contains('hidden') && m.id !== 'main-menu'
                    );
                    if (!hasOpenModal) {
                        const container = document.querySelector('.menu-container');
                        if (container) container.classList.remove('modal-blur');
                    }
                }
            }
        });
    });

    // Only the main menu closes when clicking the backdrop. Sub-modals are
    // closed with their X button to prevent accidental data loss.
    document.querySelectorAll('.menu-overlay').forEach(overlay => {
        overlay.addEventListener('click', (e) => {
            if (e.target === overlay && overlay.id === 'main-menu') {
                closeAll();
            }
        });
    });

    // Password Modal Confirm
    const confirmPasswordBtn = document.getElementById('confirm-password');
    if (confirmPasswordBtn) {
        confirmPasswordBtn.addEventListener('click', () => {
            const passwordInput = document.getElementById('access-password');
            const password = passwordInput?.value || '';

            postNUI('openStorage', {
                storageId: pendingStorageId,
                password: password,
                passwordRequired: true
            });

            closeAll();
        });
    }

    // Delete Storage Button
    const deleteStorageBtn = document.getElementById('delete-storage-btn');
    if (deleteStorageBtn) {
        deleteStorageBtn.addEventListener('click', () => {
            const deleteConfirmModal = document.getElementById('delete-confirm-modal');
            if (deleteConfirmModal) deleteConfirmModal.classList.remove('hidden');
        });
    }

    // Confirm Delete
    const confirmDeleteBtn = document.getElementById('confirm-delete');
    if (confirmDeleteBtn) {
        confirmDeleteBtn.addEventListener('click', () => {
            postNUI('deleteStorage', {
                id: currentManageId
            });
            closeAll();
        });
    }

    // Capacity update
    const saveCapacityBtn = document.getElementById('save-capacity-update');
    if (saveCapacityBtn) {
        saveCapacityBtn.addEventListener('click', () => {
            const slotsInput = document.getElementById('update-slots');
            const weightInput = document.getElementById('update-weight');

            const slots = parseInt(slotsInput?.value) || 0;
            const weight = parseInt(weightInput?.value) || 0;

            if (slots < 1 || slots > (limits.maxSlots || 100)) {
                sendNotify(t('invalid_slots_range', limits.maxSlots || 100), 'error');
                return;
            }

            if (weight < 1 || weight > ((limits.maxWeight || 500000) / 1000)) {
                sendNotify(t('invalid_weight_range', (limits.maxWeight || 500000) / 1000), 'error');
                return;
            }

            postNUI('updateStorageCapacity', {
                id: currentManageId,
                slots: slots,
                weight: weight * 1000
            });

            const capacityModal = document.getElementById('capacity-modal');
            if (capacityModal) capacityModal.classList.add('hidden');
        });
    }

    // Remove password
    const removePasswordBtn = document.getElementById('remove-password-btn');
    if (removePasswordBtn) {
        removePasswordBtn.addEventListener('click', () => {
            postNUI('removePassword', {
                id: currentManageId
            });

            const changePasswordModal = document.getElementById('change-password-modal');
            if (changePasswordModal) changePasswordModal.classList.add('hidden');
        });
    }
});

function getFilteredStorages() {
    let filtered = storages;
    if (currentFilter === 'fav') {
        filtered = filtered.filter(s => favorites.includes(s.id));
    }
    if (searchQuery.trim() !== "") {
        filtered = filtered.filter(s => s.name.toLowerCase().includes(searchQuery));
    }
    return filtered;
}

function renderStorages() {
    const list = document.getElementById('storage-list');
    const filterBar = document.getElementById('filter-bar');
    const filtered = getFilteredStorages();

    if (!list) return;

    const totalItems = filtered.length;
    const maxPages = Math.max(1, Math.ceil(totalItems / itemsPerPage));
    if (currentPage > maxPages) currentPage = maxPages;

    const start = (currentPage - 1) * itemsPerPage;
    const paginated = filtered.slice(start, start + itemsPerPage);

    // Update UI
    const pageIndicator = document.getElementById('page-indicator');
    if (pageIndicator) pageIndicator.innerText = t('page_of', currentPage, maxPages);

    const prevBtn = document.getElementById('prev-page');
    const nextBtn = document.getElementById('next-page');
    if (prevBtn) prevBtn.disabled = currentPage === 1;
    if (nextBtn) nextBtn.disabled = currentPage === maxPages;

    // Toggle filter bar visibility
    if (filterBar) {
        if (currentFilter === 'fav') {
            filterBar.classList.remove('hidden');
        } else {
            filterBar.classList.add('hidden');
        }
    }

    if (totalItems === 0) {
        list.innerHTML = `
            <div class="empty-state">
                <div class="empty-icon">
                    <i data-lucide="package"></i>
                </div>
                <h2>${escapeHtml(t('empty_title'))}</h2>
                <p>${escapeHtml(t('empty_desc', t('new_storage')))}</p>
            </div>
        `;
        if (window.lucide) lucide.createIcons();
        return;
    }

    list.innerHTML = '';

    paginated.forEach(s => {
        const isFav = favorites.includes(s.id);
        const card = document.createElement('div');
        card.className = 'storage-card';
        const requiresPassword = !!s.password && !s.isOwner && !s.isMember;

        card.innerHTML = `
            <div class="card-img">
                <img src="${escapeHtml(s.image || defaultImage)}" loading="lazy" decoding="async" onerror="this.src='${defaultImage}'" alt="">
            </div>
            <div class="card-content">
                <div class="card-info">
                    <h3>${escapeHtml(s.name)}</h3>
                    <div class="card-stats">
                        <div class="stat-item">
                            <span>${escapeHtml(t('capacity'))}</span>
                            <span>${escapeHtml(t('slots_count', s.slots))}</span>
                        </div>
                        <div class="stat-item">
                            <span>${escapeHtml(t('weight'))}</span>
                            <span>${(Number(s.weight) / 1000).toFixed(0)} kg</span>
                        </div>
                    </div>
                </div>
                <div class="card-actions">
                    ${s.isOwner ? `
                        <div class="manage-btn" onclick="openManagement(${Number(s.id)})" title="${escapeHtml(t('manage'))}">
                            <i data-lucide="settings"></i>
                        </div>
                    ` : ''}
                    ${s.isMember && !s.isOwner ? `
                        <div class="manage-btn" onclick="leaveStorage(${Number(s.id)})" title="${escapeHtml(t('leave_storage'))}">
                            <i data-lucide="log-out"></i>
                        </div>
                    ` : ''}
                    <div class="fav-badge ${isFav ? 'active' : ''}" onclick="toggleFav(${Number(s.id)})">
                        <i data-lucide="star" style="${isFav ? 'fill: #ffd700' : ''}"></i>
                    </div>
                    <button class="open-btn" onclick="openStorage(${Number(s.id)}, ${requiresPassword})">${escapeHtml(t('open_button'))}</button>
                </div>
            </div>
        `;
        list.appendChild(card);
    });
    if (window.lucide) lucide.createIcons();
}

function toggleFav(id) {
    if (favorites.includes(id)) {
        favorites = favorites.filter(fid => fid !== id);
    } else {
        favorites.push(id);
    }
    localStorage.setItem('zodi4c-storage-favs', JSON.stringify(favorites));
    renderStorages();
}

function openStorage(id, hasPassword) {
    if (hasPassword) {
        pendingStorageId = id;
        const passwordModal = document.getElementById('password-modal');
        const container = document.querySelector('.menu-container');
        if (passwordModal) passwordModal.classList.remove('hidden');
        if (container) container.classList.add('modal-blur');
    } else {
        postNUI('openStorage', {
            storageId: id,
            passwordRequired: false
        });
        closeAll();
    }
}

function updatePricingUI() {
    const bankPrice = document.getElementById('price-bank');
    const cashPrice = document.getElementById('price-cash');
    if (bankPrice) bankPrice.innerText = `${pricing.bank || 5000}$`;
    if (cashPrice) cashPrice.innerText = `${pricing.cash || 5000}$`;
}

function closeAll() {
    const mainMenu = document.getElementById('main-menu');
    const createModal = document.getElementById('create-modal');
    const passwordModal = document.getElementById('password-modal');
    const manageModal = document.getElementById('manage-modal');
    const deleteConfirmModal = document.getElementById('delete-confirm-modal');
    const container = document.querySelector('.menu-container');

    if (mainMenu) mainMenu.classList.add('hidden');
    if (createModal) createModal.classList.add('hidden');
    if (passwordModal) passwordModal.classList.add('hidden');
    if (manageModal) manageModal.classList.add('hidden');
    if (deleteConfirmModal) deleteConfirmModal.classList.add('hidden');
    if (container) container.classList.remove('modal-blur');

    postNUI('closeMenu', {});
}

function openManagement(id) {
    currentManageId = id;
    const storage = storages.find(s => s.id === id);

    if (!storage) {
        sendNotify(t('storage_info_not_found'), 'error');
        return;
    }

    postNUI('getMembers', { id: id }).then(response => {
        if (response && response.success && response.members) {
            const editNameInput = document.getElementById('edit-storage-name');
            const editImageInput = document.getElementById('edit-storage-image');
            const capacitySlotsInput = document.getElementById('update-slots');
            const capacityWeightInput = document.getElementById('update-weight');

            if (editNameInput) editNameInput.value = storage.name;
            if (editImageInput) editImageInput.value = (storage.image && !storage.image.startsWith('data:')) ? storage.image : "";
            if (capacitySlotsInput) capacitySlotsInput.value = storage.slots;
            if (capacityWeightInput) capacityWeightInput.value = Math.round((Number(storage.weight) || 0) / 1000);

            renderMembers(response.members, storage.owner);

            const manageModal = document.getElementById('manage-modal');
            const container = document.querySelector('.menu-container');
            if (manageModal) manageModal.classList.remove('hidden');
            if (container) container.classList.add('modal-blur');
        } else {
            sendNotify(t('members_load_error'), 'error');
        }
    }).catch(err => {
        console.error('Error getting members:', err);
        sendNotify(t('members_connection_error'), 'error');
    });
}

function renderMembers(members, ownerCid) {
    const list = document.getElementById('members-list');
    if (!list) return;

    list.innerHTML = '';

    const ownerEntry = members.find(m => m.citizenid === ownerCid);
    const otherMembers = members.filter(m => m.citizenid !== ownerCid);
    const allToRender = ownerEntry ? [ownerEntry, ...otherMembers] : otherMembers;

    if (allToRender.length === 0) {
        list.innerHTML = `<div style="text-align:center; color:var(--text-dim); padding:20px;">${escapeHtml(t('no_members'))}</div>`;
        return;
    }

    allToRender.forEach(m => {
        const isOwner = m.citizenid === ownerCid;
        const item = document.createElement('div');
        item.className = 'member-item';

        const initials = escapeHtml(getInitials(m.name));
        const safeCid = escapeHtml(JSON.stringify(String(m.citizenid ?? '')));
        const avatarHtml = m.discordId ?
            `<img src="https://api.vops.lt/discord/avatar/${encodeURIComponent(m.discordId)}" class="member-avatar" onerror="this.style.display='none'; this.nextElementSibling.style.display='flex';">` : '';

        item.innerHTML = `
            <div class="member-info">
                <div class="member-avatar-wrapper">
                    ${avatarHtml}
                    <div class="member-initials" style="${m.discordId ? 'display:none;' : 'display:flex;'}">
                        ${initials}
                    </div>
                </div>
                <span class="member-name">
                    ${escapeHtml(m.name)} 
                    ${isOwner ? '<i data-lucide="crown" class="crown-icon"></i>' : ''}
                </span>
            </div>
            ${!isOwner ? `<button class="kick-btn" onclick="kickMember(${safeCid})">${escapeHtml(t('kick'))}</button>` : `<span style="color:var(--primary); font-size:12px; font-weight:600; text-transform: uppercase;">${escapeHtml(t('leader'))}</span>`}
        `;
        list.appendChild(item);
    });
    if (window.lucide) lucide.createIcons();
}

// Helper to get initials from name (Zodiac Leo -> ZL)
function getInitials(name) {
    if (!name) return "?";
    const parts = name.trim().split(' ');
    if (parts.length === 0) return "?";
    if (parts.length === 1) return parts[0].charAt(0).toUpperCase();
    return (parts[0].charAt(0) + parts[parts.length - 1].charAt(0)).toUpperCase();
}

function kickMember(cid) {
    postNUI('kickMember', {
        storageId: currentManageId,
        citizenid: cid
    }).then(res => {
        if (res && res.success) {
            // Refresh the list after the server has removed the member.
            setTimeout(() => {
                postNUI('getMembers', { id: currentManageId }).then(response => {
                    if (response && response.members) {
                        const storage = storages.find(s => s.id === currentManageId);
                        renderMembers(response.members, storage ? storage.owner : null);
                    }
                });
            }, 250);
        }
    });
}

function leaveStorage(id) {
    postNUI('leaveStorage', { storageId: id });
}

function sendNotify(text, type) {
    let toast = document.getElementById('zodi4c-toast-container');
    if (!toast) {
        toast = document.createElement('div');
        toast.id = 'zodi4c-toast-container';
        document.body.appendChild(toast);
    }

    const colors = { error: '#ff4757', success: '#2ed573', info: '#0097a7', warning: '#ffa502' };
    const icons = { error: '✕', success: '✓', info: 'ℹ', warning: '⚠' };
    const toastType = type || 'info';

    const el = document.createElement('div');
    el.className = 'zodi4c-toast zodi4c-toast--' + toastType;
    el.innerHTML = `<span class="zodi4c-toast-icon" style="background:${colors[toastType] || colors.info}">${icons[toastType] || icons.info}</span><span class="zodi4c-toast-text">${escapeHtml(text)}</span>`;
    toast.appendChild(el);

    // Animate in
    requestAnimationFrame(() => el.classList.add('zodi4c-toast--show'));

    setTimeout(() => {
        el.classList.remove('zodi4c-toast--show');
        setTimeout(() => el.remove(), 350);
    }, 3500);
}

function togglePasswordVisibility(inputId) {
    const input = document.getElementById(inputId);
    if (!input) return;

    const wrapper = input.closest('.password-input-wrapper');
    const btn = wrapper?.querySelector('.password-toggle');

    if (input.type === 'password') {
        input.type = 'text';
        // Lucide replaces the <i> element, so the icon is swapped directly.
        if (btn) btn.innerHTML = `<svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24"/><line x1="1" y1="1" x2="23" y2="23"/></svg>`;
    } else {
        input.type = 'password';
        if (btn) btn.innerHTML = `<svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>`;
    }
}

function openSubModal(modalId) {
    const modal = document.getElementById(modalId);
    if (modal) modal.classList.remove('hidden');
    if (window.lucide) lucide.createIcons();
}

// Helper function for NUI calls
function postNUI(action, data) {
    return new Promise((resolve, reject) => {
        const resourceName = (typeof GetParentResourceName === 'function') ? GetParentResourceName() : 'zodi4c-storage';
        const xhr = new XMLHttpRequest();
        xhr.open("POST", `https://${resourceName}/${action}`, true);
        xhr.setRequestHeader("Content-Type", "application/json");
        xhr.onreadystatechange = function () {
            if (xhr.readyState === 4) {
                if (xhr.status === 200) {
                    try {
                        resolve(JSON.parse(xhr.responseText));
                    } catch (e) {
                        resolve(null);
                    }
                } else {
                    console.error(`[zodi4c-storage] NUI error (${action}): ${xhr.status}`);
                    resolve(null);
                }
            }
        };
        xhr.onerror = function () {
            console.error(`[zodi4c-storage] NUI network error (${action})`);
            resolve(null);
        };
        xhr.send(JSON.stringify(data || {}));
    });
}

function getLogAction(action) {
    const actions = {
        take: 'take',
        put: 'put',
        access: 'access',
        'ALDI': 'take',
        'KOYDU': 'put',
        'GİRİŞ': 'access'
    };
    return actions[action] || 'access';
}

function openLogs() {
    if (!currentManageId) return;

    postNUI('getLogs', { storageId: currentManageId }).then(logs => {
        const list = document.getElementById('logs-list');
        if (!list) return;

        list.innerHTML = '';

        if (!logs || logs.length === 0) {
            list.innerHTML = `<tr><td colspan="4" style="text-align:center; padding: 30px; color: var(--text-dim);">${escapeHtml(t('no_logs'))}</td></tr>`;
        } else {
            logs.forEach(log => {
                const action = getLogAction(log.action);
                const row = document.createElement('tr');
                row.innerHTML = `
                    <td style="color: var(--text-dim); font-family: monospace;">${escapeHtml(log.date || log.created_at)}</td>
                    <td style="font-weight: 600;">${escapeHtml(log.name)}</td>
                    <td><span class="log-action-badge log-action-${action}">${escapeHtml(t('log_' + action))}</span></td>
                    <td style="color: #eee;">${escapeHtml(log.details || '-')}</td>
                `;
                list.appendChild(row);
            });
        }

        openSubModal('logs-modal');
    });
}

window.openStorage = openStorage;
window.toggleFav = toggleFav;
window.openManagement = openManagement;
window.kickMember = kickMember;
window.leaveStorage = leaveStorage;
window.openSubModal = openSubModal;
window.togglePasswordVisibility = togglePasswordVisibility;
window.openLogs = openLogs;