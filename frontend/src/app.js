import { NAV } from './constants/navigation.js';
import { state } from './data/appState.js';
import { caregiverSignup, elderSignup, welcome } from './screens/authScreens.js';
import { caregiverHome, family, messageDetail } from './screens/caregiverScreens.js';
import { delivered, elderHome, recorder, simpleElder } from './screens/elderScreens.js';

const root = document.getElementById('root');

const views = {
  welcome,
  elderSignup,
  caregiverSignup,
  caregiverHome,
  family,
  message: messageDetail,
  elderHome,
  recorder,
  delivered,
  health: () => simpleElder('Health Logs', '▧', 'Your recent check-ins and medication reminders will appear here.', 'health'),
  settings: () => simpleElder('Settings', '⚙', 'Microphone access, notification permissions, and caregiver connection are enabled.', 'settings'),
};

function setScreen(screen) {
  state.screen = screen;
  render();
}

function render() {
  root.innerHTML = views[state.screen]();
}

function handleInput(event) {
  const name = event.target.dataset.field;
  if (name) state[name] = event.target.value;
}

function handleClick(event) {
  const role = event.target.closest('[data-role]')?.dataset.role;
  if (role) {
    state.selectedRole = role;
    render();
    return;
  }

  const messageId = event.target.closest('[data-message]')?.dataset.message;
  if (messageId) {
    state.selectedMessage = state.messages.find((message) => message.id === messageId);
    setScreen(NAV.message);
    return;
  }

  const dismissId = event.target.closest('[data-dismiss]')?.dataset.dismiss;
  if (dismissId) {
    state.messages = state.messages.filter((message) => message.id !== dismissId);
    render();
    return;
  }

  const status = event.target.closest('[data-status]')?.dataset.status;
  if (status) {
    state.careStatus = status === 'working'
      ? { label: 'I am working now!', detail: 'Will see your message soon.', sent: 'Just now', icon: '💼' }
      : { label: "I've read your message", detail: 'I will call you at 6:00 PM.', sent: 'Just now', icon: '☎' };
    setScreen(NAV.caregiverHome);
    return;
  }

  const action = event.target.closest('[data-action]')?.dataset.action;
  if (!action) return;

  const actions = {
    welcome: () => setScreen(NAV.welcome),
    signIn: () => setScreen(state.selectedRole === 'elder' ? NAV.elderHome : NAV.caregiverHome),
    createAccount: () => setScreen(state.selectedRole === 'elder' ? NAV.elderSignup : NAV.caregiverSignup),
    finishElderSignup: () => {
      state.selectedRole = 'elder';
      setScreen(NAV.elderHome);
    },
    finishCaregiverSignup: () => {
      state.selectedRole = 'caregiver';
      setScreen(NAV.family);
    },
    caregiverHome: () => setScreen(NAV.caregiverHome),
    family: () => setScreen(NAV.family),
    elderHome: () => setScreen(NAV.elderHome),
    recorder: () => setScreen(NAV.recorder),
    health: () => setScreen(NAV.health),
    settings: () => setScreen(NAV.settings),
    addMember: () => {
      state.family.push(state.nickname.trim() || state.memberId.trim() || 'New Family Member');
      state.memberId = '';
      state.nickname = '';
      render();
    },
    recordToggle: () => {
      if (state.recorderMode === 'recording') {
        state.recorderMode = 'ready';
        setScreen(NAV.delivered);
      } else {
        state.recorderMode = 'recording';
        render();
      }
    },
    callParent: () => {
      window.location.href = 'tel:+15555550100';
    },
    callEmergency: () => {
      window.location.href = 'tel:+15555550111';
    },
    falseAlarm: () => setScreen(NAV.caregiverHome),
  };

  actions[action]?.();
}

export function initApp() {
  root.addEventListener('input', handleInput);
  root.addEventListener('click', handleClick);
  render();
}
