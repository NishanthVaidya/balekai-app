// utils/token-refresh.tsx
import { getRefreshToken, setTokens, clearTokens, isTokenExpired } from './token';

class TokenRefreshService {
  private isRefreshing = false;
  private refreshPromise: Promise<string | null> | null = null;

  async refreshToken(): Promise<string | null> {
    // If already refreshing, return the existing promise
    if (this.isRefreshing && this.refreshPromise) {
      return this.refreshPromise;
    }

    this.isRefreshing = true;
    this.refreshPromise = this.performTokenRefresh();

    try {
      const newAccessToken = await this.refreshPromise;
      return newAccessToken;
    } finally {
      this.isRefreshing = false;
      this.refreshPromise = null;
    }
  }

  private async performTokenRefresh(): Promise<string | null> {
    const refreshToken = getRefreshToken();
    
    if (!refreshToken) {
      console.warn('No refresh token available');
      return null;
    }

    if (isTokenExpired(refreshToken)) {
      console.warn('Refresh token has expired');
      clearTokens();
      return null;
    }

    try {
      const response = await fetch(`${process.env.NEXT_PUBLIC_API_BASE_URL || 'https://dtcvfgct9ga1.cloudfront.net'}/auth/refresh`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ refreshToken }),
      });

      if (!response.ok) {
        console.error('Token refresh failed:', response.status, response.statusText);
        clearTokens();
        return null;
      }

      const data = await response.json();
      
      if (data.accessToken && data.refreshToken) {
        setTokens(data.accessToken, data.refreshToken);
        console.log('Tokens refreshed successfully');
        return data.accessToken;
      } else {
        console.error('Invalid token refresh response');
        clearTokens();
        return null;
      }
    } catch (error) {
      console.error('Token refresh error:', error);
      clearTokens();
      return null;
    }
  }

  async getValidToken(): Promise<string | null> {
    const currentToken = localStorage.getItem('token');
    
    if (!currentToken) {
      return null;
    }

    // If token is not expired, return it
    if (!isTokenExpired(currentToken)) {
      return currentToken;
    }

    // If token is expired, try to refresh
    console.log('Access token expired, attempting refresh...');
    return await this.refreshToken();
  }
}

// Export a singleton instance
export const tokenRefreshService = new TokenRefreshService();
