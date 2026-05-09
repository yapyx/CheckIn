import { messageCard } from '../components/cards.js';
import { field } from '../components/forms.js';
import { bottomNav, topbar } from '../components/layout.js';
import { state } from '../data/appState.js';

export function caregiverHome() {
  const cards = state.messages.map(messageCard).join('') || `<div class="empty">✓ All messages are handled.</div>`;
  return `<section class="screen with-nav"><div class="padded grow">${topbar()}<p class="date">Mon, 15 Feb</p><h1 class="hello">Hello, Angelica</h1><h2 class="section-title">Your family needs you</h2>${cards}</div>${bottomNav('home')}</section>`;
}

export function family() {
  const members = state.family.map((member) => `<button class="family-card"><span>👴</span><strong>${member}</strong></button>`).join('');
  return `<section class="screen with-nav"><div class="padded grow">${topbar('Family', 'caregiverHome', '👩‍⚕️')}<h1 class="hello">Family Circle</h1>${members}<div class="add-box"><h2>Add a Family Member</h2>${field('Member ID', 'Enter CheckIn ID', 'memberId')}${field('Nickname', 'e.g., Grandpa Joe', 'nickname')}<button class="primary wide" data-action="addMember">Add Member</button></div></div>${bottomNav('family')}</section>`;
}

export function messageDetail() {
  const message = state.selectedMessage || state.messages[0];
  const emergency = message.tone === 'critical';
  return `<section class="screen with-nav">${topbar('CheckIn', 'caregiverHome', '👩‍⚕️')}<div class="padded grow detail">${emergency ? `<div class="emergency">🚨 Emergency alert requires acknowledgment</div>` : ''}<div class="voice-card"><b>VOICE MEMO</b><h3>Today, 10:42 AM • 0:18</h3><div class="wave">${Array.from({ length: 14 }, (_, index) => `<i style="height:${18 + (index % 5) * 12}px"></i>`).join('')}</div><div class="player"><button>▶</button><span class="track"><i></i></span><code>0:06 / 0:18</code></div></div><h2 class="eyebrow">✦ AI ANALYSIS</h2><div class="analysis"><div><small>INTENT</small><strong>${message.intent}</strong></div><div><small>MOOD</small><strong>${message.mood}</strong></div></div><h2 class="eyebrow">☰ FULL TRANSCRIPTION</h2><blockquote>"${message.transcript}"</blockquote><h2>Quick Status Update</h2><p>Update the status shown on the senior's tablet:</p><button class="dark wide" data-status="working">💼 Working</button><button class="outline wide" data-status="callback">☎ Will call back</button>${emergency ? `<div class="quick-actions"><button class="primary" data-action="callParent">Call parent now</button><button class="outline" data-action="callEmergency">Call emergency contact</button><button class="outline" data-action="falseAlarm">Mark as false alarm</button></div>` : ''}</div>${bottomNav('home')}</section>`;
}
