import { elderNav, topbar } from '../components/layout.js';
import { state } from '../data/appState.js';

export function elderHome() {
  return `<section class="screen with-nav elder-screen">${topbar('CheckIn', 'welcome', '👴')}<div class="padded grow"><h1>Your Caregiver</h1><p class="large-copy">Sarah is here to support you today. Reach out if you need anything.</p><div class="caregiver-card"><div class="photo-ring">👩‍⚕️<span></span></div><h2>Sarah Jenkins</h2><b>Verified Caregiver • Online</b><button class="primary wide" data-action="recorder">▱ Talk to Sarah</button></div></div>${elderNav('home')}</section>`;
}

export function recorder() {
  const recording = state.recorderMode === 'recording';
  return `<section class="screen recorder"><h1>Talk to Sarah</h1><div class="status-dot"></div><h2>${recording ? 'CLICK TO END' : 'CLICK TO TALK'}</h2><p>${recording ? 'Tap the button when you are finished.' : 'Press and hold the big button to speak.'}</p><button class="record-button ${recording ? 'recording' : ''}" data-action="recordToggle"><span class="mic">🎙</span><span>${recording ? 'CLICK TO END' : 'CLICK TO START'}</span></button><footer><span>♢</span><strong>Secured System</strong><p>Sarah will hear your message instantly.<br>This connection is private and safe.</p></footer></section>`;
}

export function delivered() {
  const status = state.careStatus;
  return `<section class="screen delivered">${topbar('CheckIn', 'elderHome', '👩‍⚕️')}<div class="padded"><div class="success">✓</div><div class="circle-illustration">👵 🛒 👴<span></span></div><h2>${status.label}</h2><p>${status.detail}</p><p class="time">◷ Sent at ${status.sent}</p><div class="delivered-card"><span>✓</span><div><strong>Memo Delivered</strong><p>Your voice message has been safely sent to Sarah.</p></div></div><button class="primary wide" data-action="recorder">🎙 Back to Recorder</button></div></section>`;
}

export function simpleElder(title, icon, copy, active) {
  return `<section class="screen with-nav">${topbar(title, 'elderHome', '👴')}<div class="padded grow center"><span class="page-icon">${icon}</span><h1>${title}</h1><p class="large-copy">${copy}</p></div>${elderNav(active)}</section>`;
}
