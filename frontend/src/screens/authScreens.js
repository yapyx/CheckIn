import { careIllustration } from '../assets/illustrations.js';
import { roleCard } from '../components/cards.js';
import { field } from '../components/forms.js';
import { brand, trust } from '../components/layout.js';

export function welcome() {
  return `<section class="screen padded welcome">${brand()}<div class="hero-card">${careIllustration()}</div><div class="segmented"><button class="active">Sign Up</button><button data-action="signIn">Sign In</button></div><h2>Tell us who you are</h2>${roleCard('elder', 'elder', 'I am an Elder', 'I want to receive care')}${roleCard('caregiver', 'caregiver', 'I am a Caregiver', 'I am here to support someone')}<button class="primary wide" data-action="createAccount">Create New Account</button>${trust()}</section>`;
}

export function caregiverSignup() {
  return `<section class="screen padded form-screen">${brand()}<h2>Create Caregiver Account</h2>${field('User ID', 'Enter your official staff ID')}${field('Create Password', 'Minimum 12 characters', '', false, '◉')}${field('Occupation', 'Select your current role', '', false, '⌄⌄')}${field('Others/Specializations', 'List certifications (e.g., Dementia Care)', '', true)}<p class="agreement"><span>ⓘ</span> By clicking Create, you agree to our <b>Data Processing Agreement</b> and <b>Terms of Conduct.</b></p><button class="primary wide" data-action="finishCaregiverSignup">Create</button><button class="outline wide" data-action="welcome">Cancel</button>${trust()}</section>`;
}

export function elderSignup() {
  return `<section class="screen padded form-screen">${brand()}<h2>Join CheckIn</h2><p>Please fill in your details to get started.</p>${field('User ID', 'Enter your unique ID')}${field('Create Password', 'Choose a safe password', '', false, '◉')}${field('Age', 'e.g. 75')}${field('Health Conditions', 'e.g. Hypertension, Diabetes')}${field('Notes / Other Information', 'Anything else we should know?', '', true)}<button class="primary wide" data-action="finishElderSignup">Create</button><button class="outline wide" data-action="welcome">← Go Back</button>${trust()}</section>`;
}
