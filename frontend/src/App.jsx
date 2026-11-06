import React from 'react';
import { Navigate, Route, Routes } from 'react-router-dom';
import { AuthProvider } from './context/AuthContext.jsx';
import LoginPage from './pages/LoginPage.jsx';
import DashboardPage from './pages/DashboardPage.jsx';
import ProfilePage from './pages/ProfilePage.jsx';
import SharingPage from './pages/SharingPage.jsx';
import PermissionsPage from './pages/PermissionsPage.jsx';
import ProtectedRoute from './components/ProtectedRoute.jsx';
export default function App() { return <AuthProvider><Routes><Route path="/login" element={<LoginPage />} /><Route path="/" element={<ProtectedRoute><DashboardPage /></ProtectedRoute>} /><Route path="/profile" element={<ProtectedRoute><ProfilePage /></ProtectedRoute>} /><Route path="/sharing" element={<ProtectedRoute><SharingPage /></ProtectedRoute>} /><Route path="/permissions" element={<ProtectedRoute><PermissionsPage /></ProtectedRoute>} /><Route path="*" element={<Navigate to="/" replace />} /></Routes></AuthProvider>; }
