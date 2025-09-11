import axios from "axios"
import { tokenRefreshService } from "./token-refresh"
import { isTokenExpired, clearTokens } from "./token"

const api = axios.create({
  baseURL: process.env.NEXT_PUBLIC_API_BASE_URL || "https://dtcvfgct9ga1.cloudfront.net",
  headers: {
    "Content-Type": "application/json",
  },
})

// Request Interceptor
api.interceptors.request.use(
  async (config) => {
    if (typeof window !== "undefined") {
      const token = localStorage.getItem("token")
      if (token) {
        // Check if token is expired
        if (isTokenExpired(token)) {
          console.warn("Token expired, attempting refresh...")
          const newToken = await tokenRefreshService.refreshToken()
          if (newToken) {
            config.headers.Authorization = `Bearer ${newToken}`
          } else {
            // Refresh failed, clear tokens and don't add authorization header
            clearTokens()
          }
        } else {
          config.headers.Authorization = `Bearer ${token}`
        }
      }
    }
    return config
  },
  (error) => Promise.reject(error)
)

// Response Interceptor
api.interceptors.response.use(
  (response) => response,
  async (error) => {
    const originalRequest = error.config

    if (error.response && error.response.status === 401 && !originalRequest._retry) {
      originalRequest._retry = true

      if (typeof window !== "undefined") {
        const currentPath = window.location.pathname
        
        // Don't attempt refresh for auth endpoints or if already on login page
        if (currentPath === "/login" || currentPath === "/register" || 
            originalRequest.url?.includes('/auth/')) {
          return Promise.reject(error)
        }

        try {
          // Attempt to refresh the token
          const newToken = await tokenRefreshService.refreshToken()
          
          if (newToken) {
            // Retry the original request with the new token
            originalRequest.headers.Authorization = `Bearer ${newToken}`
            return api(originalRequest)
          } else {
            // Refresh failed, redirect to login
            clearTokens()
            console.warn("Token refresh failed. Redirecting to login.")
            if (window.location.pathname !== "/login") {
              window.location.href = "/login"
            }
          }
        } catch (refreshError) {
          console.error("Token refresh error:", refreshError)
          clearTokens()
          if (window.location.pathname !== "/login") {
            window.location.href = "/login"
          }
        }
      }
    }
    
    return Promise.reject(error)
  }
)

export default api
