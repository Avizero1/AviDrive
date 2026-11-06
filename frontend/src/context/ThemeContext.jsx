import React from 'react';
export const ThemeContext=React.createContext(null);
export function ThemeProvider({children}){const [theme,setTheme]=React.useState(localStorage.getItem('avidrive_theme')||'dark');React.useEffect(()=>{document.documentElement.dataset.theme=theme;localStorage.setItem('avidrive_theme',theme)},[theme]);return <ThemeContext.Provider value={{theme,toggle:()=>setTheme(t=>t==='dark'?'light':'dark')}}>{children}</ThemeContext.Provider>}
export const useTheme=()=>React.useContext(ThemeContext);
