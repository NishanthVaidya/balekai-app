// This is a mock authentication service
// In a real application, you would connect this to your backend authentication system

interface User {
  id: string
  name: string
  email: string
}

interface LoginCredentials {
  email: string
  password: string
}

interface RegisterData {
  name: string
  email: string
  password: string
}

export const authService = {
  // Login user
  async login(credentials: LoginCredentials): Promise<User> {
    // Simulate API call
    await new Promise((resolve) => setTimeout(resolve, 1000))

    // In a real app, you would validate credentials with your backend
    if (credentials.email === "user@example.com" && credentials.password === "password123") {
      return {
        id: "1",
        name: "Test User",
        email: credentials.email,
      }
    }

    throw new Error("Invalid credentials")
  },

  // Register new user
  async register(data: RegisterData): Promise<User> {
    // Simulate API call
    await new Promise((resolve) => setTimeout(resolve, 1000))

    // In a real app, you would send registration data to your backend
    return {
      id: "2",
      name: data.name,
      email: data.email,
    }
  },

  // Send password reset email
  async forgotPassword(email: string): Promise<void> {
    // Simulate API call
    await new Promise((resolve) => setTimeout(resolve, 1000))

    // In a real app, you would trigger a password reset email from your backend
    if (email !== "user@example.com") {
      throw new Error("Email not found")
    }
  },

  // Reset password with token
  async resetPassword(token: string): Promise<void> {
    // Simulate API call
    await new Promise((resolve) => setTimeout(resolve, 1000))

    // In a real app, you would validate the token and update the password in your backend
    if (!token) {
      throw new Error("Invalid token")
    }
  },

  // Logout user
  async logout(): Promise<void> {
    // Simulate API call
    await new Promise((resolve) => setTimeout(resolve, 1000))

    // In a real app, you would invalidate the session in your backend
    localStorage.removeItem("user")
  },

  // Get current user
  async getCurrentUser(): Promise<User | null> {
    // Simulate API call
    await new Promise((resolve) => setTimeout(resolve, 500))

    // In a real app, you would validate the session and return the current user
    const userJson = localStorage.getItem("user")
    if (!userJson) return null

    try {
      return JSON.parse(userJson) as User
    } catch {
      return null
    }
  },
}
