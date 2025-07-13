// utils/token.ts
export const getToken = () => {
  if (typeof window === 'undefined') return null;
  return localStorage.getItem('jwt');
};

export const clearToken = () => {
  if (typeof window !== 'undefined') localStorage.removeItem('jwt');
};
