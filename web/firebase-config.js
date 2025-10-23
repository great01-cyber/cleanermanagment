// Import the functions you need from the SDKs you need
import { initializeApp } from "firebase/app";
import { getAuth } from "firebase/auth";
import { getFirestore } from "firebase/firestore";
import { getStorage } from "firebase/storage";
import { getAnalytics } from "firebase/analytics";

// Your web app's Firebase configuration
// For Firebase JS SDK v7.20.0 and later, measurementId is optional
const firebaseConfig = {
  apiKey: "AIzaSyBhHaSWsOV2u7PmCsmeI8igiltJygiN2D8",
  authDomain: "cleaner-application-27b56.firebaseapp.com",
  projectId: "cleaner-application-27b56",
  storageBucket: "cleaner-application-27b56.firebasestorage.app",
  messagingSenderId: "728116934635",
  appId: "1:728116934635:web:3101e6ad09c6e99e270bae",
  measurementId: "G-4VHJ42TPKY"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);

// Initialize Firebase services
export const auth = getAuth(app);
export const db = getFirestore(app);
export const storage = getStorage(app);
export const analytics = getAnalytics(app);
