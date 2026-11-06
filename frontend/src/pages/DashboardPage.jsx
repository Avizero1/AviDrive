import React from 'react';
import { useAuth } from '../context/AuthContext.jsx';
import { Link } from 'react-router-dom';
export default function DashboardPage(){const {logout}=useAuth();return <main className="page"><header className="header"><div><h1>AviDrive</h1><p className="muted">Файловое хранилище</p></div><nav><Link to="/profile" className="muted">Профиль</Link> <button onClick={logout}>Выйти</button></nav></header><section className="card"><h2>Добро пожаловать</h2><p className="muted">Файловый менеджер будет доступен на следующем шаге.</p></section></main>}
