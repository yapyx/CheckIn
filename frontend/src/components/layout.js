import { iconSvg } from '../assets/icons.js';

export const brand = () => `<header class="brand"><h1>CheckIn</h1><p>Dependable daily care</p></header>`;

export const trust = () => `<div class="trust"><span aria-hidden="true">${iconSvg('shield')}</span> Government-grade protection</div>`;

export const topbar = (title = 'CheckIn', back = '', avatar = 'A') => `<div class="topbar">${back ? `<button data-action="${back}" class="icon-btn">←</button><strong>${title}</strong>` : `<strong>${title}</strong>`}<div class="avatar">${avatar}</div></div>`;

export const bottomNav = (active = 'home') => `<nav class="bottom-nav"><button data-action="caregiverHome" class="${active === 'home' ? 'active' : ''}"><span>⌂</span>Home</button><button data-action="family" class="${active === 'family' ? 'active' : ''}"><span>☷</span>Family</button></nav>`;

export const elderNav = (active = 'home') => `<nav class="bottom-nav elder"><button data-action="elderHome" class="${active === 'home' ? 'active' : ''}"><span>⌂</span>Home</button><button data-action="health" class="${active === 'health' ? 'active' : ''}"><span>▧</span>Health Logs</button><button data-action="settings" class="${active === 'settings' ? 'active' : ''}"><span>⚙</span>Settings</button></nav>`;
