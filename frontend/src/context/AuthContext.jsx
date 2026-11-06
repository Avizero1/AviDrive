import React, { createContext, useContext, useMemo, useState } from 'react';
export const AuthContext = createContext(null);
export function AuthProvider({ children }) { const [token,setToken]=useState(localStorage.getItem('avidrive_token')); const value=useMemo(()=>({token,login:t=>{localStorage.setItem('avidrive_token',t);setToken(t)},logout:()=>{localStorage.removeItem('avidrive_token');setToken(null)}}),[token]); return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>; }
export const useAuth=()=>useContext(AuthContext);
