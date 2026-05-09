import { iconSvg } from '../assets/icons.js';
import { state } from '../data/appState.js';

export function roleCard(role, icon, title, copy) {
  return `<button class="role-card ${state.selectedRole === role ? 'selected' : ''}" data-role="${role}"><span>${iconSvg(icon)}</span><div><strong>${title}</strong><small>${copy}</small></div></button>`;
}

export function messageCard(message) {
  return `<article class="msg-card ${message.tone}" data-message="${message.id}"><button class="card-open"><div class="msg-head"><div class="kind"><span>${message.icon}</span><b>${message.kind}</b></div><time>${message.time}</time></div><h3>${message.title}</h3><p>${message.copy}</p></button><button class="slim outline" data-dismiss="${message.id}">Mark handled</button></article>`;
}
