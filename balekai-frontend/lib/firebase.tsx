// Import the functions you need from the SDKs you need
import { initializeApp } from "firebase/app"
import { getAuth, GoogleAuthProvider, signInWithPopup } from "firebase/auth"

// TODO: Add SDKs for Firebase products that you want to use
// https://firebase.google.com/docs/web/setup#available-libraries

// Your web app's Firebase configuration
// For Firebase JS SDK v7.20.0 and later, measurementId is optional
const firebaseConfig = {
  apiKey: "AIzaSyCfVbVp0n1pqoo6RN4T_r5KfIslVwyZciw",
  authDomain: "trelllo-7a26a.firebaseapp.com",
  projectId: "trelllo-7a26a",
  storageBucket: "trelllo-7a26a.firebasestorage.app",
  messagingSenderId: "143118515728",
  appId: "1:143118515728:web:8221e4d6ebfd66e2a35495",
  measurementId: "G-0VNZXYRPC4"
};

// Initialize Firebase

const app = initializeApp(firebaseConfig)
const auth = getAuth(app)
const googleProvider = new GoogleAuthProvider()

// ✅ This is the missing function you're trying to import
const signInWithGoogle = () => signInWithPopup(auth, googleProvider)

export { auth, signInWithGoogle }
