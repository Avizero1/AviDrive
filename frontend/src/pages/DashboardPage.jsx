import React from 'react';
import { useAuth } from '../context/AuthContext.jsx';
import { Link } from 'react-router-dom';
import FileManager from '../components/FileManager.jsx';
export default function DashboardPage(){const {logout}=useAuth();return <main className="page"><header className="header"><div><h1>AviDrive</h1><p className="muted">Файловое хранилище</p></div><nav><Link to="/profile" className="muted">Профиль</Link> <Link to="/sharing" className="muted">Ссылки</Link> <Link to="/permissions" className="muted">Права</Link> <button onClick={logout}>Выйти</button></nav></header><FileManager /></main>}
