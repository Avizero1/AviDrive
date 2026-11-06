import React from 'react';
import { useAuth } from '../context/AuthContext.jsx';
export default function DashboardPage(){const {logout}=useAuth();return <main className="page"><header className="header"><div><h1>AviDrive</h1><p className="muted">Файловое хранилище</p></div><button onClick={logout}>Выйти</button></header><section className="card"><h2>Добро пожаловать</h2><p className="muted">Файловый менеджер будет доступен на следующем шаге.</p></section></main>}
