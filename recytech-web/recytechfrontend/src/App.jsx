import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import Login from './pages/Login';
import Register from './pages/Register';
import ForgotPassword from './pages/ForgotPassword';
import VerifyPin from './pages/VerifyPin';
import ResetPassword from './pages/ResetPassword';
import Dashboard from './pages/Dashboard';
import Collectors from './pages/Collectors';
import Reports from './pages/Reports';
import Settings from './pages/Settings';
import UserManagement from './pages/UserManagement'; 
import RequestManagement from './pages/RequestManagement'; 
import RequestsSummary from './pages/RequestsSummary';
import ProtectedRoute from './pages/ProtectedRoute';
import EducationManager from './pages/EducationManager';
import ExchangeRateManager from './pages/ExchangeRateManager';
import ResidentManagement from './pages/ResidentManagement';
import PayoutHistory from './pages/PayoutHistory';
import Unauthorized from './pages/Unauthorized';
import NotFound from './pages/NotFound';

function App() {
  return (
    <Router>
      <Routes>
        <Route path="/" element={<Navigate to="/login" />} />
        <Route path="/login" element={<Login />} />
        <Route path="/register" element={<Register />} />
        <Route path="/forgot-password" element={<ForgotPassword />} />
        <Route path="/verify-pin" element={<VerifyPin />} />
        <Route path="/reset-password" element={<ResetPassword />} />
        <Route path="/unauthorized" element={<Unauthorized />} />
        
        {/* Protected Routes */}
        <Route 
          path="/dashboard" 
          element={<ProtectedRoute><Dashboard /></ProtectedRoute>} 
        />
        <Route 
          path="/requests-summary" 
          element={<ProtectedRoute><RequestsSummary /></ProtectedRoute>} 
        />
        <Route 
          path="/collectors" 
          element={
            <ProtectedRoute allowedRoles={['Admin', 'Super Admin']}>
              <Collectors />
            </ProtectedRoute>
          } 
        />

        <Route 
          path="/education" 
          element={
            <ProtectedRoute allowedRoles={['Staff', 'Admin', 'Super Admin']}>
              <EducationManager />
            </ProtectedRoute>
          } 
        />

        <Route 
          path="/exchange-rates" 
          element={
            <ProtectedRoute allowedRoles={['Admin', 'Super Admin']}>
              <ExchangeRateManager />
            </ProtectedRoute>
          } 
        />

        <Route 
          path="/residents" 
          element={
            <ProtectedRoute allowedRoles={['Admin', 'Super Admin']}>
              <ResidentManagement />
            </ProtectedRoute>
          } 
        />

        <Route 
          path="/transactions" 
          element={
            <ProtectedRoute allowedRoles={['Admin', 'Super Admin']}>
              <PayoutHistory />
            </ProtectedRoute>
          } 
        />

        <Route 
          path="/requests" 
          element={
            <ProtectedRoute allowedRoles={['Admin', 'Super Admin']}>
              <RequestManagement />
            </ProtectedRoute>
          } 
        />
        <Route 
          path="/reports" 
          element={
            <ProtectedRoute allowedRoles={['Admin', 'Super Admin']}>
              <Reports />
            </ProtectedRoute>
          } 
        />
        <Route 
          path="/settings" 
          element={
            <ProtectedRoute allowedRoles={['Admin', 'Super Admin']}>
              <Settings />
            </ProtectedRoute>
          } 
        />

        {/* Super Admin Only */}
        <Route 
          path="/users" 
          element={<ProtectedRoute allowedRoles={['Super Admin']}><UserManagement /></ProtectedRoute>} 
        />

        {/* Catch-all 404 Route */}
        <Route path="*" element={<NotFound />} />
      </Routes>
    </Router>
  );
}

export default App;
