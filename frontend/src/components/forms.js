import { state } from '../data/appState.js';
import { esc } from '../utils/html.js';

export const field = (label, placeholder, name = '', tall = false, icon = '') => `<label class="field"><span>${label}</span><div class="input ${tall ? 'tall' : ''}"><input data-field="${name}" value="${esc(state[name] || '')}" placeholder="${placeholder}">${icon ? `<b>${icon}</b>` : ''}</div></label>`;
