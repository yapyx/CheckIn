const NAV = { welcome:'welcome', elderSignup:'elderSignup', caregiverSignup:'caregiverSignup', caregiverHome:'caregiverHome', family:'family', message:'message', elderHome:'elderHome', recorder:'recorder', delivered:'delivered', health:'health', settings:'settings' };

const state = {
  screen: NAV.welcome,
  selectedRole: 'elder',
  selectedMessage: null,
  recorderMode: 'ready',
  memberId: '',
  nickname: '',
  family: ['Grandpa Joe', 'Grandma Mary'],
  careStatus: { label:'I am working now!', detail:'Will see your message soon.', sent:'10:30 AM', icon:'💼' },
  messages: [
    { id:'critical', kind:'Critical Alert', title:'Medication Reminder Missed', time:'10 mins ago', copy:"Sarah hasn't acknowledged her morning blood pressure medication. This may require immediate attention.", tone:'critical', icon:'🚨', transcript:'I forgot whether I took my blood pressure pill this morning, and I feel a little dizzy.', summary:'Possible missed blood pressure medication with dizziness reported.', intent:'Medical Alert', mood:'Concerned' },
    { id:'note', kind:'Personal Note', title:'Feeling Lonely', time:'45 mins ago', copy:'Just wanted to say hi and ask about dinner plans tonight. It has been a quiet afternoon.', tone:'warm', icon:'♡', transcript:'I was just wondering if you are coming over for dinner today? I made your favorite chicken stew.', summary:'Grandma Mary is checking dinner plans and would appreciate a response.', intent:'Routine Inquiry', mood:'Anticipatory' },
    { id:'daily', kind:'Check-in', title:'Daily Status', time:'5 hours ago', copy:"I'm doing well today, the weather looks lovely through the window.", tone:'plain', icon:'✓', transcript:"I'm doing well today, the weather looks lovely through the window.", summary:'Daily wellbeing check-in, no action needed.', intent:'Daily Check-in', mood:'Content' }
  ]
};

const root = document.getElementById('root');
const esc = (value='') => String(value).replace(/[&<>"]/g, (c) => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]));
const setScreen = (screen) => { state.screen = screen; render(); };
const brand = () => `<header class="brand"><h1>CheckIn</h1><p>Dependable daily care</p></header>`;
const trust = () => `<div class="trust"><span>♢</span> Government-grade protection</div>`;
const field = (label, placeholder, name='', tall=false, icon='') => `<label class="field"><span>${label}</span><div class="input ${tall?'tall':''}"><input data-field="${name}" value="${esc(state[name] || '')}" placeholder="${placeholder}">${icon ? `<b>${icon}</b>` : ''}</div></label>`;
const topbar = (title='CheckIn', back='', avatar='A') => `<div class="topbar">${back ? `<button data-action="${back}" class="icon-btn">←</button><strong>${title}</strong>` : `<strong>${title}</strong>`}<div class="avatar">${avatar}</div></div>`;
const bottomNav = (active='home') => `<nav class="bottom-nav"><button data-action="caregiverHome" class="${active==='home'?'active':''}"><span>⌂</span>Home</button><button data-action="family" class="${active==='family'?'active':''}"><span>☷</span>Family</button></nav>`;
const elderNav = (active='home') => `<nav class="bottom-nav elder"><button data-action="elderHome" class="${active==='home'?'active':''}"><span>⌂</span>Home</button><button data-action="health" class="${active==='health'?'active':''}"><span>▧</span>Health Logs</button><button data-action="settings" class="${active==='settings'?'active':''}"><span>⚙</span>Settings</button></nav>`;

function welcome() { return `<section class="screen padded welcome">${brand()}<div class="hero-card"><div class="care-illustration"><span>🛒</span><span>👵</span><span>🧑‍⚕️</span></div></div><div class="segmented"><button class="active">Sign Up</button><button data-action="signIn">Sign In</button></div><h2>Tell us who you are</h2>${roleCard('elder','🚶','I am an Elder','I want to receive care')}${roleCard('caregiver','🎧','I am a Caregiver','I am here to support someone')}<button class="primary wide" data-action="createAccount">Create New Account</button>${trust()}</section>`; }
function roleCard(role, icon, title, copy) { return `<button class="role-card ${state.selectedRole===role?'selected':''}" data-role="${role}"><span>${icon}</span><div><strong>${title}</strong><small>${copy}</small></div></button>`; }
function caregiverSignup() { return `<section class="screen padded form-screen">${brand()}<h2>Create Caregiver Account</h2>${field('User ID','Enter your official staff ID')}${field('Create Password','Minimum 12 characters','',false,'◉')}${field('Occupation','Select your current role','',false,'⌄⌄')}${field('Others/Specializations','List certifications (e.g., Dementia Care)','',true)}<p class="agreement"><span>ⓘ</span> By clicking Create, you agree to our <b>Data Processing Agreement</b> and <b>Terms of Conduct.</b></p><button class="primary wide" data-action="finishCaregiverSignup">Create</button><button class="outline wide" data-action="welcome">Cancel</button>${trust()}</section>`; }
function elderSignup() { return `<section class="screen padded form-screen">${brand()}<h2>Join CheckIn</h2><p>Please fill in your details to get started.</p>${field('User ID','Enter your unique ID')}${field('Create Password','Choose a safe password','',false,'◉')}${field('Age','e.g. 75')}${field('Health Conditions','e.g. Hypertension, Diabetes')}${field('Notes / Other Information','Anything else we should know?','',true)}<button class="primary wide" data-action="finishElderSignup">Create</button><button class="outline wide" data-action="welcome">← Go Back</button>${trust()}</section>`; }
function caregiverHome() { const cards = state.messages.map(messageCard).join('') || `<div class="empty">✓ All messages are handled.</div>`; return `<section class="screen with-nav"><div class="padded grow">${topbar()}<p class="date">Mon, 15 Feb</p><h1 class="hello">Hello, Sarah!</h1><h2 class="section-title">Recent Messages</h2><div class="message-list">${cards}</div></div>${bottomNav('home')}</section>`; }
function messageCard(m) { return `<article class="msg-card ${m.tone}"><button class="card-open" data-message="${m.id}"><div class="msg-head"><span class="kind"><i>${m.icon}</i>${m.kind}</span><time>${m.time}</time></div><h3>${m.title}</h3><p>${m.copy}</p></button>${m.id==='daily'?`<button class="outline slim" data-dismiss="${m.id}">Dismiss</button>`:''}</article>`; }
function family() { return `<section class="screen with-nav">${topbar('Family','caregiverHome','👨‍⚕️')}<div class="padded grow"><p>Caring for</p><h1>Your Household</h1>${state.family.map((name,i)=>`<button class="family-card" data-family="${esc(name)}"><span>${i===0?'👴':'👵'}</span><strong>${esc(name)}</strong></button>`).join('')}<div class="add-box"><h2>Add Family Member</h2><p>Connect to an elderly user's device via ID</p>${field('Elderly User ID','e.g. CS-9942-88','memberId')}${field('Nickname','e.g. Grandma Mary','nickname')}<button class="dark wide" data-action="addMember">☷ Add Member</button></div></div>${bottomNav('family')}</section>`; }
function messageDetail() { const m = state.selectedMessage || state.messages[0]; const emergency = m.tone === 'critical'; return `<section class="screen with-nav">${topbar('CheckIn','caregiverHome','👩‍⚕️')}<div class="padded grow detail">${emergency?`<div class="emergency">🚨 Emergency alert requires acknowledgment</div>`:''}<div class="voice-card"><b>VOICE MEMO</b><h3>Today, 10:42 AM • 0:18</h3><div class="wave">${Array.from({length:14},(_,i)=>`<i style="height:${18+(i%5)*12}px"></i>`).join('')}</div><div class="player"><button>▶</button><span class="track"><i></i></span><code>0:06 / 0:18</code></div></div><h2 class="eyebrow">✦ AI ANALYSIS</h2><div class="analysis"><div><small>INTENT</small><strong>${m.intent}</strong></div><div><small>MOOD</small><strong>${m.mood}</strong></div></div><h2 class="eyebrow">☰ FULL TRANSCRIPTION</h2><blockquote>"${m.transcript}"</blockquote><h2>Quick Status Update</h2><p>Update the status shown on the senior's tablet:</p><button class="dark wide" data-status="working">💼 Working</button><button class="outline wide" data-status="callback">☎ Will call back</button>${emergency?`<div class="quick-actions"><button class="primary" data-action="callParent">Call parent now</button><button class="outline" data-action="callEmergency">Call emergency contact</button><button class="outline" data-action="falseAlarm">Mark as false alarm</button></div>`:''}</div>${bottomNav('home')}</section>`; }
function elderHome() { return `<section class="screen with-nav elder-screen">${topbar('CheckIn','welcome','👴')}<div class="padded grow"><h1>Your Caregiver</h1><p class="large-copy">Sarah is here to support you today. Reach out if you need anything.</p><div class="caregiver-card"><div class="photo-ring">👩‍⚕️<span></span></div><h2>Sarah Jenkins</h2><b>Verified Caregiver • Online</b><button class="primary wide" data-action="recorder">▱ Talk to Sarah</button></div></div>${elderNav('home')}</section>`; }
function recorder() { const recording = state.recorderMode === 'recording'; return `<section class="screen recorder"><h1>Talk to Sarah</h1><div class="status-dot"></div><h2>${recording?'CLICK TO END':'CLICK TO TALK'}</h2><p>${recording?'Tap the button when you are finished.':'Press and hold the big button to speak.'}</p><button class="record-button ${recording?'recording':''}" data-action="recordToggle"><span class="mic">🎙</span><span>${recording?'CLICK TO END':'CLICK TO START'}</span></button><footer><span>♢</span><strong>Secured System</strong><p>Sarah will hear your message instantly.<br>This connection is private and safe.</p></footer></section>`; }
function delivered() { const s = state.careStatus; return `<section class="screen delivered">${topbar('CheckIn','elderHome','👩‍⚕️')}<div class="padded"><div class="success">✓</div><div class="circle-illustration">👵 🛒 👴<span></span></div><h2>${s.label}</h2><p>${s.detail}</p><p class="time">◷ Sent at ${s.sent}</p><div class="delivered-card"><span>✓</span><div><strong>Memo Delivered</strong><p>Your voice message has been safely sent to Sarah.</p></div></div><button class="primary wide" data-action="recorder">🎙 Back to Recorder</button></div></section>`; }
function simpleElder(title, icon, copy, active) { return `<section class="screen with-nav">${topbar(title,'elderHome','👴')}<div class="padded grow center"><span class="page-icon">${icon}</span><h1>${title}</h1><p class="large-copy">${copy}</p></div>${elderNav(active)}</section>`; }

function render() {
  const views = { welcome, elderSignup, caregiverSignup, caregiverHome, family, message: messageDetail, elderHome, recorder, delivered, health: () => simpleElder('Health Logs','▧','Your recent check-ins and medication reminders will appear here.','health'), settings: () => simpleElder('Settings','⚙','Microphone access, notification permissions, and caregiver connection are enabled.','settings') };
  root.innerHTML = views[state.screen]();
}

root.addEventListener('input', (event) => { const name = event.target.dataset.field; if (name) state[name] = event.target.value; });
root.addEventListener('click', (event) => {
  const role = event.target.closest('[data-role]')?.dataset.role;
  if (role) { state.selectedRole = role; render(); return; }
  const messageId = event.target.closest('[data-message]')?.dataset.message;
  if (messageId) { state.selectedMessage = state.messages.find((m) => m.id === messageId); setScreen(NAV.message); return; }
  const dismissId = event.target.closest('[data-dismiss]')?.dataset.dismiss;
  if (dismissId) { state.messages = state.messages.filter((m) => m.id !== dismissId); render(); return; }
  const status = event.target.closest('[data-status]')?.dataset.status;
  if (status) { state.careStatus = status === 'working' ? { label:'I am working now!', detail:'Will see your message soon.', sent:'Just now', icon:'💼' } : { label:"I've read your message", detail:'I will call you at 6:00 PM.', sent:'Just now', icon:'☎' }; setScreen(NAV.caregiverHome); return; }
  const action = event.target.closest('[data-action]')?.dataset.action;
  if (!action) return;
  const actions = {
    welcome: () => setScreen(NAV.welcome),
    signIn: () => setScreen(state.selectedRole === 'elder' ? NAV.elderHome : NAV.caregiverHome),
    createAccount: () => setScreen(state.selectedRole === 'elder' ? NAV.elderSignup : NAV.caregiverSignup),
    finishElderSignup: () => { state.selectedRole='elder'; setScreen(NAV.elderHome); },
    finishCaregiverSignup: () => { state.selectedRole='caregiver'; setScreen(NAV.family); },
    caregiverHome: () => setScreen(NAV.caregiverHome),
    family: () => setScreen(NAV.family),
    elderHome: () => setScreen(NAV.elderHome),
    recorder: () => setScreen(NAV.recorder),
    health: () => setScreen(NAV.health),
    settings: () => setScreen(NAV.settings),
    addMember: () => { state.family.push(state.nickname.trim() || state.memberId.trim() || 'New Family Member'); state.memberId=''; state.nickname=''; render(); },
    recordToggle: () => { if (state.recorderMode === 'recording') { state.recorderMode='ready'; setScreen(NAV.delivered); } else { state.recorderMode='recording'; render(); } },
    callParent: () => { window.location.href = 'tel:+15555550100'; },
    callEmergency: () => { window.location.href = 'tel:+15555550111'; },
    falseAlarm: () => setScreen(NAV.caregiverHome),
  };
  actions[action]?.();
});

render();
