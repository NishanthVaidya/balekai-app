// utils/token.ts
export const getToken = () => {
  if (typeof window === 'undefined') return null;
  return localStorage.getItem('token');
};

export const getRefreshToken = () => {
  if (typeof window === 'undefined') return null;
  return localStorage.getItem('refreshToken');
};

export const setTokens = (accessToken: string, refreshToken: string) => {
  if (typeof window !== 'undefined') {
    localStorage.setItem('token', accessToken);
    localStorage.setItem('refreshToken', refreshToken);
  }
};

export const clearTokens = () => {
  if (typeof window !== 'undefined') {
    localStorage.removeItem('token');
    localStorage.removeItem('refreshToken');
    localStorage.removeItem('user');
  }
};

export const clearToken = () => {
  clearTokens(); // Use the new function for consistency
};

export const isTokenExpired = (token: string): boolean => {
  try {
    const payload = JSON.parse(atob(token.split('.')[1]));
    const currentTime = Date.now() / 1000;
    return payload.exp && payload.exp < currentTime;
  } catch (error) {
    return true; // If we can't parse the token, consider it expired
  }
};

export const getTokenExpirationTime = (token: string): number | null => {
  try {
    const payload = JSON.parse(atob(token.split('.')[1]));
    return payload.exp ? payload.exp * 1000 : null; // Convert to milliseconds
  } catch (error) {
    return null;
  }
};

export const isTokenExpiringSoon = (token: string, minutesBeforeExpiry: number = 5): boolean => {
  const expirationTime = getTokenExpirationTime(token);
  if (!expirationTime) return true;
  
  const currentTime = Date.now();
  const timeUntilExpiry = expirationTime - currentTime;
  const warningTime = minutesBeforeExpiry * 60 * 1000; // Convert minutes to milliseconds
  
  return timeUntilExpiry <= warningTime;
};
