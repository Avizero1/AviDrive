import React, {useState} from 'react';
import {createRoot} from 'react-dom/client';
import {BrowserRouter, Routes, Route, Link, useLocation} from 'react-router-dom';
import './styles.css';

const Logo = () => <Link className="logo" to="/files"><span className="logo-mark">A</span><b>AviDrive</b></Link>;
function Button({children, ...props}) { return <button className="button" {...props}>{children}</button>; }
function Input(props) { return <input className="input" {...props}/>; }
function Modal({title, children, onClose}) { return <div className="modal-backdrop"><section className="modal"><button className="close" onClick={onClose}>×</button><h2>{title}</h2>{children}</section></div>; }
function Skeleton() { return <div className="skeleton"/>; }
function EmptyState({children='Здесь пока ничего нет'}) { return <div className="empty"><span>📁</span><p>{children}</p><Button>Создать папку</Button></div>; }

function Footer() { return <footer>© 2026 AviDrive by Avizero</footer>; }
function Sidebar({collapsed, setCollapsed}) { return <aside className={collapsed?'sidebar collapsed':'sidebar'}><nav><Link to="/files">📁 <span>Мои файлы</span></Link><Link to="/shared">👥 <span>Общие папки</span></Link><Link to="/admin">🛡 <span>Админ-панель</span></Link><Link to="/profile">👤 <span>Профиль</span></Link></nav><button className="collapse" onClick={()=>setCollapsed(!collapsed)}>{collapsed?'»':'«'}<span>{collapsed?'':' Свернуть'}</span></button></aside>; }
function Header() { return <header><Logo/><div className="search">🔍 <span>Поиск файлов и папок</span></div><div className="quota">Квота: ∞</div><button className="user">👤 demo ▾</button></header>; }
function AppLayout({children}) { const [collapsed,setCollapsed]=useState(false); return <div className="app"><Header/><div className="body"><Sidebar collapsed={collapsed} setCollapsed={setCollapsed}/><main>{children}</main></div><Footer/></div>; }
function AuthLayout({children}) { return <div className="auth-layout"><Logo/>{children}<Footer/></div>; }
function PublicLayout({children}) { return <div className="public-layout"><header><Logo/><span>Публичный объект</span></header>{children}<Footer/></div>; }
function Login() { return <AuthLayout><section className="auth-card"><h1>Добро пожаловать</h1><p className="muted">Войдите в AviDrive</p><label>Имя пользователя<Input placeholder="username"/></label><label>Пароль<Input type="password" placeholder="••••••••"/></label><Button>Войти</Button></section></AuthLayout>; }
function Files() { return <AppLayout><div className="breadcrumbs">Главная / Документы</div><div className="toolbar"><h1>Мои файлы</h1><Button>＋ Загрузить</Button><Button>＋ Новая папка</Button></div><div className="file-area"><EmptyState>Папка пуста</EmptyState></div></AppLayout>; }
function Placeholder({title, icon='📄'}) { return <AppLayout><div className="breadcrumbs">Главная / {title}</div><section className="placeholder"><div>{icon}</div><h1>{title}</h1><p className="muted">Раздел будет доступен в следующих шагах ТЗ.</p></section></AppLayout>; }
function Public() { return <PublicLayout><section className="placeholder"><div>🔗</div><h1>Публичная ссылка</h1><p className="muted">Объект доступен по токену.</p></section></PublicLayout>; }
function NotFound() { return <AuthLayout><section className="auth-card"><div className="error-code">404</div><h1>Страница не найдена</h1><Link className="button" to="/files">Вернуться к файлам</Link></section></AuthLayout>; }
function App() { return <Routes><Route path="/login" element={<Login/>}/><Route path="/files" element={<Files/>}/><Route path="/shared" element={<Placeholder title="Общие папки" icon="👥"/>}/><Route path="/admin" element={<Placeholder title="Админ-панель" icon="🛡"/>}/><Route path="/profile" element={<Placeholder title="Профиль" icon="👤"/>}/><Route path="/s/:token/*" element={<Public/>}/><Route path="*" element={<NotFound/>}/></Routes>; }
createRoot(document.getElementById('root')).render(<BrowserRouter><App/></BrowserRouter>);
